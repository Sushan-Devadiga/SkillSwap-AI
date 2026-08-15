import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String userId;
  final String fullName;
  final String skillName;
  final String similarity;
  final String? avatarUrl;

  const MatchDetailsScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.skillName,
    required this.similarity,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? const Icon(Icons.person, size: 60) : null,
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, color: AppColors.primaryContainer),
                const SizedBox(width: 8),
                Text(
                  '$similarity% Compatibility',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            AiSuggestedCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Why this is a great match',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Based on our AI analysis, $fullName excels at $skillName which exactly matches your current learning goals. Their schedule also strongly aligns with yours on weekday evenings.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Pass', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'Request Swap',
                    icon: Icons.handshake,
                    onPressed: () {
                      context.push('/swap-request/$userId');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
