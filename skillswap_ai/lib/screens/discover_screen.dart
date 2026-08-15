import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/chips.dart';
import '../widgets/cards.dart';
import '../services/discover_service.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
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
      
      final newProfiles = await service.getDiscoverProfiles(
        searchQuery: _searchController.text.trim(),
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
    // Basic debounce could be added here
    _fetchProfiles(isLoadMore: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list), 
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Advanced filters coming soon!')),
              );
            }
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProfiles(isLoadMore: false),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onSubmitted: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search people or skills...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _fetchProfiles(isLoadMore: false);
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.surfaceStroke),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.surfaceStroke),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Explore Community', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            
            if (_profiles.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: AppColors.outline),
                      const SizedBox(height: 16),
                      Text('No users found', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text('Try adjusting your search criteria.'),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _profiles.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final profile = _profiles[index];
                      final username = profile['username'] as String;
                      final fullName = profile['full_name'] as String? ?? 'User';
                      final experience = profile['experience_level'] as String? ?? '';
                      final bio = profile['bio'] as String? ?? '';
                      
                      // Extract top teaching skill for preview
                      String topSkill = 'Various skills';
                      final userSkills = profile['user_skills'] as List? ?? [];
                      for (var us in userSkills) {
                        if (us['type'] == 'TEACH') {
                          topSkill = us['skills']['name'] as String;
                          break;
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: StandardCard(
                          padding: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () {
                              context.push('/profile/$username');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.primaryContainer,
                                    radius: 28,
                                    child: Icon(Icons.person, color: AppColors.onPrimaryContainer),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fullName, style: Theme.of(context).textTheme.titleMedium),
                                        Text('@$username', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.school, size: 14, color: AppColors.outline),
                                            const SizedBox(width: 4),
                                            Text(topSkill, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                                            if (experience.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceContainerHigh,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(experience, style: const TextStyle(fontSize: 10)),
                                              ),
                                            ]
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          bio,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.outline),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _profiles.length + (_hasMore && _profiles.isNotEmpty ? 1 : 0),
                  ),
                ),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
