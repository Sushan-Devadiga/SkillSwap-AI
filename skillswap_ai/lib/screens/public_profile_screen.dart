import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/buttons.dart';
import '../services/discover_service.dart';
import '../services/connection_service.dart';
import '../widgets/chips.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  Map<String, dynamic>? _profileData;
  String _connectionStatus = 'none';
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(discoverServiceProvider);
      final data = await service.getProfileByUsername(widget.username);
      
      if (data == null) {
        _error = 'User not found.';
      } else {
        _profileData = data;
        // Fetch connection status
        final connService = ref.read(connectionServiceProvider);
        _connectionStatus = await connService.getConnectionStatus(data['id']);
      }
    } catch (e) {
      _error = 'Error loading profile.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profileData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _profileData!;
    final fullName = p['full_name'] as String? ?? 'User';
    final bio = p['bio'] as String? ?? 'No bio provided.';
    final location = p['location'] as String? ?? '';
    final timezone = p['timezone'] as String? ?? '';
    final experienceLevel = p['experience_level'] as String? ?? '';
    final availability = p['availability'] as String? ?? '';
    
    List<String> goals = [];
    if (p['learning_goals'] != null) {
      goals = List<String>.from(p['learning_goals']);
    }

    final userSkills = p['user_skills'] as List? ?? [];
    List<String> teaching = [];
    List<String> learning = [];

    for (var us in userSkills) {
      final type = us['type'];
      final skillName = us['skills']['name'] as String;
      if (type == 'TEACH') {
        teaching.add(skillName);
      } else {
        learning.add(skillName);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('@${widget.username}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.person, size: 50, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (location.isNotEmpty || timezone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  [if (location.isNotEmpty) location, if (timezone.isNotEmpty) timezone].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            if (teaching.isNotEmpty)
              _buildSection(
                context,
                title: 'Teaching',
                subtitle: experienceLevel.isNotEmpty ? experienceLevel : null,
                icon: Icons.school,
                skills: teaching,
              ),
            if (teaching.isNotEmpty) const SizedBox(height: 24),
            
            if (learning.isNotEmpty)
              _buildSection(
                context,
                title: 'Learning',
                icon: Icons.menu_book,
                skills: learning,
                isLearning: true,
              ),
              
            if (goals.isNotEmpty || availability.isNotEmpty) ...[
              const Divider(height: 48),
              if (availability.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.event_available, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Availability', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(availability),
                ),
                const SizedBox(height: 24),
              ],
              
              if (goals.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.flag, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Learning Goals', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                ...goals.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(g)),
                        ],
                      ),
                    )),
              ],
            ],
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, p['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String peerId) {
    if (_isActionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_connectionStatus == 'accepted') {
      return ElevatedButton.icon(
        onPressed: () {
          context.push('/chat/${widget.username}');
        },
        icon: const Icon(Icons.message),
        label: const Text('Send Message'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    if (_connectionStatus == 'pending') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.access_time),
        label: const Text('Request Pending'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        setState(() => _isActionLoading = true);
        final connService = ref.read(connectionServiceProvider);
        final success = await connService.sendRequest(peerId);
        
        if (mounted) {
          setState(() {
            _isActionLoading = false;
            if (success) _connectionStatus = 'pending';
          });
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request.')));
          }
        }
      },
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Request Skill Swap'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, String? subtitle, required IconData icon, required List<String> skills, bool isLearning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: skills.map((s) => SkillChip(label: s, isSelected: isLearning, onTap: () {})).toList(),
        ),
      ],
    );
  }
}
