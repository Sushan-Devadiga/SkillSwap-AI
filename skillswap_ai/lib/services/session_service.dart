import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'token_service.dart';
import 'credential_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return SessionService(supabase, notificationService);
});

class SessionService {
  final SupabaseClient _client;
  final NotificationService _notificationService;
  late final TokenService _tokenService;
  late final CredentialService _credentialService;
  final Set<String> _locallyCancelledSessionIds = {};

  SessionService(this._client, this._notificationService) {
    _tokenService = TokenService(_client);
    _credentialService = CredentialService(_client);
  }

  Future<bool> proposeSession({
    required String peerId,
    required String title,
    required DateTime time,
    required int durationMinutes,
    String? skillId,
    String? meetingLink,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      print('proposeSession error: No authenticated user');
      return false;
    }

    try {
      // Auto-generate Jitsi Meet URL: https://meet.jit.si/SkillSwap-[SESSION_ID]
      final roomTag = 'SkillSwap-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${currentUserId.substring(0, 4)}';
      final generatedLink = meetingLink ?? 'https://meet.jit.si/$roomTag';

      // Create session in sessions table
      final sessionResponse = await _client.from('sessions').insert({
        'organizer_id': currentUserId,
        'title': title,
        'scheduled_time': time.toIso8601String(),
        'duration_minutes': durationMinutes,
        if (skillId != null) 'skill_id': skillId,
        'meeting_link': generatedLink,
        'status': 'scheduled',
        'description': jsonEncode({'peer_id': peerId, 'title': title}),
      }).select('id').single();
      
      final sessionId = sessionResponse['id'] as String;
      
      // 1. Add organizer to session_participants (auth.uid() == currentUserId always passes RLS)
      try {
        await _client.from('session_participants').insert({
          'session_id': sessionId,
          'participant_id': currentUserId,
        });
      } catch (e) {
        print('Notice: Organizer participant insert: $e');
      }

      // 2. Add peer to session_participants
      try {
        await _client.from('session_participants').insert({
          'session_id': sessionId,
          'participant_id': peerId,
        });
      } catch (e) {
        print('Notice: Peer participant insert (RLS policy may require organizer grant): $e');
      }
      
      // Get current user profile for notification
      String fullName = 'A peer';
      try {
        final profileResp = await _client.from('profiles').select('full_name').eq('id', currentUserId).maybeSingle();
        if (profileResp != null && profileResp['full_name'] != null) {
          fullName = profileResp['full_name'];
        }
      } catch (e) {
        print('Error fetching profile for notification: $e');
      }
      
      // Send notification to peer
      await _notificationService.createNotification(
        userId: peerId,
        type: 'session_invitation',
        content: '$fullName invited you to a session: $title',
        relatedEntityId: sessionId,
      );
      
      return true;
    } catch (e) {
      print('Error proposing session: $e');
      return false;
    }
  }

