import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final discoverServiceProvider = Provider<DiscoverService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DiscoverService(supabase);
});

// Riverpod state notifier for selected category in Discover
class DiscoverCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final discoverCategoryProvider =
    NotifierProvider<DiscoverCategoryNotifier, String>(DiscoverCategoryNotifier.new);

// Riverpod state notifier for search query in Discover
class DiscoverSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearchQuery(String query) {
    state = query;
  }
}

final discoverSearchQueryProvider =
    NotifierProvider<DiscoverSearchQueryNotifier, String>(DiscoverSearchQueryNotifier.new);

// Riverpod state notifier for selected skill level in Discover
class DiscoverSkillLevelNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setSkillLevel(String level) {
    state = level;
  }
}

final discoverSkillLevelProvider =
    NotifierProvider<DiscoverSkillLevelNotifier, String>(DiscoverSkillLevelNotifier.new);

// Riverpod FutureProvider to fetch profiles by category
final discoverProfilesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final service = ref.watch(discoverServiceProvider);
  return await service.getDiscoverProfiles(category: category);
});

class DiscoverService {
  final SupabaseClient _client;

  DiscoverService(this._client);

  Future<List<Map<String, dynamic>>> getDiscoverProfiles({
    String? searchQuery,
    String? category,
    String? skillLevel,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final hasCategory = category != null && category.isNotEmpty && category.toLowerCase() != 'all';
      final cleanQuery = searchQuery?.trim() ?? '';
      final hasQuery = cleanQuery.isNotEmpty;

      const selectClause = '''
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
            id,
            name,
            category
          )
        )
      ''';

      // 1. If searching, query skills table to find users who teach or learn matching skills
      List<String> userIdsWithMatchingSkills = [];
      if (hasQuery) {
        try {
          final matchingSkillsResp = await _client
              .from('skills')
              .select('id')
              .or('name.ilike.%$cleanQuery%,category.ilike.%$cleanQuery%');
          
          if (matchingSkillsResp.isNotEmpty) {
            final skillIds = (matchingSkillsResp as List).map((s) => s['id'] as String).toList();
            final userSkillsResp = await _client
                .from('user_skills')
                .select('user_id')
                .inFilter('skill_id', skillIds);
            
            userIdsWithMatchingSkills = (userSkillsResp as List)
                .map((us) => us['user_id'] as String)
                .toSet()
                .toList();
          }
        } catch (e) {
          print('Notice: Error searching skills: $e');
        }
      }

      // 2. Query 1: Search profiles by username, full_name, or bio
      var profileQuery = _client.from('profiles').select(selectClause);
      if (currentUserId != null) profileQuery = profileQuery.neq('id', currentUserId);
      profileQuery = profileQuery.not('username', 'is', null);

      if (hasQuery) {
        profileQuery = profileQuery.or('username.ilike.%$cleanQuery%,full_name.ilike.%$cleanQuery%,bio.ilike.%$cleanQuery%');
      }

      final profileResultsFuture = profileQuery.range(offset, offset + limit * 2);

      // 3. Query 2: If users matched by skill, fetch their profiles too
      Future<List<dynamic>>? skillUsersFuture;
      if (hasQuery && userIdsWithMatchingSkills.isNotEmpty) {
        var skillQuery = _client.from('profiles').select(selectClause);
        if (currentUserId != null) skillQuery = skillQuery.neq('id', currentUserId);
        skillQuery = skillQuery.not('username', 'is', null);
        skillQuery = skillQuery.inFilter('id', userIdsWithMatchingSkills);
        skillUsersFuture = skillQuery.limit(limit * 2);
      }

      // Execute queries in parallel
      final results = await Future.wait([
        profileResultsFuture,
        if (skillUsersFuture != null) skillUsersFuture,
      ]);

      final profileResults = List<Map<String, dynamic>>.from(results[0]);
      final skillResults = results.length > 1 ? List<Map<String, dynamic>>.from(results[1]) : <Map<String, dynamic>>[];

      // Merge results uniquely by ID
      final Map<String, Map<String, dynamic>> mergedMap = {};
      for (var p in profileResults) {
        mergedMap[p['id'] as String] = p;
      }
      for (var p in skillResults) {
        mergedMap[p['id'] as String] = p;
      }

      List<Map<String, dynamic>> list = mergedMap.values.toList();

      // 4. Apply category filter if active
      if (hasCategory) {
        final catLower = category.toLowerCase();
        list = list.where((p) {
          final usList = p['user_skills'] as List? ?? [];
          return usList.any((us) {
            final skill = us['skills'];
            if (skill is Map) {
              final cat = (skill['category'] as String?)?.toLowerCase() ?? '';
              return cat.contains(catLower);
            }
            return false;
          });
        }).toList();
      }

      // 4b. Apply skill level filter if active
      final hasSkillLevel = skillLevel != null &&
          skillLevel.isNotEmpty &&
          skillLevel.toLowerCase() != 'all' &&
          skillLevel.toLowerCase() != 'all levels';

      if (hasSkillLevel) {
        final levelLower = skillLevel.toLowerCase();
        list = list.where((p) {
          final expLevel = (p['experience_level'] as String?)?.toLowerCase() ?? '';
          if (expLevel.contains(levelLower)) return true;
          // Map "expert" to "advanced" or vice versa if needed
          if (levelLower == 'expert' && (expLevel.contains('expert') || expLevel.contains('advanced'))) return true;
          if (levelLower == 'advanced' && (expLevel.contains('advanced') || expLevel.contains('expert'))) return true;

          final usList = p['user_skills'] as List? ?? [];
          return usList.any((us) {
            final prof = (us['proficiency_level'] as String?)?.toLowerCase() ?? '';
            return prof.contains(levelLower);
          });
        }).toList();
      }

      // 5. If searching, verify in-memory matches across people & skills
      if (hasQuery) {
        final qLower = cleanQuery.toLowerCase();
        list = list.where((p) {
          final username = (p['username'] as String?)?.toLowerCase() ?? '';
          final fullName = (p['full_name'] as String?)?.toLowerCase() ?? '';
          final bio = (p['bio'] as String?)?.toLowerCase() ?? '';
          if (username.contains(qLower) || fullName.contains(qLower) || bio.contains(qLower)) {
            return true;
          }
          final usList = p['user_skills'] as List? ?? [];
          return usList.any((us) {
            final skill = us['skills'];
            if (skill is Map) {
              final name = (skill['name'] as String?)?.toLowerCase() ?? '';
              final cat = (skill['category'] as String?)?.toLowerCase() ?? '';
              return name.contains(qLower) || cat.contains(qLower);
            }
            return false;
          });
        }).toList();
      }

      return list.take(limit).toList();
    } catch (e) {
      print('Error in getDiscoverProfiles, using fallback: $e');
      return _fallbackGetDiscoverProfiles(
        searchQuery: searchQuery,
        category: category ?? 'All',
        skillLevel: skillLevel ?? 'All',
        limit: limit,
        offset: offset,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fallbackGetDiscoverProfiles({
    String? searchQuery,
    String category = 'All',
    String skillLevel = 'All',
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

      if (currentUserId != null) {
        query = query.neq('id', currentUserId);
      }
      query = query.not('username', 'is', null);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryStr = searchQuery.trim();
        query = query.or('username.ilike.%$queryStr%,full_name.ilike.%$queryStr%');
      }

      final response = await query.range(offset, offset + (limit * 2) - 1);
      var list = List<Map<String, dynamic>>.from(response);

      if (category.toLowerCase() != 'all') {
        final catLower = category.toLowerCase();
        list = list.where((profile) {
          final userSkills = profile['user_skills'] as List? ?? [];
          return userSkills.any((us) {
            final skill = us['skills'];
            if (skill is Map) {
              final cat = (skill['category'] as String?)?.toLowerCase() ?? '';
              return cat.contains(catLower);
            }
            return false;
          });
        }).toList();
      }

      if (skillLevel.toLowerCase() != 'all' && skillLevel.toLowerCase() != 'all levels') {
        final levelLower = skillLevel.toLowerCase();
        list = list.where((p) {
          final exp = (p['experience_level'] as String?)?.toLowerCase() ?? '';
          if (exp.contains(levelLower)) return true;
          final userSkills = p['user_skills'] as List? ?? [];
          return userSkills.any((us) {
            final prof = (us['proficiency_level'] as String?)?.toLowerCase() ?? '';
            return prof.contains(levelLower);
          });
        }).toList();
      }

      return list.take(limit).toList();
    } catch (e) {
      print('Fallback error in getDiscoverProfiles: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
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
        learning_style,
        user_skills (
          type,
          proficiency_level,
          skills (
            id,
            name,
            category
          )
        )
      ''').eq('id', userId).maybeSingle();
      
      if (response != null) return response;
    } catch (e) {
      print('Notice in getProfileById joined query: $e');
    }

    // Fallback: direct profiles query + separate skills query
    try {
      final pResp = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (pResp != null) {
        try {
          final usResp = await _client.from('user_skills').select('type, proficiency_level, skills(id, name, category)').eq('user_id', userId);
          pResp['user_skills'] = usResp;
        } catch (_) {}
        return pResp;
      }
    } catch (e) {
      print('Error in getProfileById fallback: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getProfile(String idOrUsername) async {
    final raw = idOrUsername.trim();
    final clean = raw.startsWith('@') ? raw.substring(1) : raw;

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(clean);

    if (isUuid) {
      final byId = await getProfileById(clean);
      if (byId != null) return byId;
      return getProfileByUsername(clean);
    } else {
      final byUsername = await getProfileByUsername(clean);
      if (byUsername != null) return byUsername;
      return getProfileById(clean);
    }
  }
  
  Future<Map<String, dynamic>?> getProfileByUsername(String username) async {
    final cleanUsername = username.trim().replaceAll('@', '');
    if (cleanUsername.isEmpty) return null;

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
        learning_style,
        user_skills (
          type,
          proficiency_level,
          skills (
            id,
            name,
            category
          )
        )
      ''').ilike('username', cleanUsername).maybeSingle();
      
      if (response != null) return response;
    } catch (e) {
      print('Notice in getProfileByUsername joined query: $e');
    }

    // Fallback: direct profiles query + separate skills query
    try {
      final pResp = await _client.from('profiles').select().ilike('username', cleanUsername).maybeSingle();
      if (pResp != null) {
        final uid = pResp['id'];
        if (uid != null) {
          try {
            final usResp = await _client.from('user_skills').select('type, proficiency_level, skills(id, name, category)').eq('user_id', uid);
            pResp['user_skills'] = usResp;
          } catch (_) {}
        }
        return pResp;
      }
    } catch (e) {
      print('Error in getProfileByUsername fallback: $e');
    }
    return null;
  }
}
