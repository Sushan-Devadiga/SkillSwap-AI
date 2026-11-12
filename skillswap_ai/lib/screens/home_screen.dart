import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/shadcn_ui.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../providers/profile_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/session_provider.dart';

final userStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(statsServiceProvider).getUserStats();
});

// Reuse the centralized activeSwapsProvider for instant synchronized updates
final upcomingSessionsProvider = activeSwapsProvider;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final firstName = userProfile?.fullName.split(' ').first ?? 'User';
    final userTeachingSkill = userProfile?.teachingSkills.isNotEmpty == true 
        ? userProfile!.teachingSkills.first 
        : 'Skills';
        
    final statsAsync = ref.watch(userStatsProvider);
    final stats = statsAsync.value ?? {'skillsLearned': 0, 'skillsShared': 0, 'exchangesCompleted': 0, 'connections': 0};
    
    final sessionsAsync = ref.watch(upcomingSessionsProvider);
    final sessions = sessionsAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surfaceBg.withOpacity(0.9),
            pinned: true,
            elevation: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final currentUsername = ref.read(userProfileProvider).value?.username;
                    if (currentUsername != null && currentUsername.isNotEmpty) {
                      ref.read(mainNavIndexProvider.notifier).setIndex(4);
                    } else {
                      context.push('/profile-setup');
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: userProfile?.avatarUrl != null && userProfile!.avatarUrl.isNotEmpty
                        ? NetworkImage(userProfile.avatarUrl)
                        : null,
                    child: userProfile?.avatarUrl == null || userProfile!.avatarUrl.isEmpty
                        ? Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 14, color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      firstName,
                      style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text('$unreadCount'),
                      child: const Icon(LucideIcons.bell, color: AppColors.onSurface),
                    ),
                    onPressed: () => context.push('/notifications'),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroCard(context, ref),
                const SizedBox(height: 16),
                _buildTimeTokenEconomyCard(context, ref),
                const SizedBox(height: 20),
                
                Text('Your Learning Journey', style: AppTypography.headlineMd),
                const SizedBox(height: 12),
                _buildBentoGrid(context, ref, stats),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.aiGlow.createShader(bounds),
                      child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Text('Your AI Match Today', style: AppTypography.headlineMd),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAiMatch(context, ref, userTeachingSkill),
                
                const SizedBox(height: 24),
                
                Text('Upcoming Session', style: AppTypography.headlineMd),
                const SizedBox(height: 12),
                _buildUpcomingSession(context, ref, sessions),
                
                const SizedBox(height: 80), // Padding for bottom nav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(LucideIcons.zap, size: 200, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn from people.\nShare what you know.',
                  style: AppTypography.headlineLg.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exchange skills with people who have something valuable to teach.',
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () => ref.read(mainNavIndexProvider.notifier).setIndex(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                      ),
                      child: const Text('Find a Skill Match'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/profile-setup'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('Share a Skill'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildTimeTokenEconomyCard(BuildContext context, WidgetRef ref) {
    final tokenBalanceAsync = ref.watch(tokenBalanceProvider);
    final balance = tokenBalanceAsync.value ?? 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTokenEconomySheet(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.coins, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$balance Time Tokens',
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '1 Hr = 1 Token',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Teach to earn • Learn to spend • No tuition',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wallet',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 450.ms, delay: 100.ms).slideY(begin: 0.04, end: 0);
  }

  void _showTokenEconomySheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final balanceAsync = ref.watch(tokenBalanceProvider);
          final balance = balanceAsync.value ?? 3;
          final txAsync = ref.watch(tokenTransactionsProvider);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.coins, color: Color(0xFFF59E0B), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time-as-Currency Wallet', style: AppTypography.headlineMd.copyWith(color: textColor)),
                              Text('1 Hour = 1 Token • Zero Cost Education', style: AppTypography.bodySm.copyWith(color: subTextColor)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: subTextColor, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: borderCol, height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD97706), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Available Time Credit', style: AppTypography.labelSm.copyWith(color: Colors.white70)),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$balance',
                                      style: AppTypography.headlineXl.copyWith(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Time Tokens', style: AppTypography.labelMd.copyWith(color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.info, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Teach 1 hr = +1 Token • Learn 1 hr = -1 Token. Tokens never expire!',
                                          style: AppTypography.bodySm.copyWith(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Why Time Tokens Work', style: AppTypography.labelMd.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            'Time is the great equalizer. Whether you are a senior engineer or a first-year student, your hour is worth exactly one token. Zero cost. Infinite learning.',
                            style: AppTypography.bodySm.copyWith(color: subTextColor, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          Text('Transaction Ledger', style: AppTypography.labelMd.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          txAsync.when(
                            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                            error: (e, _) => Text('Could not load ledger: $e', style: TextStyle(color: subTextColor)),
                            data: (txs) {
                              if (txs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Center(
                                    child: Text('No transactions yet. Complete a swap to start earning!', style: TextStyle(color: subTextColor, fontSize: 12)),
                                  ),
                                );
                              }
                              return Column(
                                children: txs.map((tx) {
                                  final amount = (tx['amount'] as num?)?.toInt() ?? 0;
                                  final isCredit = amount >= 0;
                                  final desc = tx['description'] ?? 'Token transfer';
                                  final createdAtStr = tx['created_at'] as String?;
                                  final dateFormatted = createdAtStr != null
                                      ? DateFormat('MMM d, y • h:mm a').format(DateTime.parse(createdAtStr).toLocal())
                                      : 'Initial Credit';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: borderCol),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                            color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                desc,
                                                style: AppTypography.bodySm.copyWith(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                dateFormatted,
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isCredit ? '+$amount 🪙' : '$amount 🪙',
                                            style: TextStyle(
                                              color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, WidgetRef ref, Map<String, int> stats) {
    if (stats.values.every((v) => v == 0)) {
      return EmptyState(
        title: 'Start your journey',
        description: 'Complete a swap to see your stats grow.',
        icon: LucideIcons.rocket,
        buttonText: 'Find a Match',
        onButtonTap: () => ref.read(mainNavIndexProvider.notifier).setIndex(1),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 520) {
          return Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Skills Learned',
                  value: stats['skillsLearned'] ?? 0,
                  icon: LucideIcons.bookOpen,
                  iconColor: Colors.blue,
                  onTap: () => _showSkillsLearnedModal(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Skills Shared',
                  value: stats['skillsShared'] ?? 0,
                  icon: LucideIcons.award,
                  iconColor: Colors.orange,
                  onTap: () => _showSkillsSharedModal(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Exchanges',
                  value: stats['exchangesCompleted'] ?? 0,
                  icon: LucideIcons.refreshCcw,
                  iconColor: Colors.green,
                  onTap: () => _showExchangesModal(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  title: 'Connections',
                  value: stats['connections'] ?? 0,
                  icon: LucideIcons.users,
                  iconColor: Colors.purple,
                  onTap: () => _showConnectionsModal(context, ref),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Skills Learned',
                      value: stats['skillsLearned'] ?? 0,
                      icon: LucideIcons.bookOpen,
                      iconColor: Colors.blue,
                      onTap: () => _showSkillsLearnedModal(context, ref),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Skills Shared',
                      value: stats['skillsShared'] ?? 0,
                      icon: LucideIcons.award,
                      iconColor: Colors.orange,
                      onTap: () => _showSkillsSharedModal(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Exchanges',
                      value: stats['exchangesCompleted'] ?? 0,
                      icon: LucideIcons.refreshCcw,
                      iconColor: Colors.green,
                      onTap: () => _showExchangesModal(context, ref),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      title: 'Connections',
                      value: stats['connections'] ?? 0,
                      icon: LucideIcons.users,
                      iconColor: Colors.purple,
                      onTap: () => _showConnectionsModal(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  void _showStatsBottomSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.headlineMd.copyWith(color: textColor)),
                          Text(subtitle, style: AppTypography.bodySm.copyWith(color: subTextColor)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: subTextColor, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Divider(color: borderCol, height: 1),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectionsModal(BuildContext context, WidgetRef ref) {
    _showStatsBottomSheet(
      context: context,
      title: 'Your Connections',
      subtitle: 'Peers you have connected with on SkillSwap',
      icon: LucideIcons.users,
      iconColor: Colors.purple,
      child: Consumer(
        builder: (context, ref, _) {
          final connectionsAsync = ref.watch(connectionsProvider);
          final currentUserId = ref.read(authServiceProvider).currentUser?.id;

          return connectionsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('Error loading connections: $err')),
            ),
            data: (connections) {
              if (connections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: EmptyState(
                    title: 'No connections yet',
                    description: 'Explore Discover to connect with learners and teachers.',
                    icon: LucideIcons.users,
                    buttonText: 'Find People to Connect',
                    onButtonTap: () {
                      Navigator.pop(context);
                      ref.read(mainNavIndexProvider.notifier).setIndex(1);
                    },
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: connections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = connections[index];
                  final isRequester = item['requester_id'] == currentUserId;
                  final peer = (isRequester ? item['receiver'] : item['requester']) as Map<String, dynamic>?;
                  final peerName = peer?['full_name'] as String? ?? 'Peer';
                  final peerUsername = peer?['username'] as String? ?? 'user';
                  final peerAvatar = peer?['avatar_url'] as String?;
                  final peerId = peer?['id'] as String? ?? '';

                  final targetRoute = peerId.isNotEmpty ? '/profile/$peerId' : '/profile/$peerUsername';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            context.push(targetRoute);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryContainer,
                                  backgroundImage: peerAvatar != null && peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                                  child: peerAvatar == null || peerAvatar.isEmpty
                                      ? Text(peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(peerName, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
                                      Text('@$peerUsername', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.checkCheck, size: 12, color: AppColors.primaryContainer),
                                      const SizedBox(width: 4),
                                      Text('Connected', style: AppTypography.labelSm.copyWith(color: AppColors.primaryContainer, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('/chat/$peerUsername');
                                },
                                icon: const Icon(LucideIcons.messageSquare, size: 14),
                                label: const Text('Chat'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('/schedule/$peerUsername');
                                },
                                icon: const Icon(LucideIcons.calendar, size: 14),
                                label: const Text('Schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push(targetRoute);
                              },
                              icon: const Icon(LucideIcons.user, size: 16),
                              tooltip: 'View Profile',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showSkillsLearnedModal(BuildContext context, WidgetRef ref) {
    _showStatsBottomSheet(
      context: context,
      title: 'Skills Learned',
      subtitle: 'Skills acquired through completed skill swap exchanges',
      icon: LucideIcons.bookOpen,
      iconColor: Colors.blue,
      child: Consumer(
        builder: (context, ref, _) {
          final skillsAsync = ref.watch(learnedSkillsProvider);

          return skillsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('Error loading learned skills: $err')),
            ),
            data: (skills) {
              if (skills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: EmptyState(
                    title: 'No skills learned yet',
                    description: 'Complete a swap session where a partner teaches you to log learned skills here.',
                    icon: LucideIcons.bookOpen,
                    buttonText: 'Find Skills to Learn',
                    onButtonTap: () {
                      Navigator.pop(context);
                      ref.read(mainNavIndexProvider.notifier).setIndex(1);
                    },
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: skills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = skills[index];
                  final skill = item['skill'] as Map<String, dynamic>?;
                  final skillName = skill?['name'] as String? ?? 'Skill';
                  final provider = item['provider'] as Map<String, dynamic>?;
                  final providerName = provider?['full_name'] as String? ?? 'Mentor';
                  final rating = item['rating'] as int? ?? 5;
                  final hours = (item['hours_exchanged'] as num?)?.toDouble() ?? 1.0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceStroke),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.bookOpen, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skillName, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('Taught by $providerName • ${hours.toStringAsFixed(1)}h', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text('$rating.0', style: AppTypography.labelMd),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showSkillsSharedModal(BuildContext context, WidgetRef ref) {
    _showStatsBottomSheet(
      context: context,
      title: 'Skills Shared',
      subtitle: 'Skills and expertise you have taught to others',
      icon: LucideIcons.award,
      iconColor: Colors.orange,
      child: Consumer(
        builder: (context, ref, _) {
          final skillsAsync = ref.watch(sharedSkillsProvider);

          return skillsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('Error loading shared skills: $err')),
            ),
            data: (skills) {
              if (skills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: EmptyState(
                    title: 'No skills shared yet',
                    description: 'Teach skills in swap sessions with peers to grow your mentoring reputation.',
                    icon: LucideIcons.award,
                    buttonText: 'View Pending Requests',
                    onButtonTap: () {
                      Navigator.pop(context);
                      ref.read(mainNavIndexProvider.notifier).setIndex(3);
                    },
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: skills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = skills[index];
                  final skill = item['skill'] as Map<String, dynamic>?;
                  final skillName = skill?['name'] as String? ?? 'Skill';
                  final receiver = item['receiver'] as Map<String, dynamic>?;
                  final receiverName = receiver?['full_name'] as String? ?? 'Learner';
                  final hours = (item['hours_exchanged'] as num?)?.toDouble() ?? 1.0;
                  final feedback = item['feedback'] as String? ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.award, color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(skillName, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('Learned by $receiverName • ${hours.toStringAsFixed(1)}h', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (feedback.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '"$feedback"',
                              style: AppTypography.bodySm.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showExchangesModal(BuildContext context, WidgetRef ref) {
    _showStatsBottomSheet(
      context: context,
      title: 'Completed Exchanges',
      subtitle: 'Complete history of your 1-on-1 skill swaps',
      icon: LucideIcons.refreshCcw,
      iconColor: Colors.green,
      child: Consumer(
        builder: (context, ref, _) {
          final exchangesAsync = ref.watch(exchangesProvider);

          return exchangesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('Error loading exchanges: $err')),
            ),
            data: (exchanges) {
              if (exchanges.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: EmptyState(
                    title: 'No exchanges completed yet',
                    description: 'Schedule a session or complete an ongoing swap to see your records here.',
                    icon: LucideIcons.refreshCcw,
                    buttonText: 'Find a Partner',
                    onButtonTap: () {
                      Navigator.pop(context);
                      ref.read(mainNavIndexProvider.notifier).setIndex(1);
                    },
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: exchanges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = exchanges[index];
                  final skill = item['skill'] as Map<String, dynamic>?;
                  final skillName = skill?['name'] as String? ?? 'Skill Swap';
                  final provider = item['provider'] as Map<String, dynamic>?;
                  final receiver = item['receiver'] as Map<String, dynamic>?;
                  final hours = (item['hours_exchanged'] as num?)?.toDouble() ?? 1.0;
                  final rating = item['rating'] as int? ?? 5;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceStroke),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.refreshCcw, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skillName, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('${provider?['full_name'] ?? 'Provider'} ⇄ ${receiver?['full_name'] ?? 'Learner'}', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                              Text('${hours.toStringAsFixed(1)} hours exchanged', style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text('$rating.0', style: AppTypography.labelMd),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAiMatch(BuildContext context, WidgetRef ref, String userTeachingSkill) {
    final matchesAsyncValue = ref.watch(matchesProvider);
    
    return matchesAsyncValue.when(
      loading: () => const Skeleton(height: 200, borderRadius: 16),
      error: (err, stack) => Text('Error loading matches: $err'),
      data: (matches) {
        if (matches.isEmpty) {
          return EmptyState(
            title: 'No strong matches yet',
            description: 'We are looking for the perfect skill exchange partner for you.',
            icon: LucideIcons.search,
            buttonText: 'Update Skills',
            onButtonTap: () => context.push('/profile-setup'),
          );
        }
        
        final match = matches.first;
        final similarityPercent = (match.similarity * 100).toStringAsFixed(0);
        
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceStroke),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: AppColors.aiGlow,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: match.avatarUrl != null ? NetworkImage(match.avatarUrl!) : null,
                          child: match.avatarUrl == null ? const Icon(LucideIcons.user) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.fullName, style: AppTypography.headlineMd),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(LucideIcons.zap, size: 14, color: AppColors.primaryContainer),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$similarityPercent% Match',
                                    style: AppTypography.labelSm.copyWith(color: AppColors.primaryContainer),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (match.username != null && match.username.toString().isNotEmpty) {
                              context.push('/profile/${match.username}');
                            } else {
                              context.push(Uri(path: '/match', queryParameters: {'id': match.userId, 'name': match.fullName, 'skill': match.skillName, 'similarity': similarityPercent}).toString());
                            }
                          },
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You teach', style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(userTeachingSkill, style: AppTypography.labelMd),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.arrowRightLeft, color: AppColors.primary, size: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('They teach', style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(match.skillName, style: AppTypography.labelMd),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildUpcomingSession(BuildContext context, WidgetRef ref, List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return EmptyState(
        title: 'No upcoming sessions',
        description: 'Schedule a session with a match to start learning.',
        icon: LucideIcons.calendar,
      );
    }
    
    final session = sessions.first;
    final title = session['title'] ?? 'Skill Swap Session';
    final scheduledTime = DateTime.parse(session['scheduled_time']);
    final duration = session['duration_minutes'] ?? 45;
    
    String timeStr = '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    String dateStr = '${scheduledTime.month}/${scheduledTime.day}';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceStroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.calendarClock, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineMd),
                const SizedBox(height: 4),
                Text('$dateStr • $timeStr • $duration min', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              final link = session['meeting_link'] as String?;
              if (link != null && link.isNotEmpty) {
                ref.read(sessionServiceProvider).openMeetingLink(link);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No meeting link available for this session.')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
