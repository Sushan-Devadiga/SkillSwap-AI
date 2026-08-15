import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final discoverServiceProvider = Provider<DiscoverService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DiscoverService(supabase);
});

class DiscoverService {
  final SupabaseClient _client;

  DiscoverService(this._client);

  Future<List<Map<String, dynamic>>> getDiscoverProfiles({
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      var query = _client.from('profiles').select('''
        id,
        username,
        full_name,
        avatar_url,
        bio,
        experience_level,
        user_skills (
          type,
          proficiency_level,
          skills (
            name,
            category
          )
        )
      ''');

      // Filter out the current user
      if (currentUserId != null) {
        query = query.neq('id', currentUserId);
      }

      // We only want users who have actually completed their profile (e.g. have a username)
      query = query.not('username', 'is', null);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search by full_name or username
        query = query.or('full_name.ilike.%$searchQuery%,username.ilike.%$searchQuery%');
      }

      final response = await query.range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error in getDiscoverProfiles: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    try {
      final response = await _client.from('profiles').select('''
        id,
        username,
        full_name,
        avatar_url,
        bio,
        location,
        timezone,
        experience_level,
        learning_goals,
        availability,
        user_skills (
          type,
          proficiency_level,
          skills (
            name,
            category
          )
        )
      ''').eq('username', username).maybeSingle();
      
      return response;
    } catch (e) {
      print('Error in getProfileByUsername: $e');
      return null;
    }
  }
}