  Future<bool> openMeetingLink(String meetingLink) async {
    try {
      final uri = Uri.parse(meetingLink);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching meeting: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingSessions() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Find sessions where the user is a participant and status is scheduled or in_progress
      // We use the joined tables syntax
      const sessionSelect = '''
        id,
        title,
        description,
        scheduled_time,
        duration_minutes,
        status,
        organizer_id,
        meeting_link,
        skill:skill_id (id, name, category),
        organizer:organizer_id (id, full_name, username, avatar_url, bio, experience_level),
        session_participants (
          participant_id,
          profiles:participant_id (id, full_name, username, avatar_url, bio, experience_level)
        )
      ''';

      final response = await _client.from('session_participants')
          .select('''
            session_id,
            sessions:session_id (
              $sessionSelect
            )
          ''')
          .eq('participant_id', currentUserId)
          .inFilter('sessions.status', ['scheduled', 'in_progress'])
          .not('sessions.id', 'is', null);

      final Map<String, Map<String, dynamic>> sessionMap = {};
      
      for (var item in response) {
        if (item['sessions'] != null) {
          final sessionData = Map<String, dynamic>.from(item['sessions'] as Map);
          final id = sessionData['id'] as String;
          final scheduledTime = DateTime.parse(sessionData['scheduled_time']);
          if (scheduledTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
             sessionMap[id] = sessionData;
          }
        }
      }

      // Also fetch directly from sessions where current user is organizer
      try {
        final organizerResp = await _client.from('sessions')
            .select(sessionSelect)
            .eq('organizer_id', currentUserId)
            .inFilter('status', ['scheduled', 'in_progress']);

        for (var item in organizerResp) {
          final sessionData = Map<String, dynamic>.from(item as Map);
          final id = sessionData['id'] as String;
          if (!sessionMap.containsKey(id)) {
            final scheduledTime = DateTime.parse(sessionData['scheduled_time']);
            if (scheduledTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
              sessionMap[id] = sessionData;
            }
          }
        }
      } catch (e) {
        print('Notice: Direct organizer sessions fetch error: $e');
      }

      final List<Map<String, dynamic>> validSessions = [];

      // Resolve peer profile and ensure only sessions with real Supabase users are shown
      for (var session in sessionMap.values) {
        Map<String, dynamic>? peer;
        final participants = session['session_participants'] as List? ?? [];
        for (var p in participants) {
          if (p['participant_id'] != currentUserId) {
            final prof = p['profiles'] as Map<String, dynamic>?;
            if (prof != null && (prof['id'] as String?)?.isNotEmpty == true) {
              peer = prof;
              break;
            }
          }
        }

        if (peer == null && session['organizer_id'] != currentUserId) {
          final org = session['organizer'] as Map<String, dynamic>?;
          if (org != null && (org['id'] as String?)?.isNotEmpty == true) {
            peer = org;
          }
        }

        if (peer == null) {
          final desc = (session['description'] as String?) ?? '';
          String? peerIdCandidate;

          if (desc.contains('"peer_id":')) {
            try {
              final parsed = jsonDecode(desc) as Map<String, dynamic>;
              peerIdCandidate = parsed['peer_id'] as String?;
            } catch (_) {}
          }

          if (peerIdCandidate != null && peerIdCandidate.isNotEmpty) {
            try {
              final peerQuery = await _client.from('profiles')
                  .select('id, full_name, username, avatar_url, bio, experience_level')
                  .eq('id', peerIdCandidate)
                  .maybeSingle();
              if (peerQuery != null && (peerQuery['id'] as String?)?.isNotEmpty == true) {
                peer = peerQuery;
              }
            } catch (_) {}
          }
        }

        // Exact Supabase check:
        // A session MUST have an actual, verified peer profile in Supabase profiles!
        // If the peer does NOT exist in Supabase, this is an orphaned/invalid test record.
        if (peer == null || (peer['id'] as String?)?.isEmpty == true) {
          final orphanId = session['id'] as String?;
          if (orphanId != null && session['organizer_id'] == currentUserId) {
            // Auto-clean orphaned test session from Supabase
            try {
              _client.from('sessions').delete().eq('id', orphanId).then((_) {}).catchError((_) {});
            } catch (_) {}
          }
          continue; // Exclude from active swaps list
        }

        session['peer_profile'] = peer;
        validSessions.add(session);
      }

      // Filter out any locally cancelled sessions or cancelled status
      validSessions.removeWhere((s) {
        final id = s['id'] as String?;
        return id != null && (_locallyCancelledSessionIds.contains(id) || s['status'] == 'cancelled');
      });

      validSessions.sort((a, b) => DateTime.parse(a['scheduled_time']).compareTo(DateTime.parse(b['scheduled_time'])));
      return validSessions;
    } catch (e) {
      print('Error getting upcoming sessions: $e');
      return [];
    }
  }

  Future<bool> cancelSession(String sessionId) async {
    _locallyCancelledSessionIds.add(sessionId);
    final currentUserId = _client.auth.currentUser?.id;

    try {
      // 1. Delete participant entries first to avoid foreign key blocks
      if (currentUserId != null) {
        try {
          await _client.from('session_participants')
              .delete()
              .eq('session_id', sessionId)
              .eq('participant_id', currentUserId);
        } catch (e) {
          print('Notice deleting participant: $e');
        }
      }

      try {
        await _client.from('session_participants').delete().eq('session_id', sessionId);
      } catch (e) {
        print('Notice deleting all participants: $e');
      }

      // 2. Mark session status as cancelled
      try {
        await _client.from('sessions').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', sessionId);
      } catch (e) {
        print('Notice updating session status to cancelled: $e');
      }

      // 3. Attempt hard delete if authorized (organizer)
      try {
        await _client.from('sessions').delete().eq('id', sessionId);
      } catch (e) {
        print('Notice hard deleting session: $e');
      }

      return true;
    } catch (e) {
      print('Error in cancelSession: $e');
      return true; // Still true because locally cancelled
    }
  }

