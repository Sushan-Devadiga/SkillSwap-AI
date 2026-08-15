import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileService(supabase);
});

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> upsertProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').upsert({
      'id': userId,
      ...data,
    });
  }

  Future<String?> getOrCreateSkill(String name) async {
    try {
      final existing = await _client.from('skills').select('id').eq('name', name).maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }
      final response = await _client.from('skills').insert({'name': name}).select('id').single();
      return response['id'] as String;
    } catch (e) {
      print('Error in getOrCreateSkill: $e');
      return null;
    }
  }

  Future<void> saveUserSkills(String userId, List<Map<String, dynamic>> userSkillsData) async {
    try {
      if (userSkillsData.isEmpty) return;
      // First delete existing skills of the same types being inserted to avoid unique constraint conflicts on updates
      final types = userSkillsData.map((e) => e['type'] as String).toSet().toList();
      if (types.isNotEmpty) {
        await _client.from('user_skills').delete().eq('user_id', userId).inFilter('type', types);
      }
      
      // Then insert new ones
      await _client.from('user_skills').insert(userSkillsData);
    } catch (e) {
      print('Error saving user skills: $e');
    }
  }
}
