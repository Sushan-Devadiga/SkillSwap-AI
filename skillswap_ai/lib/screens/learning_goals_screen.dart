import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/inputs.dart';
import '../providers/profile_provider.dart';

class LearningGoalsScreen extends ConsumerStatefulWidget {
  const LearningGoalsScreen({super.key});

  @override
  ConsumerState<LearningGoalsScreen> createState() => _LearningGoalsScreenState();
}

class _LearningGoalsScreenState extends ConsumerState<LearningGoalsScreen> {
  final _goalController = TextEditingController();
  final List<String> _goals = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.learningGoals.isNotEmpty) {
      _goals.addAll(profile.learningGoals);
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _addGoal() {
    final text = _goalController.text.trim();
    if (text.isNotEmpty && !_goals.contains(text)) {
      setState(() {
        _goals.add(text);
        _goalController.clear();
      });
    }
  }

  void _removeGoal(String goal) {
    setState(() {
      _goals.remove(goal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Specific Goals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are your specific goals?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add specific outcomes you want to achieve (e.g., "Build my first mobile app").',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: CustomInputField(
                    label: 'New Goal',
                    hintText: 'Type a goal...',
                    controller: _goalController,
                    onSubmitted: (_) => _addGoal(),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: IconButton.filled(
                    onPressed: _addGoal,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView.separated(
                itemCount: _goals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_goals[index]),
                    leading: const Icon(Icons.flag_outlined, color: AppColors.primary),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.outline),
                      onPressed: () => _removeGoal(_goals[index]),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.surfaceStroke),
                    ),
                    tileColor: AppColors.surfaceContainerLowest,
                  );
                },
              ),
            ),
            
            PrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: () {
                final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                ref.read(userProfileProvider.notifier).updateLocalState(
                  currentProfile.copyWith(learningGoals: _goals)
                );
                context.push('/availability');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
