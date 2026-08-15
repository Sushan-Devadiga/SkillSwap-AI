import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../widgets/cards.dart';
import '../services/auth_service.dart';
import '../widgets/buttons.dart';
import '../services/discover_service.dart';
import '../services/stats_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../providers/profile_provider.dart';

final userStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(statsServiceProvider).getUserStats();
});

final upcomingSessionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(sessionServiceProvider).getUpcomingSessions();
});

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
      backgroundColor: const Color(0xFFF4F7FB), // Very light blue/gray background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sync_alt, color: AppColors.primaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'SkillSwap AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                  child: const Icon(Icons.notifications_outlined, color: AppColors.onSurface),
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tooltip: 'Profile Menu',
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    final currentUsername = ref.read(userProfileProvider).value?.username;
                    if (currentUsername != null && currentUsername.isNotEmpty) {
                      context.push('/profile/$currentUsername');
                    } else {
                      context.push('/profile-setup');
                    }
                    break;
                  case 'notifications':
                    context.push('/notifications');
                    break;
                  case 'settings':
                    // Handle settings tap
                    break;
                  case 'logout':
                    ref.read(authServiceProvider).signOut();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_outlined, size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: userProfile?.avatarUrl != null && userProfile!.avatarUrl.isNotEmpty
                    ? NetworkImage(userProfile.avatarUrl)
                    : null,
                child: userProfile?.avatarUrl == null || userProfile!.avatarUrl.isEmpty
                    ? Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 14, color: AppColors.onPrimaryContainer),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              '${_getGreeting()}, $firstName 👋',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ready to learn something new or share what you know?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            
            // Hero Card
            StandardCard(
              padding: EdgeInsets.zero, // Padding handled inside
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -40,
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(Icons.people_alt, size: 240, color: AppColors.primary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Learn from people.\nShare what you know.',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurface,
                                        height: 1.2,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Exchange skills with people who have something valuable to teach — and something you can teach them.',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Find a Skill Match', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary, width: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Share a Skill', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (MediaQuery.of(context).size.width > 700) ...[
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F766E), Color(0xFF4F46E5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    )
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 0.2,
                                      child: CustomPaint(
                                        painter: _GridPainter(),
                                        size: const Size(double.infinity, double.infinity),
                                      ),
                                    ),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(radius: 32, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 36, color: Colors.white)),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                                          child: Icon(Icons.sync_alt, color: Colors.white, size: 36),
                                        ),
                                        CircleAvatar(radius: 32, backgroundColor: Colors.white24, child: Icon(Icons.person_2, size: 36, color: Colors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // AI Match of the Day
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.aiGlow.createShader(bounds),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  '✨ Your AI Match Today',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer(
              builder: (context, ref, child) {
                final matchesAsyncValue = ref.watch(matchesProvider);
                
                return matchesAsyncValue.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
                  error: (err, stack) => StandardCard(child: Text('Error loading matches: $err')),
                  data: (matches) {
                    if (matches.isEmpty) {
                      return StandardCard(
                        padding: const EdgeInsets.all(32), 
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                'No strong matches yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(height: 1.5, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () { context.push('/profile-setup'); }, 
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                    child: const Text('Add Skills')
                                  ),
                                  OutlinedButton(
                                    onPressed: () { context.push('/discover'); }, 
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                                    child: const Text('Discover People')
                                  ),
                                ]
                              )
                            ]
                          )
                        )
                      );
                    }
                    
                    final match = matches.first;
                    final similarityPercent = (match.similarity * 100).toStringAsFixed(0);
                    
                    return AiSuggestedCard(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: match.avatarUrl != null ? NetworkImage(match.avatarUrl!) : null,
                                child: match.avatarUrl == null ? const Icon(Icons.person) : null,
                                radius: 32,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.fullName,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                value: match.similarity,
                                                strokeWidth: 3,
                                                backgroundColor: AppColors.surfaceStroke,
                                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                                              ),
                                            ),
                                            Text(
                                              '$similarityPercent',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryContainer),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '% Compatibility',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (MediaQuery.of(context).size.width > 500)
                                _buildViewMatchButton(context, match, similarityPercent),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceStroke),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('You teach', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      Text(userTeachingSkill, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                    ]
                                  ),
                                  child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 24),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${match.fullName} teaches', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 6),
                                      Text(match.skillName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(left: BorderSide(color: AppColors.primaryContainer, width: 4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => AppColors.aiGlow.createShader(bounds),
                                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        match.explanation,
                                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic, fontSize: 14, height: 1.4),
                                      ),
                                      if (match.suggestions.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tip: ${match.suggestions}',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (MediaQuery.of(context).size.width <= 500) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: _buildViewMatchButton(context, match, similarityPercent),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                );
              }
            ),
            
            const SizedBox(height: 48),
            
            // Your Learning Journey
            Text(
              'Your Learning Journey',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.8,
                  children: [
                    _buildStatCard(Icons.school_outlined, 'Skills Learned', '${stats['skillsLearned']}', context),
                    _buildStatCard(Icons.workspace_premium_outlined, 'Skills Shared', '${stats['skillsShared']}', context),
                    _buildStatCard(Icons.handshake_outlined, 'Exchanges Completed', '${stats['exchangesCompleted']}', context),
                    _buildStatCard(Icons.people_outline, 'Connections', '${stats['connections']}', context),
                  ],
                );
              }
            ),

            const SizedBox(height: 48),
            
            // Upcoming Session
            Text(
              'Upcoming Session',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            if (sessions.isEmpty)
              StandardCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today, size: 48, color: AppColors.outline),
                      const SizedBox(height: 16),
                      Text('No upcoming sessions', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text('Schedule a session with a match to start learning.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final session = sessions.first;
                  final title = session['title'] ?? 'Skill Swap Session';
                  final scheduledTime = DateTime.parse(session['scheduled_time']);
                  final duration = session['duration_minutes'] ?? 45;
                  
                  String timeStr = '${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}';
                  String dateStr = '${scheduledTime.month}/${scheduledTime.day}';
                  if (scheduledTime.day == DateTime.now().day) {
                    dateStr = 'Today';
                  } else if (scheduledTime.day == DateTime.now().day + 1) {
                    dateStr = 'Tomorrow';
                  }

                  return Column(
                    children: [
                      StandardCard(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Text('$dateStr · $timeStr', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.schedule, size: 16, color: AppColors.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Text('$duration min · Online', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (MediaQuery.of(context).size.width > 500)
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text('Join Session', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                      if (MediaQuery.of(context).size.width <= 500) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Join Session', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  );
                }
              ),

            const SizedBox(height: 48),

            // Quick Actions
            Text(
              'What would you like to do?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                return Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    Expanded(
                      flex: isMobile ? 0 : 1,
                      child: _buildActionCard(
                        icon: Icons.search,
                        title: 'Find a Match',
                        description: 'Discover people who complement your skills',
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                    Expanded(
                      flex: isMobile ? 0 : 1,
                      child: _buildActionCard(
                        icon: Icons.add_circle_outline,
                        title: 'Add a Skill',
                        description: 'Tell the community what you can teach',
                        onTap: () {
                          context.push('/profile-setup');
                        },
                      ),
                    ),
                    SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                    Expanded(
                      flex: isMobile ? 0 : 1,
                      child: _buildActionCard(
                        icon: Icons.calendar_month,
                        title: 'Schedule a Session',
                        description: 'Plan your next knowledge exchange',
                        onTap: () {},
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMatchButton(BuildContext context, dynamic match, String similarityPercent) {
    return ElevatedButton(
      onPressed: () {
        if (match.username != null && match.username.toString().isNotEmpty) {
          context.push('/profile/${match.username}');
        } else {
          context.push(
            Uri(
              path: '/match',
              queryParameters: {
                'id': match.userId,
                'name': match.fullName,
                'skill': match.skillName,
                'similarity': similarityPercent,
                if (match.avatarUrl != null) 'avatar': match.avatarUrl,
              },
            ).toString()
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onSurface,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('View Match', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, BuildContext context) {
    return StandardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryContainer, size: 24),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;
    
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
