import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'notification_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return SessionService(supabase, notificationService);
});

class SessionService {
  final SupabaseClient _client;
  final NotificationService _notificationService;

  SessionService(this._client, this._notificationService);

  Future<bool> proposeSession({
    required String peerId,
    required String title,
    required DateTime time,
    required int durationMinutes,
    String? skillId,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      // Create session
      final sessionResponse = await _client.from('sessions').insert({
        'organizer_id': currentUserId,
        'title': title,
        'scheduled_time': time.toIso8601String(),
        'duration_minutes': durationMinutes,
        if (skillId != null) 'skill_id': skillId,
        'status': 'scheduled',
      }).select('id').single();
      
      final sessionId = sessionResponse['id'];
      
      // Add participants
      await _client.from('session_participants').insert([
        {'session_id': sessionId, 'participant_id': currentUserId},
        {'session_id': sessionId, 'participant_id': peerId},
      ]);
      
      // Get current user profile for notification
      final profileResp = await _client.from('profiles').select('full_name').eq('id', currentUserId).single();
      final fullName = profileResp['full_name'];
      
      // Send notification
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

  Future<List<Map<String, dynamic>>> getUpcomingSessions() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Find sessions where the user is a participant and status is scheduled or in_progress
      // We use the joined tables syntax
      final response = await _client.from('session_participants')
          .select('''
            session_id,
            sessions:session_id (
              id,
              title,
              scheduled_time,
              duration_minutes,
              status,
              organizer_id,
              session_participants (
                participant_id,
                profiles:participant_id (id, full_name, username, avatar_url)
              )
            )
          ''')
          .eq('participant_id', currentUserId)
          .inFilter('sessions.status', ['scheduled', 'in_progress'])
          .not('sessions.id', 'is', null); // Ensures we only get non-null matched sessions
          
      final List<Map<String, dynamic>> results = [];
      
      for (var item in response) {
        if (item['sessions'] != null) {
          final sessionData = item['sessions'] as Map<String, dynamic>;
          
          // Only include if the time is in the future or not too far in the past
          final scheduledTime = DateTime.parse(sessionData['scheduled_time']);
          if (scheduledTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
             results.add(sessionData);
          }
        }
      }
      
      results.sort((a, b) => DateTime.parse(a['scheduled_time']).compareTo(DateTime.parse(b['scheduled_time'])));
      
      return results;
    } catch (e) {
      print('Error getting upcoming sessions: $e');
      return [];
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
      });
      
      // 3. Notify receiver
      await _notificationService.createNotification(
        userId: receiverId,
        type: 'session_completion',
        content: 'Your session has been marked as complete.',
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
