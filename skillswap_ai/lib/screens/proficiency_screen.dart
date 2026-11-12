import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';

class ProficiencyLevelData {
  final String level;
  final String tag;
  final String description;
  final IconData icon;

  const ProficiencyLevelData({
    required this.level,
    required this.tag,
    required this.description,
    required this.icon,
  });
}

class ProficiencyScreen extends ConsumerStatefulWidget {
  const ProficiencyScreen({super.key});

  @override
  ConsumerState<ProficiencyScreen> createState() => _ProficiencyScreenState();
}

class _ProficiencyScreenState extends ConsumerState<ProficiencyScreen> {
  final List<ProficiencyLevelData> _levels = const [
    ProficiencyLevelData(
      level: 'Beginner',
      tag: '0 - 1 yrs practical experience',
      description: 'You understand foundational concepts and syntax. Great for guiding newer peers and reinforcing core fundamentals.',
      icon: LucideIcons.sprout,
    ),
    ProficiencyLevelData(
      level: 'Intermediate',
      tag: '1 - 3 yrs practical experience',
      description: 'Comfortable writing code or designing independently, solving bugs, and building real-world projects.',
      icon: LucideIcons.compass,
    ),
    ProficiencyLevelData(
      level: 'Advanced',
      tag: '3 - 5+ yrs practical experience',
      description: 'Deep domain fluency, architectural knowledge, optimization techniques, and best practice code reviews.',
      icon: LucideIcons.award,
    ),
    ProficiencyLevelData(
      level: 'Expert',
      tag: '5+ yrs & lead mentorship',
      description: 'Industry authority or seasoned specialist. Capable of end-to-end guidance, systems design, and advanced critique.',
      icon: LucideIcons.crown,
    ),
  ];

  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.experienceLevel.isNotEmpty) {
      _selectedLevel = profile.experienceLevel;
    } else {
      _selectedLevel = 'Intermediate'; // Default helpful selection
    }
  }

  void _handleContinue() {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an experience level to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
    ref.read(userProfileProvider.notifier).updateLocalState(
          currentProfile.copyWith(experienceLevel: _selectedLevel),
        );
    context.push('/learning-skills');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryEmerald = Color(0xFF059669);

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
          'Experience Level',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 3 / 7, // Step 3 of 7
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
                                'STEP 3 OF 7',
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
                              'Teaching Depth',
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // HEADLINE & SUBTITLE
                        Text(
                          'How experienced are you?',
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your general proficiency level for the skills you plan to teach. The AI uses this for skill-level pairing.',
                          style: AppTypography.bodyMd.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // PROFICIENCY CARDS
                        ..._levels.map((item) {
                          final isSelected = _selectedLevel == item.level;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedLevel = item.level;
                                  });
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                            ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                            : const Color(0xFFECFDF5))
                                        : bgCard,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected ? primaryEmerald : strokeColor,
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? primaryEmerald.withValues(alpha: 0.14)
                                            : Colors.black.withValues(alpha: 0.03),
                                        blurRadius: isSelected ? 12 : 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon container
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryEmerald.withValues(alpha: 0.18)
                                              : (isDark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: isSelected ? primaryEmerald : textSecondary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Text information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  item.level,
                                                  style: AppTypography.headlineMd.copyWith(
                                                    color: textPrimary,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? primaryEmerald.withValues(alpha: 0.15)
                                                        : (isDark
                                                            ? const Color(0xFF334155)
                                                            : const Color(0xFFF1F5F9)),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    item.tag,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? primaryEmerald : textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item.description,
                                              style: AppTypography.bodySm.copyWith(
                                                color: textSecondary,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Selection radio indicator
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? primaryEmerald : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected ? primaryEmerald : strokeColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                LucideIcons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // STICKY BOTTOM BUTTON
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
                          onPressed: _handleContinue,
                          icon: const Icon(LucideIcons.arrowRight, size: 18),
                          label: Text(
                            _selectedLevel != null
                                ? 'Continue (${_selectedLevel!})'
                                : 'Select Experience Level',
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
