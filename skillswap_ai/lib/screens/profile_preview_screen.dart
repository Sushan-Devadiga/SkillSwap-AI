import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/chips.dart';
import '../providers/profile_provider.dart';

class ProfilePreviewScreen extends ConsumerStatefulWidget {
  const ProfilePreviewScreen({super.key});

  @override
  ConsumerState<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        await ref.read(userProfileProvider.notifier).submitOnboarding(profile);
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value ?? UserProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
      ),
      body: _isSubmitting 
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving your ecosystem...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Looking good!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review your profile before jumping in.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  
                  StandardCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.primaryContainer,
                              child: Icon(Icons.person, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.location.isNotEmpty ? profile.location : 'Earth',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    profile.timezone.isNotEmpty ? profile.timezone : 'UTC',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bio',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(profile.bio),
                        
                        const Divider(height: 32),
                        
                        Text(
                          'Can Teach (${profile.experienceLevel})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.teachingSkills.map((s) => SkillChip(label: s)).toList(),
                        ),
                        
                        const Divider(height: 32),
                        
                        Text(
                          'Wants to Learn',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.learningSkills.map((s) => SkillChip(label: s, isSelected: true)).toList(),
                        ),
                        
                        if (profile.learningGoals.isNotEmpty) ...[
                          const Divider(height: 32),
                          Text(
                            'Goals',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...profile.learningGoals.map((g) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(g)),
                                  ],
                                ),
                              ))
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Complete Profile',
                    icon: Icons.rocket_launch,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