  Future<bool> updateSessionStatus(String sessionId, String status) async {
    try {
      await _client.from('sessions').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', sessionId);
      return true;
    } catch (e) {
      print('Error updating session status: $e');
      return false;
    }
  }

  Future<bool> completeSession({
    required String sessionId,
    required String providerId,
    required String receiverId,
    String? skillId,
    required double hours,
    int? rating,
    String? feedback,
  }) async {
    try {
      // 1. Update session status
      await updateSessionStatus(sessionId, 'completed');
      
      // 2. Create exchange history
      await _client.from('exchange_history').insert({
        'session_id': sessionId,
        'provider_id': providerId,
        'receiver_id': receiverId,
        if (skillId != null) 'skill_id': skillId,
        'hours_exchanged': hours,
        if (rating != null) 'rating': rating,
        if (feedback != null && feedback.trim().isNotEmpty) 'feedback': feedback.trim(),
      });
      
      // 3. Resolve skill name
      String skillName = 'General Skill Exchange';
      if (skillId != null) {
        try {
          final skillResp = await _client.from('skills').select('name').eq('id', skillId).maybeSingle();
          if (skillResp != null && skillResp['name'] != null) {
            skillName = skillResp['name'];
          }
        } catch (_) {}
      }

      // 4. Time-as-Currency Model: 1 Hour = 1 Time Token
      final tokenUnits = (hours <= 0 ? 1.0 : hours).round().clamp(1, 10);
      try {
        final currentUid = _client.auth.currentUser?.id;

        // Settle current user's token change immediately
        if (currentUid != null && currentUid == providerId) {
          // Current user taught -> earn +tokens
          await _tokenService.awardTokens(
            userId: currentUid,
            amount: tokenUnits,
            type: 'earned_teaching',
            description: 'Taught $skillName for ${hours.toStringAsFixed(1)} hr',
            sessionId: sessionId,
          );
        } else if (currentUid != null && currentUid == receiverId) {
          // Current user learned -> spend -tokens
          await _tokenService.spendTokens(
            userId: currentUid,
            amount: tokenUnits,
            description: 'Learned $skillName for ${hours.toStringAsFixed(1)} hr',
            sessionId: sessionId,
          );
        }

        // Attempt settlement for the peer
        final peerUid = (currentUid == providerId) ? receiverId : providerId;
        if (peerUid.isNotEmpty && peerUid != currentUid) {
          try {
            if (currentUid == providerId) {
              await _tokenService.spendTokens(
                userId: peerUid,
                amount: tokenUnits,
                description: 'Learned $skillName for ${hours.toStringAsFixed(1)} hr',
                sessionId: sessionId,
              );
            } else {
              await _tokenService.awardTokens(
                userId: peerUid,
                amount: tokenUnits,
                type: 'earned_teaching',
                description: 'Taught $skillName for ${hours.toStringAsFixed(1)} hr',
                sessionId: sessionId,
              );
            }
          } catch (_) {
            // Handled: peer's dynamic balance calculation from exchange_history automatically tracks this!
          }
        }
      } catch (e) {
        print('Notice in token settlement: $e');
      }

      // 5. Blockchain-Backed Verified Credentials: Mint verified badge
      try {
        await _credentialService.mintBadge(
          learnerId: receiverId,
          mentorId: providerId,
          skillName: skillName,
          hours: hours,
          sessionId: sessionId,
        );
      } catch (e) {
        print('Notice in badge minting: $e');
      }

      // 6. Notify receiver with verified badge details
      await _notificationService.createNotification(
        userId: receiverId,
        type: 'session_completion',
        content: 'Your $skillName session is complete! You earned $tokenUnits Time Token credit and a Verified Skill Badge.',
        relatedEntityId: sessionId,
      );
      
      return true;
    } catch (e) {
      print('Error completing session: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedExchanges() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _client.from('exchange_history')
          .select('''
            id,
            hours_exchanged,
            rating,
            feedback,
            created_at,
            skills:skill_id (id, name, category),
            provider:provider_id (id, full_name, username, avatar_url)
          ''')
          .eq('receiver_id', currentUserId)
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting completed exchanges: $e');
      return [];
    }
  }
}
