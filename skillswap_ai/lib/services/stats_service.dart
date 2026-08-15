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

  Future<Map<String, int>> getUserStats() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return {
      'skillsLearned': 0,
      'skillsShared': 0,
      'exchangesCompleted': 0,
      'connections': 0,
    };

    try {
      // Get skills learned/taught
      final skillsResp = await _client.from('user_skills').select('type').eq('user_id', currentUserId);
      int skillsLearned = 0;
      int skillsShared = 0;
      for (var skill in skillsResp) {
        if (skill['type'] == 'LEARN') skillsLearned++;
        if (skill['type'] == 'TEACH') skillsShared++;
      }

      // Get completed exchanges (user was either provider or receiver)
      final exchangesResp = await _client.from('exchange_history')
          .select('id')
          .or('provider_id.eq.$currentUserId,receiver_id.eq.$currentUserId');
      final exchangesCompleted = (exchangesResp as List).length;

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
}
