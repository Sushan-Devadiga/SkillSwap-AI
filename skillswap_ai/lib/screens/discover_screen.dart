import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/shadcn_ui.dart';
import '../services/discover_service.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _profiles = [];
  String _selectedCategory = 'All';
  String _selectedSkillLevel = 'All';

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'All', 'name': 'All', 'icon': LucideIcons.layers},
    {'id': 'Development', 'name': 'Development', 'icon': LucideIcons.code},
    {'id': 'Design', 'name': 'Design', 'icon': LucideIcons.palette},
    {'id': 'Languages', 'name': 'Languages', 'icon': LucideIcons.languages},
    {'id': 'Business', 'name': 'Business', 'icon': LucideIcons.briefcase},
    {'id': 'Music', 'name': 'Music', 'icon': LucideIcons.music},
  ];

  final List<Map<String, dynamic>> _skillLevels = const [
    {'id': 'All', 'name': 'All Levels', 'icon': LucideIcons.sparkles, 'tag': 'Any proficiency'},
    {'id': 'Beginner', 'name': 'Beginner', 'icon': LucideIcons.sprout, 'tag': 'Foundations'},
    {'id': 'Intermediate', 'name': 'Intermediate', 'icon': LucideIcons.zap, 'tag': 'Practicing'},
    {'id': 'Advanced', 'name': 'Advanced', 'icon': LucideIcons.rocket, 'tag': 'Proficient'},
    {'id': 'Expert', 'name': 'Expert', 'icon': LucideIcons.award, 'tag': 'Mentors'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = ref.read(discoverCategoryProvider);
    _selectedSkillLevel = ref.read(discoverSkillLevelProvider);
    _fetchProfiles();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _fetchProfiles(isLoadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles({bool isLoadMore = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(discoverServiceProvider);
      final offset = isLoadMore ? _profiles.length : 0;
      final category = _selectedCategory == 'All' ? null : _selectedCategory;
      final skillLevel = (_selectedSkillLevel == 'All' || _selectedSkillLevel == 'All Levels') ? null : _selectedSkillLevel;
      
      final newProfiles = await service.getDiscoverProfiles(
        searchQuery: _searchController.text.trim(),
        category: category,
        skillLevel: skillLevel,
        limit: _limit,
        offset: offset,
      );

      setState(() {
        if (isLoadMore) {
          _profiles.addAll(newProfiles);
        } else {
          _profiles = newProfiles;
        }
        
        _hasMore = newProfiles.length == _limit;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {}); // Updates clear icon visibility
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(discoverSearchQueryProvider.notifier).setSearchQuery(query);
      setState(() {
        _profiles = [];
        _hasMore = true;
      });
      _fetchProfiles(isLoadMore: false);
    });
  }

  void _showFilterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;
    final chipBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    String tempCategory = _selectedCategory;
    String tempSkillLevel = _selectedSkillLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final int activeCount = (tempCategory != 'All' ? 1 : 0) +
                (tempSkillLevel != 'All' && tempSkillLevel != 'All Levels' ? 1 : 0);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: strokeColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.slidersHorizontal, size: 18, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Filters',
                            style: AppTypography.headlineMd.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$activeCount active',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (activeCount > 0)
                            TextButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  tempCategory = 'All';
                                  tempSkillLevel = 'All';
                                });
                              },
                              icon: const Icon(LucideIcons.rotateCcw, size: 13),
                              label: const Text('Reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: subtextColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(LucideIcons.x, size: 20, color: subtextColor),
                            onPressed: () => Navigator.pop(sheetContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: strokeColor, height: 1),
                      const SizedBox(height: 18),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Category Section
                              Row(
                                children: [
                                  const Icon(LucideIcons.layoutGrid, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Category',
                                    style: AppTypography.labelMd.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((cat) {
                                  final catId = cat['id'] as String;
                                  final catName = cat['name'] as String;
                                  final catIcon = cat['icon'] as IconData;
                                  final isCatSelected = catId == tempCategory;

                                  return InkWell(
                                    onTap: () {
                                      setSheetState(() {
                                        tempCategory = catId;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isCatSelected
                                            ? const Color(0xFF059669)
                                            : chipBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isCatSelected
                                              ? const Color(0xFF059669)
                                              : strokeColor,
                                          width: isCatSelected ? 1.5 : 1.0,
                                        ),
                                        boxShadow: isCatSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF059669).withOpacity(0.28),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            catIcon,
                                            size: 15,
                                            color: isCatSelected ? Colors.white : subtextColor,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            catName,
                                            style: TextStyle(
                                              color: isCatSelected ? Colors.white : textColor,
                                              fontSize: 13,
                                              fontWeight: isCatSelected ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                          if (isCatSelected) ...[
                                            const SizedBox(width: 6),
                                            const Icon(LucideIcons.check, size: 13, color: Colors.white),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 24),

                              // 2. Skill Level Section
                              Row(
                                children: [
                                  const Icon(LucideIcons.award, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Experience & Skill Level',
                                    style: AppTypography.labelMd.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _skillLevels.map((lvl) {
                                  final lvlId = lvl['id'] as String;
                                  final lvlName = lvl['name'] as String;
                                  final lvlIcon = lvl['icon'] as IconData;
                                  final lvlTag = lvl['tag'] as String;
                                  final isLvlSelected = lvlId == tempSkillLevel;

                                  return InkWell(
                                    onTap: () {
                                      setSheetState(() {
                                        tempSkillLevel = lvlId;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isLvlSelected
                                            ? const Color(0xFF059669).withOpacity(0.12)
                                            : chipBg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isLvlSelected
                                              ? const Color(0xFF059669)
                                              : strokeColor,
                                          width: isLvlSelected ? 1.8 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: isLvlSelected
                                                  ? const Color(0xFF059669)
                                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              lvlIcon,
                                              size: 13,
                                              color: isLvlSelected ? Colors.white : subtextColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                lvlName,
                                                style: TextStyle(
                                                  color: isLvlSelected ? const Color(0xFF059669) : textColor,
                                                  fontSize: 13,
                                                  fontWeight: isLvlSelected ? FontWeight.w700 : FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                lvlTag,
                                                style: TextStyle(
                                                  color: subtextColor,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isLvlSelected) ...[
                                            const SizedBox(width: 8),
                                            const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF059669)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(color: strokeColor, height: 1),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: strokeColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Cancel', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF059669), Color(0xFF0D9488)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF059669).withOpacity(0.32),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  ref.read(discoverCategoryProvider.notifier).setCategory(tempCategory);
                                  ref.read(discoverSkillLevelProvider.notifier).setSkillLevel(tempSkillLevel);
                                  setState(() {
                                    _selectedCategory = tempCategory;
                                    _selectedSkillLevel = tempSkillLevel;
                                    _profiles = [];
                                    _hasMore = true;
                                  });
                                  _fetchProfiles(isLoadMore: false);
                                },
                                icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                                label: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = _selectedCategory != 'All' || (_selectedSkillLevel != 'All' && _selectedSkillLevel != 'All Levels');

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surfaceBg.withOpacity(0.9),
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text('Discover', style: AppTypography.headlineLg),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(132),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onSubmitted: (query) {
                              _debounceTimer?.cancel();
                              ref.read(discoverSearchQueryProvider.notifier).setSearchQuery(query);
                              setState(() {
                                _profiles = [];
                                _hasMore = true;
                              });
                              _fetchProfiles(isLoadMore: false);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search skills or people...',
                              prefixIcon: const Icon(LucideIcons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  _debounceTimer?.cancel();
                                  _searchController.clear();
                                  ref.read(discoverSearchQueryProvider.notifier).setSearchQuery('');
                                  setState(() {
                                    _profiles = [];
                                    _hasMore = true;
                                  });
                                  _fetchProfiles(isLoadMore: false);
                                },
                              ) : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasActiveFilters ? const Color(0xFF059669) : AppColors.surfaceStroke,
                              width: hasActiveFilters ? 1.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(
                                  LucideIcons.slidersHorizontal,
                                  color: hasActiveFilters ? const Color(0xFF059669) : AppColors.onSurface,
                                ),
                                onPressed: _showFilterSheet,
                                tooltip: 'Filter Profiles',
                              ),
                              if (hasActiveFilters)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length + (_selectedSkillLevel != 'All' && _selectedSkillLevel != 'All Levels' ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          // Show removable level pill first if active
                          if (_selectedSkillLevel != 'All' && _selectedSkillLevel != 'All Levels' && index == 0) {
                            return InkWell(
                              onTap: () {
                                ref.read(discoverSkillLevelProvider.notifier).setSkillLevel('All');
                                setState(() {
                                  _selectedSkillLevel = 'All';
                                  _profiles = [];
                                  _hasMore = true;
                                });
                                _fetchProfiles(isLoadMore: false);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF059669)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.award, size: 14, color: Color(0xFF059669)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Level: $_selectedSkillLevel',
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(LucideIcons.x, size: 13, color: Color(0xFF059669)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final categoryIndex = (_selectedSkillLevel != 'All' && _selectedSkillLevel != 'All Levels') ? index - 1 : index;
                          final cat = _categories[categoryIndex];
                          final categoryId = cat['id'] as String;
                          final categoryName = cat['name'] as String;
                          final categoryIcon = cat['icon'] as IconData;
                          final isSelected = categoryId == _selectedCategory;

                          return GestureDetector(
                            onTap: () {
                              if (_selectedCategory == categoryId) return;
                              ref.read(discoverCategoryProvider.notifier).setCategory(categoryId);
                              setState(() {
                                _selectedCategory = categoryId;
                                _profiles = [];
                                _hasMore = true;
                              });
                              _fetchProfiles(isLoadMore: false);
                            },
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF059669)
                                    : (isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : (isDark ? const Color(0xFF334155) : AppColors.surfaceStroke),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF059669).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    categoryName,
                                    style: AppTypography.labelSm.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white : AppColors.onSurfaceVariant),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isLoading && _profiles.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Skeleton(height: 160, borderRadius: 16),
                  ),
                  childCount: 5,
                ),
              ),
            )
          else if (_profiles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    title: 'No matches found',
                    description: 'No profiles match your active filters. Try adjusting or resetting them.',
                    icon: LucideIcons.searchX,
                    buttonText: hasActiveFilters ? 'Clear All Filters' : null,
                    onButtonTap: hasActiveFilters
                        ? () {
                            ref.read(discoverCategoryProvider.notifier).setCategory('All');
                            ref.read(discoverSkillLevelProvider.notifier).setSkillLevel('All');
                            _searchController.clear();
                            ref.read(discoverSearchQueryProvider.notifier).setSearchQuery('');
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedSkillLevel = 'All';
                              _profiles = [];
                              _hasMore = true;
                            });
                            _fetchProfiles(isLoadMore: false);
                          }
                        : null,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _profiles.length) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final profile = _profiles[index];
                    final username = profile['username'] as String;
                    final fullName = profile['full_name'] as String? ?? 'User';
                    final bio = profile['bio'] as String? ?? 'Lifelong learner.';
                    
                    final teachingSkills = <String>[];
                    final learningSkills = <String>[];
                    
                    final userSkills = profile['user_skills'] as List? ?? [];
                    for (var us in userSkills) {
                      final skillMap = us['skills'];
                      if (skillMap is Map && skillMap['name'] != null) {
                        final sName = skillMap['name'] as String;
                        if (us['type'] == 'TEACH') {
                          if (!teachingSkills.contains(sName)) teachingSkills.add(sName);
                        } else if (us['type'] == 'LEARN') {
                          if (!learningSkills.contains(sName)) learningSkills.add(sName);
                        }
                      }
                    }

                    final hasAvatar = profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceStroke),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => context.push('/profile/${profile['id']}'),
                                  borderRadius: BorderRadius.circular(28),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.primaryContainer,
                                    backgroundImage: hasAvatar ? NetworkImage(profile['avatar_url']) : null,
                                    child: !hasAvatar
                                        ? Text(
                                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => context.push('/profile/${profile['id']}'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fullName, style: AppTypography.headlineMd),
                                        Text('@$username', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      (profile['experience_level'] != null && profile['experience_level'].toString().isNotEmpty)
                                          ? profile['experience_level']
                                          : 'Learner',
                                      style: AppTypography.labelSm.copyWith(color: AppColors.primaryContainer),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (teachingSkills.isEmpty && learningSkills.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Open to exchange', style: AppTypography.labelSm.copyWith(fontSize: 10)),
                                  ),
                                ...teachingSkills.map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.bookOpen, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text('Teaches $s', style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                                ...learningSkills.map(
                                  (s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.sparkles, size: 12, color: AppColors.secondary),
                                        const SizedBox(width: 4),
                                        Text('Learns $s', style: AppTypography.labelSm.copyWith(color: AppColors.secondary, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.push('/profile/${profile['id']}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.onSurface,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('View Profile'),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
                    );
                  },
                  childCount: _profiles.length + (_hasMore && _profiles.isNotEmpty ? 1 : 0),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
