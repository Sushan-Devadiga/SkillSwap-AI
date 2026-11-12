import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';

class LearningGoalsScreen extends ConsumerStatefulWidget {
  const LearningGoalsScreen({super.key});

  @override
  ConsumerState<LearningGoalsScreen> createState() => _LearningGoalsScreenState();
}

class _LearningGoalsScreenState extends ConsumerState<LearningGoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _goals = [];

  final List<String> _suggestedGoals = const [
    'Build a full-stack portfolio project',
    'Master asynchronous Python & APIs',
    'Design responsive Flutter mobile UI',
    'Ace system design interview questions',
    'Build a design system in Figma',
    'Deploy scalable apps to Docker & AWS',
    'Practice conversational Spanish fluency',
  ];

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
    _focusNode.dispose();
    super.dispose();
  }

  void _addGoal([String? customGoal]) {
    final text = (customGoal ?? _goalController.text).trim();
    if (text.isEmpty) return;

    if (_goals.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This goal is already added.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _goals.add(text);
      if (customGoal == null) {
        _goalController.clear();
      }
    });
  }

  void _removeGoal(String goal) {
    setState(() {
      _goals.remove(goal);
    });
  }

  void _handleContinue() {
    final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
    ref.read(userProfileProvider.notifier).updateLocalState(
          currentProfile.copyWith(learningGoals: _goals),
        );
    context.push('/availability');
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
          'Specific Goals',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 5 / 7, // Step 5 of 7
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
                                'STEP 5 OF 7',
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
                              'Targeted Outcomes',
                              style: AppTypography.bodySm.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // HEADLINE & SUBTITLE
                        Text(
                          'What are your specific goals?',
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add specific outcomes you want to achieve. Clear goals help mentors personalize exchange sessions to your needs.',
                          style: AppTypography.bodyMd.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // INPUT CARD
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: strokeColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14.0),
                                child: Icon(LucideIcons.target, color: primaryEmerald, size: 22),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _goalController,
                                  focusNode: _focusNode,
                                  style: TextStyle(color: textPrimary, fontSize: 15),
                                  onSubmitted: (_) => _addGoal(),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Build a production Flutter app...',
                                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8), fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _addGoal(),
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Add Goal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryEmerald,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // QUICK INSPIRATION CHIPS
                        Text(
                          'Need inspiration? Tap to add:',
                          style: AppTypography.bodySm.copyWith(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestedGoals.map((suggestion) {
                            final isAdded = _goals.contains(suggestion);
                            return ActionChip(
                              avatar: Icon(
                                isAdded ? LucideIcons.check : LucideIcons.sparkles,
                                size: 14,
                                color: isAdded ? primaryEmerald : textSecondary,
                              ),
                              label: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAdded ? primaryEmerald : textPrimary,
                                  fontWeight: isAdded ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              backgroundColor: isAdded
                                  ? primaryEmerald.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              side: BorderSide(
                                color: isAdded ? primaryEmerald : strokeColor,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () {
                                if (isAdded) {
                                  _removeGoal(suggestion);
                                } else {
                                  _addGoal(suggestion);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // GOALS HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Milestones (${_goals.length})',
                              style: AppTypography.headlineMd.copyWith(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_goals.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _goals.clear();
                                  });
                                },
                                child: Text(
                                  'Clear all',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // GOALS LIST OR EMPTY STATE
                        if (_goals.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: strokeColor),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: primaryEmerald.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.flag, color: primaryEmerald, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No specific goals added yet',
                                  style: AppTypography.headlineMd.copyWith(
                                    color: textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Type your custom milestone above or tap any of the suggested chips.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySm.copyWith(color: textSecondary),
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(_goals.length, (index) {
                            final goal = _goals[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: bgCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: strokeColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: primaryEmerald.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: primaryEmerald,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        goal,
                                        style: AppTypography.bodyMd.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 18),
                                      color: textSecondary,
                                      hoverColor: AppColors.error.withValues(alpha: 0.1),
                                      onPressed: () => _removeGoal(goal),
                                      tooltip: 'Remove goal',
                                    ),
                                  ],
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
                            _goals.isNotEmpty
                                ? 'Continue (${_goals.length} Goals)'
                                : 'Continue (Skip for now)',
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
