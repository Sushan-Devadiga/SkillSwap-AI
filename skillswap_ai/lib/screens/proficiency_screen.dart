import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../providers/profile_provider.dart';

class ProficiencyScreen extends ConsumerStatefulWidget {
  const ProficiencyScreen({super.key});

  @override
  ConsumerState<ProficiencyScreen> createState() => _ProficiencyScreenState();
}

class _ProficiencyScreenState extends ConsumerState<ProficiencyScreen> {
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.experienceLevel.isNotEmpty) {
      _selectedLevel = profile.experienceLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience Level'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How experienced are you?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select your general proficiency level for the skills you plan to teach.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: ListView.separated(
                itemCount: _levels.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  final isSelected = _selectedLevel == level;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLevel = level;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceStroke,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.2) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : AppColors.outline,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            level,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            PrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: () {
                if (_selectedLevel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an experience level.')),
                  );
                  return;
                }
                final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                ref.read(userProfileProvider.notifier).updateLocalState(
                  currentProfile.copyWith(experienceLevel: _selectedLevel)
                );
                context.push('/learning-skills');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
