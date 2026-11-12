import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StatsService(supabase);
});

class StatsService {
  final SupabaseClient _client;

  StatsService(this._client);

  Future<Map<String, dynamic>> getUserProfileStats([String? targetUserId]) async {
    final userId = targetUserId ?? _client.auth.currentUser?.id;
    if (userId == null) {
      return {
        'swaps': '0',
        'rating': 'New',
        'connections': '0',
      };
    }

    try {
      // 1. Total completed swaps from exchange_history
      final exchangesResp = await _client
          .from('exchange_history')
          .select('id, rating, provider_id, receiver_id')
          .or('provider_id.eq.$userId,receiver_id.eq.$userId');
      final exchangesList = List<Map<String, dynamic>>.from(exchangesResp);

      // Also check completed sessions in sessions table
      final completedSessionsResp = await _client
          .from('sessions')
          .select('id')
          .eq('organizer_id', userId)
          .eq('status', 'completed');
      final completedSessionsCount = (completedSessionsResp as List).length;

      final swapsCount = (exchangesList.length > completedSessionsCount
          ? exchangesList.length
          : completedSessionsCount);

      // 2. Average rating from reviews where this user was the teacher/provider
      final ratings = exchangesList
          .where((e) => e['provider_id'] == userId && e['rating'] != null)
          .map((e) => (e['rating'] as num).toDouble())
          .toList();

      String ratingDisplay = 'New';
      if (ratings.isNotEmpty) {
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        ratingDisplay = avg.toStringAsFixed(1);
      }

      // 3. Accepted connections
      final connectionsResp = await _client
          .from('connections')
          .select('id')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'accepted');
      final connectionsCount = (connectionsResp as List).length;

      return {
        'swaps': swapsCount.toString(),
        'rating': ratingDisplay,
        'connections': connectionsCount.toString(),
      };
    } catch (e) {
      print('Error in getUserProfileStats: $e');
      return {
        'swaps': '0',
        'rating': 'New',
        'connections': '0',
      };
    }
  }

  Future<Map<String, int>> getUserStats() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return {
      'skillsLearned': 0,
      'skillsShared': 0,
      'exchangesCompleted': 0,
      'connections': 0,
    };

    try {
      // Get completed exchanges (user was either provider or receiver)
      final exchangesResp = await _client.from('exchange_history')
          .select('id, provider_id, receiver_id')
          .or('provider_id.eq.$currentUserId,receiver_id.eq.$currentUserId');
      
      final exchangesList = exchangesResp as List;
      final exchangesCompleted = exchangesList.length;
      
      int skillsLearned = 0;
      int skillsShared = 0;
      
      for (var ex in exchangesList) {
        if (ex['receiver_id'] == currentUserId) skillsLearned++;
        if (ex['provider_id'] == currentUserId) skillsShared++;
      }

      // Get accepted connections
      final connectionsResp = await _client.from('connections')
          .select('id')
          .or('requester_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('status', 'accepted');
      final connections = (connectionsResp as List).length;

      return {
        'skillsLearned': skillsLearned,
        'skillsShared': skillsShared,
        'exchangesCompleted': exchangesCompleted,
        'connections': connections,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'skillsLearned': 0,
        'skillsShared': 0,
        'exchangesCompleted': 0,
        'connections': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getLearnedSkillsList() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final res = await _client.from('exchange_history')
          .select('*, provider:profiles!provider_id(id, full_name, username, avatar_url), skill:skills(id, name, category)')
          .eq('receiver_id', currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error getting learned skills list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSharedSkillsList() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final res = await _client.from('exchange_history')
          .select('*, receiver:profiles!receiver_id(id, full_name, username, avatar_url), skill:skills(id, name, category)')
          .eq('provider_id', currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error getting shared skills list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExchangesList() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final res = await _client.from('exchange_history')
          .select('*, provider:profiles!provider_id(id, full_name, username, avatar_url), receiver:profiles!receiver_id(id, full_name, username, avatar_url), skill:skills(id, name, category)')
          .or('provider_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error getting exchanges list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConnectionsList() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];
    try {
      final res = await _client.from('connections')
          .select('*, requester:profiles!requester_id(id, full_name, username, avatar_url), receiver:profiles!receiver_id(id, full_name, username, avatar_url)')
          .or('requester_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error getting connections list: $e');
      return [];
    }
  }
}

// Providers for the lists
final learnedSkillsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(statsServiceProvider).getLearnedSkillsList();
});

final sharedSkillsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(statsServiceProvider).getSharedSkillsList();
});

final exchangesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(statsServiceProvider).getExchangesList();
});

final connectionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(statsServiceProvider).getConnectionsList();
});

final userProfileStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(statsServiceProvider).getUserProfileStats();
});
