import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/cards.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';

class LearningProgressScreen extends ConsumerWidget {
  const LearningProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSwapsAsync = ref.watch(activeSwapsProvider);
    final completedSkillsAsync = ref.watch(completedSkillsProvider);
    final currentUserId = ref.watch(authServiceProvider).currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeSwapsProvider);
          ref.invalidate(completedSkillsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Swaps',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              activeSwapsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (activeSwaps) {
                  if (activeSwaps.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No active swaps found. Start a new session!',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: activeSwaps.map((session) {
                      // Find peer participant
                      final participants = session['session_participants'] as List? ?? [];
                      Map<String, dynamic>? peerProfile;
                      
                      for (var p in participants) {
                        if (p['participant_id'] != currentUserId && p['profiles'] != null) {
                          peerProfile = p['profiles'] as Map<String, dynamic>;
                          break;
                        }
                      }
                      
                      final peerName = peerProfile?['full_name'] ?? peerProfile?['username'] ?? 'Unknown User';
                      final initial = peerName.isNotEmpty ? peerName[0].toUpperCase() : '?';
                      
                      final title = session['title'] ?? 'Session';
                      final status = session['status'] == 'in_progress' ? 'In Progress' : 'Scheduled';
                      final scheduledTimeStr = session['scheduled_time'];
                      final scheduledTime = scheduledTimeStr != null ? DateTime.parse(scheduledTimeStr).toLocal() : null;
                      final formattedTime = scheduledTime != null ? DateFormat('EEEE, h:mm a').format(scheduledTime) : 'TBD';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: StandardCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primaryContainer,
                                        child: Text(initial, style: const TextStyle(color: AppColors.onPrimaryContainer, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        peerName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(status, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Title: $title', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 16, color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('Next session: $formattedTime', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              Text(
                'Completed Skills',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              completedSkillsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (completedSkills) {
                  if (completedSkills.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No completed skills yet. Complete a session to see them here!',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: completedSkills.map((exchange) {
                      final skill = exchange['skills'] as Map<String, dynamic>?;
                      final skillName = skill?['name'] ?? 'Unknown Skill';
                      
                      final provider = exchange['provider'] as Map<String, dynamic>?;
                      final providerName = provider?['full_name'] ?? provider?['username'] ?? 'Unknown Mentor';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: StandardCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.workspace_premium, color: Colors.green.shade800),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(skillName, style: Theme.of(context).textTheme.titleMedium),
                                    Text('Mentored by $providerName', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
