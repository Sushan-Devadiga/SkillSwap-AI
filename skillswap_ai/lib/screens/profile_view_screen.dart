import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import '../services/token_service.dart';
import '../providers/profile_provider.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out',
          style: AppTypography.headlineMd.copyWith(color: isDark ? Colors.white : AppColors.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: AppTypography.bodyMd.copyWith(color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    User? user,
    bool isDark,
  ) {
    context.push('/edit-profile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final profile = ref.watch(userProfileProvider).value;
    final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest;
    final screenBg = isDark ? const Color(0xFF0F172A) : AppColors.surfaceBg;
    final strokeColor = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    final statsAsync = ref.watch(userProfileStatsProvider);
    final stats = statsAsync.value ?? {
      'swaps': '0',
      'rating': '5.0',
      'connections': '0',
    };

    final tokenBalanceAsync = ref.watch(tokenBalanceProvider);
    final tokenBalance = tokenBalanceAsync.value ?? profile?.timeTokens ?? 3;

    final teachingSkills = (profile?.teachingSkills.isNotEmpty == true)
        ? profile!.teachingSkills
        : ['UI/UX Design', 'Flutter'];
    final learningSkills = (profile?.learningSkills.isNotEmpty == true)
        ? profile!.learningSkills
        : ['Python', 'French'];

    final displayName = (profile?.fullName != null && profile!.fullName.isNotEmpty)
        ? profile.fullName
        : (user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'Creator');

    final displayUsername = (profile?.username != null && profile!.username.isNotEmpty)
        ? profile.username
        : (user?.email?.split('@').first ?? 'creator');

    final location = profile?.location;
    final bio = profile?.bio;

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        backgroundColor: screenBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Account & Profile',
          style: AppTypography.headlineLg.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, size: 20),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileSheet(context, ref, profile, user, isDark),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => _showLogoutDialog(context, ref, isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),

          // 1. Profile Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: strokeColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar + Edit trigger
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/edit-profile'),
                    child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: hasAvatar ? NetworkImage(profile.avatarUrl) : null,
                        child: !hasAvatar
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  ),
                ),
                const SizedBox(height: 14),

                // Name
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Username & badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '@$displayUsername',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.checkCircle2, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Active Member',
                            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Bio
                Text(
                  bio != null && bio.isNotEmpty
                      ? bio
                      : 'UI/UX design engineer looking forward to swapping skills with fellow creators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
                ),

                if (location != null && location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(location, style: TextStyle(color: textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Bento Stats Grid (Tokens, Swaps, Rating, Connections)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.coins,
                  iconColor: const Color(0xFFF59E0B),
                  value: '$tokenBalance',
                  label: 'Time Tokens',
                  cardBg: cardBg,
                  strokeColor: strokeColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.repeat,
                  iconColor: AppColors.primary,
                  value: '${stats['swaps'] ?? 0}',
                  label: 'Swaps Done',
                  cardBg: cardBg,
                  strokeColor: strokeColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.star,
                  iconColor: const Color(0xFFEAB308),
                  value: '${stats['rating'] ?? "5.0"}',
                  label: 'Rating',
                  cardBg: cardBg,
                  strokeColor: strokeColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.users,
                  iconColor: const Color(0xFF6366F1),
                  value: '${stats['connections'] ?? 0}',
                  label: 'Network',
                  cardBg: cardBg,
                  strokeColor: strokeColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Skills I Teach
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: strokeColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.graduationCap, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Skills I Teach',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: teachingSkills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Skills I Want to Learn
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: strokeColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.bookOpen, size: 20, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Text(
                      'Skills I Want to Learn',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: learningSkills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.bookmark, size: 14, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(s, style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Log Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, ref, isDark),
              icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 18),
              label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          // Padding so floating nav pill doesn't overlap
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color cardBg,
    required Color strokeColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strokeColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
