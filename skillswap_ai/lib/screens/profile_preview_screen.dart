import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
        String msg = e.toString();
        if (msg.contains('profiles_username_key') || msg.contains('already taken')) {
          final profile = ref.read(userProfileProvider).value;
          final uname = profile?.username ?? '';
          msg = 'The username "@$uname" is already taken. Please go back and choose a different username.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Change Username',
              textColor: Colors.white,
              onPressed: () => context.go('/profile-setup'),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryEmerald = Color(0xFF059669);

    final hasAvatar = profile.avatarUrl.isNotEmpty;
    final displayName = profile.fullName.isNotEmpty ? profile.fullName : profile.username;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile Preview',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0, // Complete!
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(primaryEmerald),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STEP BADGE
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryEmerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'STEP 7 OF 7 • FINAL REVIEW',
                                style: TextStyle(
                                  color: primaryEmerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ecosystem Launch',
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // HEADLINE & SUBTITLE
                        Text(
                          'Looking good!',
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Review your profile card before jumping into the SkillSwap peer network.',
                          style: AppTypography.bodyMd.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // HERO PROFILE BENTO CARD
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: strokeColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Decorative Header Banner with Overlapping Avatar
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: 84,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF065F46),
                                          Color(0xFF047857),
                                          Color(0xFF0D9488),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    bottom: -36,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          width: 3.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        image: hasAvatar
                                            ? DecorationImage(
                                                image: NetworkImage(profile.avatarUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: !hasAvatar
                                          ? Center(
                                              child: Text(
                                                (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
                                                style: const TextStyle(
                                                  color: primaryEmerald,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),

                              // Avatar space + User Details, Bio & Badges
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row placing Name & Username cleanly to the right of the overlapping avatar
                                    Row(
                                      children: [
                                        const SizedBox(width: 72 + 14), // Reserved space for the 72px avatar
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: AppTypography.headlineMd.copyWith(
                                                        color: textPrimary,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    LucideIcons.badgeCheck,
                                                    color: primaryEmerald,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '@${profile.username.isNotEmpty ? profile.username : "username"}',
                                                style: AppTypography.bodySm.copyWith(
                                                  color: primaryEmerald,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    if (profile.bio.isNotEmpty) ...[
                                      Text(
                                        profile.bio,
                                        style: AppTypography.bodyMd.copyWith(
                                          color: textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (profile.location.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.mapPin, size: 12, color: primaryEmerald),
                                                const SizedBox(width: 4),
                                                Text(
                                                  profile.location,
                                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (profile.timezone.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.globe, size: 12, color: primaryEmerald),
                                                const SizedBox(width: 4),
                                                Text(
                                                  profile.timezone,
                                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (profile.learningStyle.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: primaryEmerald.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.brain, size: 12, color: primaryEmerald),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${profile.learningStyle} Learner',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: primaryEmerald,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // TIME TOKEN INITIAL BALANCE CARD (PPT Highlight)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                                  : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: primaryEmerald.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: primaryEmerald.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.coins, color: primaryEmerald, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome Grant: 3 Time Tokens',
                                      style: TextStyle(
                                        color: primaryEmerald,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your wallet is credited with 3 initial Time Tokens. Earn +1 token for every 1 hour you teach!',
                                      style: AppTypography.bodySm.copyWith(color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // BENTO GRID 1: WHAT YOU CAN TEACH
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: strokeColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.graduationCap, color: primaryEmerald, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Can Teach',
                                        style: AppTypography.headlineMd.copyWith(
                                          color: textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryEmerald.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      profile.experienceLevel.isNotEmpty ? profile.experienceLevel : 'Intermediate',
                                      style: const TextStyle(
                                        color: primaryEmerald,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (profile.teachingSkills.isEmpty)
                                Text(
                                  'No teaching skills selected yet.',
                                  style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profile.teachingSkills.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                            : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryEmerald.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.sparkles, size: 12, color: primaryEmerald),
                                          const SizedBox(width: 6),
                                          Text(
                                            s,
                                            style: const TextStyle(
                                              color: primaryEmerald,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // BENTO GRID 2: WHAT YOU WANT TO LEARN
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: strokeColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.bookOpen, color: Color(0xFF0284C7), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Wants to Learn',
                                    style: AppTypography.headlineMd.copyWith(
                                      color: textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (profile.learningSkills.isEmpty)
                                Text(
                                  'No learning skills selected yet.',
                                  style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: profile.learningSkills.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF0369A1).withValues(alpha: 0.25)
                                            : const Color(0xFFF0F9FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.flame, size: 12, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 6),
                                          Text(
                                            s,
                                            style: const TextStyle(
                                              color: Color(0xFF0284C7),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // BENTO GRID 3: SPECIFIC GOALS (IF ANY)
                        if (profile.learningGoals.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: strokeColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.target, color: primaryEmerald, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Target Milestones',
                                      style: AppTypography.headlineMd.copyWith(
                                        color: textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...profile.learningGoals.map((goal) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: primaryEmerald.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(LucideIcons.check, size: 12, color: primaryEmerald),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            goal,
                                            style: AppTypography.bodyMd.copyWith(
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // BENTO GRID 4: AVAILABILITY SUMMARY
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: strokeColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendarCheck, color: primaryEmerald, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Swap Schedule',
                                    style: AppTypography.headlineMd.copyWith(
                                      color: textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                profile.availability.isNotEmpty
                                    ? profile.availability
                                    : 'Mon, Wed, Fri - 60 min sessions',
                                style: AppTypography.bodyMd.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // STICKY BOTTOM CONFIRM BUTTON
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgCard,
                    border: Border(top: BorderSide(color: strokeColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(LucideIcons.rocket, size: 18),
                          label: Text(
                            _isSubmitting ? 'Finalizing Profile...' : 'Complete Profile & Launch',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
