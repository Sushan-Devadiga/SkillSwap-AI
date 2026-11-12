import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../constants/skills_list.dart';

class TeachingSkillsScreen extends ConsumerStatefulWidget {
  const TeachingSkillsScreen({super.key});

  @override
  ConsumerState<TeachingSkillsScreen> createState() => _TeachingSkillsScreenState();
}

class _TeachingSkillsScreenState extends ConsumerState<TeachingSkillsScreen> {
  late final Set<String> _selectedSkills;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedSkills = ref.read(userProfileProvider).value?.teachingSkills.toSet() ?? {};

    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
          if (_searchQuery.isNotEmpty) {
            _showSuggestions = true;
          }
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<String> get _matchingSkills {
    if (_searchQuery.isEmpty) {
      // Prioritize unselected popular skills when query is empty
      final unselected = popularSkills.where((s) => !_selectedSkills.contains(s)).toList();
      return unselected.take(12).toList();
    }
    final q = _searchQuery.toLowerCase();
    return popularSkills.where((s) => s.toLowerCase().contains(q)).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Development':
        return LucideIcons.code2;
      case 'Design':
        return LucideIcons.palette;
      case 'Business':
        return LucideIcons.trendingUp;
      case 'Languages':
        return LucideIcons.globe;
      default:
        return LucideIcons.sparkles;
    }
  }

  void _addSkill(String skill) {
    final clean = skill.trim();
    if (clean.isEmpty) return;
    setState(() {
      _selectedSkills.add(clean);
      _showSuggestions = true; // Keep suggestions open so user can keep adding
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryEmerald = const Color(0xFF059669);

    final matching = _matchingSkills;
    final hasExactMatch = matching.any((s) => s.toLowerCase() == _searchQuery.toLowerCase());

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
          'Teaching Skills',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 2 / 7, // Step 2 of 7
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(primaryEmerald),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // 1. STEP BADGE & HEADLINE
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STEP 2 OF 7',
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
                  'Expertise Profile',
                  style: AppTypography.bodySm.copyWith(color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'What can you teach?',
              style: AppTypography.headlineLg.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type to search all skills or choose from suggestions below.',
              style: AppTypography.bodyMd.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 24),

            // 2. SEARCH BAR
            Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showSuggestions ? primaryEmerald : strokeColor,
                  width: _showSuggestions ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _showSuggestions
                        ? primaryEmerald.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: textPrimary, fontSize: 15),
                onTap: () {
                  setState(() => _showSuggestions = true);
                },
                decoration: InputDecoration(
                  hintText: 'Search skills (e.g. Python, Figma, Spanish)...',
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8), fontSize: 14),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: _showSuggestions ? primaryEmerald : textSecondary,
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(LucideIcons.x, color: textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      if (_showSuggestions)
                        IconButton(
                          icon: Icon(LucideIcons.chevronUp, color: primaryEmerald, size: 20),
                          tooltip: 'Close suggestions',
                          onPressed: () {
                            setState(() {
                              _showSuggestions = false;
                              _searchFocusNode.unfocus();
                            });
                          },
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addSkill(value);
                  }
                },
              ),
            ),

            // 3. POPUP SUGGESTIONS OVERLAY (DIRECTLY INTERACTIVE)
            if (_showSuggestions) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryEmerald.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with count & Close button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryEmerald.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.sparkles, size: 14, color: primaryEmerald),
                                const SizedBox(width: 6),
                                Text(
                                  _searchQuery.isEmpty ? 'Suggested Skills (${matching.length})' : 'Matching Skills (${matching.length})',
                                  style: TextStyle(color: primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showSuggestions = false;
                                  _searchFocusNode.unfocus();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Text('Done', style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.check, size: 13, color: textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: strokeColor),

                      // Scrollable Items List
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView(
                          shrinkWrap: true,
                          primary: false,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                          // Custom skill option if query doesn't match an exact catalog entry
                          if (_searchQuery.isNotEmpty && !hasExactMatch) ...[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _addSkill(_searchQuery),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: primaryEmerald.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(LucideIcons.plus, size: 16, color: primaryEmerald),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(color: textPrimary, fontSize: 14),
                                            children: [
                                              const TextSpan(text: 'Add custom skill: "'),
                                              TextSpan(
                                                text: _searchQuery,
                                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryEmerald),
                                              ),
                                              const TextSpan(text: '"'),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryEmerald,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Divider(height: 1, color: strokeColor),
                          ],

                          // Matching catalog suggestions
                          if (matching.isEmpty && _searchQuery.isNotEmpty && hasExactMatch)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Skill already in your list.',
                                style: AppTypography.bodySm.copyWith(color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (matching.isEmpty && _searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No matching skills found in catalog. Tap above to add.',
                                style: AppTypography.bodySm.copyWith(color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...matching.map((skill) {
                              final category = getSkillCategory(skill);
                              final categoryColor = getSkillCategoryColor(category);
                              final icon = _getCategoryIcon(category);
                              final isSelected = _selectedSkills.contains(skill);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (isSelected) {
                                      _removeSkill(skill);
                                    } else {
                                      _addSkill(skill);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(icon, size: 15, color: categoryColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                skill,
                                                style: TextStyle(
                                                  color: isSelected ? primaryEmerald : textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                category,
                                                style: TextStyle(color: textSecondary, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (isSelected) {
                                              _removeSkill(skill);
                                            } else {
                                              _addSkill(skill);
                                            }
                                          },
                                          child: isSelected
                                              ? Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: primaryEmerald.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: primaryEmerald.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(LucideIcons.check, size: 12, color: primaryEmerald),
                                                      const SizedBox(width: 4),
                                                      Text('Added', style: TextStyle(color: primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: strokeColor),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(LucideIcons.plus, size: 12, color: textPrimary),
                                                      const SizedBox(width: 4),
                                                      Text('Add', style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 4. SELECTED SKILLS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryEmerald.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.checkCircle2, size: 14, color: primaryEmerald),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Skills (${_selectedSkills.length})',
                      style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 16),
                    ),
                  ],
                ),
                if (_selectedSkills.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedSkills.clear());
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_selectedSkills.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: strokeColor),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.sparkles, size: 28, color: textSecondary.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Text(
                      'No teaching skills selected yet',
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search above or pick from trending skills below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSkills.map((skill) {
                  final category = getSkillCategory(skill);
                  final color = getSkillCategoryColor(category);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryEmerald.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          skill,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeSkill(skill),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: textSecondary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.x, size: 12, color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),

            // 5. CLEAN POPULAR PICKS
            Row(
              children: [
                Icon(LucideIcons.flame, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text(
                  'Popular Skills',
                  style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 15),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick add',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trendingSkills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                final category = getSkillCategory(skill);
                final categoryColor = getSkillCategoryColor(category);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        _removeSkill(skill);
                      } else {
                        _addSkill(skill);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryEmerald.withValues(alpha: 0.12)
                            : bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primaryEmerald
                              : strokeColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(LucideIcons.check, size: 13, color: primaryEmerald),
                            const SizedBox(width: 6),
                          ] else ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: categoryColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            skill,
                            style: TextStyle(
                              color: isSelected ? primaryEmerald : textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),

                // 6. BOTTOM STICKY CONTINUE BUTTON
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgCard,
                    border: Border(top: BorderSide(color: strokeColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedSkills.isEmpty
                              ? null
                              : () {
                                  final currentProfile = ref.read(userProfileProvider).value ?? UserProfile();
                                  ref.read(userProfileProvider.notifier).updateLocalState(
                                    currentProfile.copyWith(teachingSkills: _selectedSkills.toList()),
                                  );
                                  context.push('/proficiency');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryEmerald,
                            disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedSkills.isEmpty
                                    ? 'Select at least 1 skill to continue'
                                    : 'Continue (${_selectedSkills.length} selected)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.arrowRight, size: 18),
                            ],
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
