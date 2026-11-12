import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/discover_service.dart';
import '../services/connection_service.dart';
import '../services/stats_service.dart';
import '../services/credential_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _credentials = [];
  String _connectionStatus = 'none';
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final discoverService = ref.read(discoverServiceProvider);
      final statsService = ref.read(statsServiceProvider);
      final credentialService = ref.read(credentialServiceProvider);
      final connService = ref.read(connectionServiceProvider);

      // 1. Fetch profile details (supports UUID or username)
      final data = await discoverService.getProfile(widget.userId);

      if (data == null) {
        setState(() {
          _error = 'User profile could not be found.';
          _isLoading = false;
        });
        return;
      }

      final peerId = data['id'] as String;

      // 2. Fetch stats, credentials, and connection status in parallel
      final results = await Future.wait([
        statsService.getUserProfileStats(peerId),
        credentialService.getUserCredentials(peerId),
        connService.getConnectionStatus(peerId),
      ]);

      if (mounted) {
        setState(() {
          _profileData = data;
          _stats = results[0] as Map<String, dynamic>;
          _credentials = results[1] as List<Map<String, dynamic>>;
          _connectionStatus = results[2] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Profile Fetch Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCertificateViewerDialog(BuildContext context, Map<String, dynamic> cred, bool isDark) {
    final skill = cred['skill_name'] ?? 'Skill';
    final tier = cred['badge_tier'] ?? 'Verified Novice';
    final hours = cred['hours_completed'] ?? 1.0;
    final hash = cred['verification_hash'] ?? '0x0000000000000000';
    final mentor = cred['mentor'] as Map<String, dynamic>?;
    final mentorName = mentor?['full_name'] ?? cred['metadata']?['mentor_name'] ?? 'Peer Mentor';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'SKILLSWAP VERIFIED CREDENTIAL',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skill,
              style: AppTypography.headlineLg.copyWith(
                color: isDark ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$tier • $hours hrs verified',
                style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Peer-Verified by $mentorName on the SkillSwap Proof-of-Skill Ledger.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.surfaceStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.link, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text('Cryptographic SHA-256 Proof', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    hash,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'SkillSwap Verified Credential: $skill ($tier) - Verification Hash: $hash'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification proof copied to clipboard!')),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 14),
                    label: const Text('Copy Proof', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.read(authServiceProvider).currentUser?.id;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading full profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _profileData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load profile',
                  style: AppTypography.headlineMd,
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'User not found.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchProfile,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profileData!;
    final peerId = p['id'] as String? ?? '';
    final isSelf = currentUserId != null && currentUserId == peerId;
    final username = p['username'] as String? ?? 'user';
    final fullName = p['full_name'] as String? ?? 'SkillSwapper';
    final avatarUrl = p['avatar_url'] as String?;
    final bio = (p['bio'] as String?)?.trim() ?? 'Passionate lifelong learner on SkillSwap.';
    final location = p['location'] as String? ?? '';
    final timezone = p['timezone'] as String? ?? '';
    final experienceLevel = p['experience_level'] as String? ?? 'Intermediate';
    final learningStyle = p['learning_style'] as String? ?? 'Visual';
    final availability = p['availability'] as String? ?? 'Flexible schedule';

    // Parse learning goals
    List<String> goals = [];
    if (p['learning_goals'] != null) {
      if (p['learning_goals'] is List) {
        goals = List<String>.from(p['learning_goals']);
      } else if (p['learning_goals'] is String) {
        goals = [p['learning_goals'] as String];
      }
    }

    // Parse teaching & learning skills
    final userSkills = p['user_skills'] as List? ?? [];
    List<Map<String, String>> teachingSkills = [];
    List<Map<String, String>> learningSkills = [];

    for (var us in userSkills) {
      final type = us['type'];
      final skill = us['skills'];
      final prof = us['proficiency_level'] as String? ?? experienceLevel;
      if (skill is Map && skill['name'] != null) {
        final skillMap = {
          'name': skill['name'] as String,
          'category': (skill['category'] as String?) ?? 'General',
          'proficiency': prof,
        };
        if (type == 'TEACH') {
          teachingSkills.add(skillMap);
        } else {
          learningSkills.add(skillMap);
        }
      }
    }

    // Default fallback if skills table is empty for mock users
    if (teachingSkills.isEmpty && p['experience_level'] != null) {
      teachingSkills.add({
        'name': 'Peer Mentorship',
        'category': 'General',
        'proficiency': experienceLevel,
      });
    }

    final stats = _stats ?? {'swaps': '0', 'rating': 'New', 'connections': '0'};
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
          '@$username',
          style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.share2, color: textPrimary, size: 20),
            tooltip: 'Share Profile',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Check out @$username on SkillSwap AI!'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile link copied to clipboard!')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO HEADER WITH GRADIENT BANNER & AVATAR
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Top Banner
                Container(
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        top: 16,
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 42,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.zap, size: 12, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                'SkillSwap Peer Profile',
                                style: AppTypography.labelSm.copyWith(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Avatar
                Positioned(
                  bottom: -46,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFF059669),
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 32),
                                )
                              : null,
                        ),
                        // Online / Active Indicator
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 54),

            // 2. USER NAME, USERNAME & LOCATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          fullName,
                          style: AppTypography.headlineLg.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '@$username'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username copied to clipboard!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@$username',
                            style: AppTypography.labelMd.copyWith(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.copy, size: 12, color: textSecondary.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Location & Timezone info
                  if (location.isNotEmpty || timezone.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (location.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.mapPin, size: 14, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(location, style: AppTypography.bodySm.copyWith(color: textSecondary)),
                            ],
                          ),
                        if (timezone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.clock, size: 14, color: textSecondary),
                              const SizedBox(width: 4),
                              Text(timezone, style: AppTypography.bodySm.copyWith(color: textSecondary)),
                            ],
                          ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Pill Badges: Experience Level + Learning Style
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.award, size: 13, color: Color(0xFF059669)),
                            const SizedBox(width: 5),
                            Text(
                              experienceLevel,
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.sparkles, size: 13, color: Color(0xFF6366F1)),
                            const SizedBox(width: 5),
                            Text(
                              '$learningStyle Learner',
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bio Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: strokeColor),
                    ),
                    child: Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. 3-STAT BENTO GRID (COMMUNITY REPUTATION) - TOKENS EXCLUDED
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      label: 'Swaps Done',
                      value: stats['swaps'] ?? '0',
                      icon: LucideIcons.repeat,
                      iconColor: const Color(0xFF059669),
                      bgCard: bgCard,
                      strokeColor: strokeColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBentoStatCard(
                      label: 'Rating',
                      value: stats['rating'] == 'New' ? 'New' : '★ ${stats['rating']}',
                      icon: LucideIcons.star,
                      iconColor: const Color(0xFFF59E0B),
                      bgCard: bgCard,
                      strokeColor: strokeColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBentoStatCard(
                      label: 'Connections',
                      value: stats['connections'] ?? '0',
                      icon: LucideIcons.users,
                      iconColor: const Color(0xFF8B5CF6),
                      bgCard: bgCard,
                      strokeColor: strokeColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. SKILLS I TEACH SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSkillsSection(
                title: 'Skills I Teach',
                subtitle: 'Expertise & Knowledge offered',
                icon: LucideIcons.graduationCap,
                accentColor: const Color(0xFF059669),
                skills: teachingSkills,
                isTeaching: true,
                bgCard: bgCard,
                strokeColor: strokeColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // 5. SKILLS I WANT TO LEARN SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSkillsSection(
                title: 'Skills I Want to Learn',
                subtitle: 'Currently exploring & seeking mentorship',
                icon: LucideIcons.bookOpen,
                accentColor: const Color(0xFF3B82F6),
                skills: learningSkills,
                isTeaching: false,
                bgCard: bgCard,
                strokeColor: strokeColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // 6. AVAILABILITY & LEARNING GOALS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.calendarClock, color: Color(0xFFF59E0B), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Availability & Goals',
                              style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 16),
                            ),
                            Text(
                              'Schedule and milestones',
                              style: AppTypography.bodySm.copyWith(color: textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.checkCircle, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              availability,
                              style: AppTypography.bodyMd.copyWith(color: textPrimary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (goals.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Target Milestones:',
                        style: AppTypography.labelSm.copyWith(color: textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...goals.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(LucideIcons.target, size: 14, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g,
                                  style: AppTypography.bodySm.copyWith(color: textPrimary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 7. VERIFIED BLOCKCHAIN CREDENTIALS CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF8B5CF6), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Credentials',
                                style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 16),
                              ),
                              Text(
                                'Cryptographic proof-of-skill records',
                                style: AppTypography.bodySm.copyWith(color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_credentials.length} Badges',
                            style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_credentials.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.info, size: 18, color: textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No verified badges minted yet. Completing swap sessions earns blockchain-backed credentials!',
                                style: AppTypography.bodySm.copyWith(color: textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _credentials.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cred = _credentials[index];
                          final skill = cred['skill_name'] ?? 'Skill';
                          final tier = cred['badge_tier'] ?? 'Verified Novice';
                          final hours = cred['hours_completed'] ?? 1.0;
                          final hash = (cred['verification_hash'] as String? ?? '0x000000000000');
                          final hashPreview = hash.length > 12 ? '${hash.substring(0, 10)}...' : hash;

                          return InkWell(
                            onTap: () => _showCertificateViewerDialog(context, cred, isDark),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: strokeColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(LucideIcons.award, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              skill,
                                              style: AppTypography.labelMd.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tier,
                                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '$hours hrs verified',
                                              style: AppTypography.bodySm.copyWith(color: textSecondary, fontSize: 11),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '⛓️ $hashPreview',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, size: 16, color: textSecondary.withValues(alpha: 0.5)),
                                ],
                              ),
                            ),
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

      // 8. BOTTOM ACTION BAR (CHAT, SCHEDULE, CONNECT)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgCard,
          border: Border(top: BorderSide(color: strokeColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: isSelf
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/profile-preview'),
                    icon: const Icon(LucideIcons.edit3, size: 16),
                    label: const Text('Edit My Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              : _buildBottomActions(context, peerId, username),
        ),
      ),
    );
  }

  Widget _buildBentoStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgCard,
    required Color strokeColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strokeColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(
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
            style: AppTypography.bodySm.copyWith(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Map<String, String>> skills,
    required bool isTeaching,
    required Color bgCard,
    required Color strokeColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineMd.copyWith(color: textPrimary, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm.copyWith(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty)
            Text(
              isTeaching ? 'No teaching skills added yet.' : 'No learning interests added yet.',
              style: AppTypography.bodySm.copyWith(color: textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) {
                final name = s['name'] ?? 'Skill';
                final prof = s['proficiency'] ?? '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (isTeaching && prof.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            prof,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, String peerId, String username) {
    if (_isActionLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 1. Accepted Connection
    if (_connectionStatus == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/chat/$username'),
              icon: const Icon(LucideIcons.messageSquare, size: 16),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/schedule/$username'),
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: const Text('Schedule Swap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // 2. Pending Request
    if (_connectionStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(LucideIcons.clock, size: 16),
              label: const Text('Request Pending'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/schedule/$username'),
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: const Text('Schedule Swap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // 3. Not Connected yet
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              setState(() => _isActionLoading = true);
              final connService = ref.read(connectionServiceProvider);
              final success = await connService.sendRequest(peerId);

              if (mounted) {
                setState(() {
                  _isActionLoading = false;
                  if (success) _connectionStatus = 'pending';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Connection request sent to @$username!' : 'Failed to send request.'),
                    backgroundColor: success ? AppColors.primaryContainer : AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(LucideIcons.userPlus, size: 16),
            label: const Text('Connect / Swap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/schedule/$username'),
            icon: const Icon(LucideIcons.calendar, size: 16),
            label: const Text('Schedule'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
