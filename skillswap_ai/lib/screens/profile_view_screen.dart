import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../providers/profile_provider.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    final profile = ref.watch(userProfileProvider).value;
    final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: hasAvatar ? NetworkImage(profile!.avatarUrl) : null,
              child: !hasAvatar ? const Icon(Icons.person, size: 50, color: AppColors.onPrimaryContainer) : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile?.fullName ?? user?.email ?? 'User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lifelong Learner',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              context,
              title: 'Teaching',
              icon: Icons.school,
              skills: ['Graphic Design', 'Figma'],
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              title: 'Learning',
              icon: Icons.menu_book,
              skills: ['Python', 'Data Science'],
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<String> skills}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: skills.map((s) => SkillChip(label: s, isSelected: true, onTap: () {})).toList(),
        ),
      ],
    );
  }
}
