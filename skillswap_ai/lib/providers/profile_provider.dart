import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class UserProfile {
  final String username;
  final String fullName;
  final String avatarUrl;
  final String bio;
  final String location;
  final String timezone;
  final String experienceLevel;
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
      teachingSkills: teachingSkills ?? this.teachingSkills,
      learningSkills: learningSkills ?? this.learningSkills,
      learningGoals: learningGoals ?? this.learningGoals,
      availability: availability ?? this.availability,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, bool complete) {
    return UserProfile(
      username: map['username'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      location: map['location'] as String? ?? '',
      timezone: map['timezone'] as String? ?? '',
      experienceLevel: map['experience_level'] as String? ?? '',
      learningGoals: List<String>.from(map['learning_goals'] ?? []),
      availability: map['availability'] as String? ?? '',
      teachingSkills: [], 
      learningSkills: [],
      isComplete: complete,
    );
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  FutureOr<UserProfile> build() async {
    return _fetchProfile();
  }

  Future<UserProfile> _fetchProfile() async {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) {
      return UserProfile();
    }

    final profileService = ref.read(profileServiceProvider);
    final data = await profileService.getProfile(user.id);
    if (data != null) {
      // Determine completeness. For testing/flexibility, we consider it complete if it has a username.
      final bool complete = (data['username'] != null && data['username'].toString().isNotEmpty);
      return UserProfile.fromMap(data, complete);
    }
    
    
    return UserProfile(fullName: user.userMetadata?['full_name'] ?? '');
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  void updateLocalState(UserProfile newProfile) {
    state = AsyncData(newProfile);
  }

  Future<void> submitOnboarding(UserProfile finalProfile) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final profileService = ref.read(profileServiceProvider);
    
    // 1. Upsert basic profile data
    await profileService.upsertProfile(user.id, {
      'full_name': finalProfile.fullName.isNotEmpty ? finalProfile.fullName : (user.userMetadata?['full_name'] ?? 'User'),
      'username': finalProfile.username,
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

    // Mark as complete
    state = AsyncData(finalProfile.copyWith(isComplete: true));
  }
}

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile>(() {
  return UserProfileNotifier();
});
