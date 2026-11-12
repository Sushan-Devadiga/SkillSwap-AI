import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

class UserProfile {
  final String username;
  final String fullName;
  final String avatarUrl;
  final String bio;
  final String location;
  final String timezone;
  final String experienceLevel;
  final String learningStyle;
  final int timeTokens;
  final List<String> teachingSkills;
  final List<String> learningSkills;
  final List<String> learningGoals;
  final String availability;
  final bool isComplete;

  UserProfile({
    this.username = '',
    this.fullName = '',
    this.avatarUrl = '',
    this.bio = '',
    this.location = '',
    this.timezone = '',
    this.experienceLevel = '',
    this.learningStyle = 'Visual',
    this.timeTokens = 3,
    this.teachingSkills = const [],
    this.learningSkills = const [],
    this.learningGoals = const [],
    this.availability = '',
    this.isComplete = false,
  });

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? location,
    String? timezone,
    String? experienceLevel,
    String? learningStyle,
    int? timeTokens,
    List<String>? teachingSkills,
    List<String>? learningSkills,
    List<String>? learningGoals,
    String? availability,
    bool? isComplete,
  }) {
    return UserProfile(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      timezone: timezone ?? this.timezone,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      timeTokens: timeTokens ?? this.timeTokens,
      teachingSkills: teachingSkills ?? this.teachingSkills,
      learningSkills: learningSkills ?? this.learningSkills,
      learningGoals: learningGoals ?? this.learningGoals,
      availability: availability ?? this.availability,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, bool complete, {String? fallbackLearningStyle}) {
    final userSkills = map['user_skills'] as List? ?? [];
    final teaching = <String>[];
    final learning = <String>[];

    for (var us in userSkills) {
      final skill = us['skills'];
      if (skill is Map && skill['name'] != null) {
        final name = skill['name'] as String;
        if (us['type'] == 'TEACH') {
          teaching.add(name);
        } else if (us['type'] == 'LEARN') {
          learning.add(name);
        }
      }
    }

    return UserProfile(
      username: map['username'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      location: map['location'] as String? ?? '',
      timezone: map['timezone'] as String? ?? '',
      experienceLevel: map['experience_level'] as String? ?? '',
      learningStyle: map['learning_style'] as String? ?? fallbackLearningStyle ?? 'Visual',
      timeTokens: (map['time_tokens'] as num?)?.toInt() ?? 3,
      learningGoals: List<String>.from(map['learning_goals'] ?? []),
      availability: map['availability'] as String? ?? '',
      teachingSkills: teaching,
      learningSkills: learning,
      isComplete: complete,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  FutureOr<UserProfile> build() async {
    // Watch authState so that whenever sign-in, sign-out, or session restore occurs,
    // this provider automatically rebuilds and fetches fresh database state.
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      return UserProfile(isComplete: false);
    }

    return _fetchProfile(
      user.id,
      user.userMetadata?['full_name'] as String?,
      metadataLearningStyle: user.userMetadata?['learning_style'] as String?,
    );
  }

  Future<UserProfile> _fetchProfile(
    String userId,
    String? metadataFullName, {
    String? metadataLearningStyle,
  }) async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final data = await profileService.getProfile(userId);
      
      if (data != null) {
        final username = data['username'] as String?;
        // Profile is complete if username exists and is not empty
        final bool complete = username != null && username.trim().isNotEmpty;
        return UserProfile.fromMap(data, complete, fallbackLearningStyle: metadataLearningStyle);
      }
      
      return UserProfile(
        fullName: metadataFullName ?? '',
        learningStyle: metadataLearningStyle ?? 'Visual',
        isComplete: false,
      );
    } catch (e) {
      print('Error in _fetchProfile: $e');
      return UserProfile(isComplete: false);
    }
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return UserProfile(isComplete: false);
      return _fetchProfile(
        user.id,
        user.userMetadata?['full_name'] as String?,
        metadataLearningStyle: user.userMetadata?['learning_style'] as String?,
      );
    });
  }

  void updateLocalState(UserProfile newProfile) {
    state = AsyncData(newProfile);
  }

  Future<void> submitOnboarding(UserProfile finalProfile) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final profileService = ref.read(profileServiceProvider);
    final cleanUsername = finalProfile.username.trim().toLowerCase();

    if (cleanUsername.isEmpty) {
      throw Exception('Username cannot be empty.');
    }

    // Verify username availability before writing to DB
    final isAvailable = await profileService.isUsernameAvailable(cleanUsername, user.id);
    if (!isAvailable) {
      throw Exception('The username "$cleanUsername" is already taken. Please choose a different username.');
    }
    
    // Persist learning_style to auth user_metadata (does not require DDL schema change)
    if (finalProfile.learningStyle.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'learning_style': finalProfile.learningStyle}),
        );
      } catch (e) {
        print('Notice updating auth metadata for learning_style: $e');
      }
    }

    // 1. Upsert profile data (only verified database columns)
    await profileService.upsertProfile(user.id, {
      'full_name': finalProfile.fullName.isNotEmpty ? finalProfile.fullName : (user.userMetadata?['full_name'] ?? 'User'),
      'username': cleanUsername,
      'avatar_url': finalProfile.avatarUrl,
      'bio': finalProfile.bio,
      'location': finalProfile.location,
      'timezone': finalProfile.timezone,
      'experience_level': finalProfile.experienceLevel,
      'learning_goals': finalProfile.learningGoals,
      'availability': finalProfile.availability,
    });

    // 2. Resolve teaching skills
    List<Map<String, dynamic>> userSkillsData = [];
    
    for (String skillName in finalProfile.teachingSkills) {
      final skillId = await profileService.getOrCreateSkill(skillName);
      if (skillId != null) {
        userSkillsData.add({
          'user_id': user.id,
          'skill_id': skillId,
          'type': 'TEACH',
          'proficiency_level': finalProfile.experienceLevel.isNotEmpty ? finalProfile.experienceLevel : 'Intermediate',
        });
      }
    }

    // 3. Resolve learning skills
    for (String skillName in finalProfile.learningSkills) {
      final skillId = await profileService.getOrCreateSkill(skillName);
      if (skillId != null) {
        userSkillsData.add({
          'user_id': user.id,
          'skill_id': skillId,
          'type': 'LEARN',
        });
      }
    }

    // 4. Save to user_skills table
    if (userSkillsData.isNotEmpty) {
      await profileService.saveUserSkills(user.id, userSkillsData);
    }

    // 5. Initialize welcome token bonus ledger record
    try {
      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.initializeWelcomeBonus(user.id);
    } catch (e) {
      print('Notice initializing welcome bonus: $e');
    }

    // 6. Mark as complete and refresh state
    await refreshProfile();
  }

  Future<void> updateProfileDetails({
    String? fullName,
    String? username,
    String? bio,
    String? location,
    String? timezone,
    String? learningStyle,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final profileService = ref.read(profileServiceProvider);
    final updates = <String, dynamic>{};

    if (fullName != null) updates['full_name'] = fullName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (location != null) updates['location'] = location.trim();
    if (timezone != null) updates['timezone'] = timezone.trim();
    if (learningStyle != null && learningStyle.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'learning_style': learningStyle.trim()}),
        );
      } catch (e) {
        print('Notice updating learning style metadata: $e');
      }
    }

    if (username != null && username.trim().isNotEmpty) {
      final cleanUsername = username.trim().toLowerCase();
      final currentUsername = state.value?.username.toLowerCase();
      if (cleanUsername != currentUsername) {
        final isAvailable = await profileService.isUsernameAvailable(cleanUsername, user.id);
        if (!isAvailable) {
          throw Exception('The username "$cleanUsername" is already taken.');
        }
      }
      updates['username'] = cleanUsername;
    }

    if (updates.isNotEmpty) {
      await profileService.upsertProfile(user.id, updates);
      await refreshProfile();
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
