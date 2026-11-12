import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/shadcn_ui.dart';
import '../providers/session_provider.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/credential_service.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/discover_service.dart';
import '../services/session_service.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';

class LearningProgressScreen extends ConsumerWidget {
  const LearningProgressScreen({super.key});

  void _showCompleteSessionDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> session,
    String peerName,
    String? peerId,
    String currentUserId,
  ) {
    int selectedRating = 5;
    final feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Complete & Verify Swap', style: AppTypography.headlineMd),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.coins, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Time Token Economy: 1 Hour = 1 Token\nMints a cryptographic Blockchain Skill Badge.',
                            style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'How was your skill exchange with $peerName?',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          iconSize: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          icon: Icon(
                            star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: star <= selectedRating ? const Color(0xFFF59E0B) : AppColors.surfaceStroke,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    selectedRating = star;
                                  });
                                },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Feedback & Peer Review', style: AppTypography.labelSm),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: feedbackController,
                    maxLines: 3,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Share how the session went or what was accomplished...',
                      filled: true,
                      fillColor: AppColors.surfaceBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.surfaceStroke),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final durationMin = session['duration_minutes'] as int? ?? 60;
                          final hours = durationMin / 60.0;
                          final providerId = (session['organizer_id'] == currentUserId) ? currentUserId : (peerId ?? currentUserId);
                          final receiverId = (session['organizer_id'] == currentUserId) ? (peerId ?? currentUserId) : currentUserId;

                          final sessionService = ref.read(sessionServiceProvider);
                          final success = await sessionService.completeSession(
                            sessionId: session['id'],
                            providerId: providerId,
                            receiverId: receiverId,
                            skillId: session['skill_id'],
                            hours: hours,
                            rating: selectedRating,
                            feedback: feedbackController.text.trim(),
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (context.mounted) {
                            if (success) {
                              ref.invalidate(activeSwapsProvider);
                              ref.invalidate(completedSkillsProvider);
                              ref.invalidate(tokenBalanceProvider);
                              ref.invalidate(tokenTransactionsProvider);
                              ref.invalidate(userCredentialsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(LucideIcons.award, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text('🎉 Swap complete! 1 Time Token transferred & Verified Badge minted.'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to complete session. Please try again.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit & Complete'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSwapDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> session,
    Map<String, dynamic>? peerProfile,
    String? currentUserId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    final peerId = peerProfile?['id'] as String? ?? '';
    final peerUsername = peerProfile?['username'] as String? ?? '';
    final peerName = peerProfile?['full_name'] as String? ?? (peerUsername.isNotEmpty ? peerUsername : 'Partner');
    final peerAvatar = peerProfile?['avatar_url'] as String?;
    final peerBio = peerProfile?['bio'] as String? ?? '';
    final peerLevel = peerProfile?['experience_level'] as String? ?? 'Learner';

    final sessionTitle = session['title'] as String? ?? 'Skill Swap Session';
    final meetingLink = session['meeting_link'] as String?;
    final scheduledTimeStr = session['scheduled_time'];
    final scheduledTime = scheduledTimeStr != null ? DateTime.parse(scheduledTimeStr).toLocal() : null;
    final formattedDate = scheduledTime != null ? DateFormat('EEEE, MMMM d, y').format(scheduledTime) : 'TBD';
    final formattedTime = scheduledTime != null ? DateFormat('h:mm a').format(scheduledTime) : 'TBD';
    final duration = session['duration_minutes'] ?? 45;
    final status = session['status'] == 'in_progress' ? 'In Progress' : 'Scheduled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: (peerId.isNotEmpty || peerUsername.isNotEmpty)
              ? ref.read(discoverServiceProvider).getProfile(peerId.isNotEmpty ? peerId : peerUsername)
              : Future.value(peerProfile),
          builder: (context, snapshot) {
            final fullPeer = snapshot.data ?? peerProfile;
            final bio = (fullPeer?['bio'] as String?)?.isNotEmpty == true ? fullPeer!['bio'] as String : peerBio;
            final avatar = fullPeer?['avatar_url'] as String? ?? peerAvatar;
            final fullName = fullPeer?['full_name'] as String? ?? peerName;
            final username = fullPeer?['username'] as String? ?? peerUsername;
            final level = fullPeer?['experience_level'] as String? ?? peerLevel;
            final resolvedPeerId = fullPeer?['id'] as String? ?? peerId;

            final teachingSkills = <String>[];
            final learningSkills = <String>[];
            final userSkills = fullPeer?['user_skills'] as List? ?? [];
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

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: strokeColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
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
                            child: const Icon(LucideIcons.repeat, size: 18, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Skill Swap Details',
                                  style: AppTypography.headlineMd.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  sessionTitle,
                                  style: AppTypography.bodySm.copyWith(color: subtextColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                      const SizedBox(height: 16),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Partner Profile Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: strokeColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: AppColors.primaryContainer,
                                          backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                          child: avatar == null || avatar.isEmpty
                                              ? Text(
                                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      fullName,
                                                      style: AppTypography.headlineMd.copyWith(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: textColor,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(LucideIcons.sparkles, size: 10, color: Color(0xFF059669)),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          level,
                                                          style: const TextStyle(
                                                            color: Color(0xFF059669),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (username.isNotEmpty)
                                                Text('@$username', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (bio.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        bio,
                                        style: AppTypography.bodySm.copyWith(color: subtextColor, height: 1.4),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(sheetContext);
                                              final target = resolvedPeerId.isNotEmpty ? resolvedPeerId : username;
                                              if (target.isNotEmpty) {
                                                context.push('/profile/$target');
                                              }
                                            },
                                            icon: const Icon(LucideIcons.user, size: 14),
                                            label: const Text('View Profile'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: textColor,
                                              side: BorderSide(color: strokeColor),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(sheetContext);
                                              if (username.isNotEmpty) {
                                                context.push('/chat/$username');
                                              }
                                            },
                                            icon: const Icon(LucideIcons.messageSquare, size: 14, color: Colors.white),
                                            label: const Text('Message', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 2. Skills Information Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: strokeColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.bookOpen, size: 16, color: Color(0xFF059669)),
                                        const SizedBox(width: 8),
                                        Text('Skills Being Swapped', style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700, color: textColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (teachingSkills.isNotEmpty || learningSkills.isNotEmpty) ...[
                                      if (teachingSkills.isNotEmpty) ...[
                                        Text('Partner Teaches (You Learn):', style: AppTypography.labelSm.copyWith(color: subtextColor, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: teachingSkills.map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF059669).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.bookOpen, size: 12, color: Color(0xFF059669)),
                                                const SizedBox(width: 5),
                                                Text(s, style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          )).toList(),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (learningSkills.isNotEmpty) ...[
                                        Text('You Teach (Partner Learns):', style: AppTypography.labelSm.copyWith(color: subtextColor, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: learningSkills.map((s) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D9488).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF0D9488)),
                                                const SizedBox(width: 5),
                                                Text(s, style: const TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          )).toList(),
                                        ),
                                      ],
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(LucideIcons.repeat, size: 14, color: Color(0xFF059669)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sessionTitle,
                                                style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // 3. Schedule, Token & Meeting Details
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: strokeColor),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '$formattedDate • $formattedTime',
                                            style: AppTypography.bodyMd.copyWith(color: textColor, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Text('$duration min', style: AppTypography.bodySm.copyWith(color: subtextColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.coins, size: 16, color: Color(0xFFD97706)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '1 Time Token (Minted upon swap completion)',
                                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (meetingLink != null && meetingLink.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.link, size: 16, color: Color(0xFF059669)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              meetingLink,
                                              style: TextStyle(color: subtextColor, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: meetingLink));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Meeting link copied!')),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: strokeColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
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
                          if (meetingLink != null && meetingLink.isNotEmpty) ...[
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(sessionServiceProvider).openMeetingLink(meetingLink);
                                  },
                                  icon: const Icon(LucideIcons.video, size: 16, color: Colors.white),
                                  label: const Text('Join Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _showCompleteSessionDialog(
                                  context,
                                  ref,
                                  session,
                                  fullName,
                                  resolvedPeerId.isNotEmpty ? resolvedPeerId : null,
                                  currentUserId ?? '',
                                );
                              },
                              icon: const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.primary),
                              label: const Text('Complete', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final sessionId = session['id'] as String?;
                            if (sessionId == null) return;

                            final confirm = await showDialog<bool>(
                              context: context,
                              useRootNavigator: true,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Cancel Session?', style: AppTypography.headlineMd.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Text(
                                  'Are you sure you want to cancel and remove this swap session with $fullName? This will immediately remove it from your active learning schedule.',
                                  style: AppTypography.bodySm.copyWith(color: subtextColor, height: 1.4),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: Text('Keep Session', style: TextStyle(color: subtextColor, fontWeight: FontWeight.w600)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    child: const Text('Yes, Cancel Session', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              Navigator.pop(sheetContext);
                              await ref.read(sessionServiceProvider).cancelSession(sessionId);
                              ref.invalidate(activeSwapsProvider);
                              ref.invalidate(upcomingSessionsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Session cancelled and removed from active swaps.'),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF0F172A),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                          label: const Text('Cancel This Session', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSwapsAsync = ref.watch(activeSwapsProvider);
    final completedSkillsAsync = ref.watch(completedSkillsProvider);
    final currentUserId = ref.watch(authServiceProvider).currentUser?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceBg,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceBg.withOpacity(0.9),
          elevation: 0,
          title: Text('My Learning', style: AppTypography.headlineLg),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.onSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: AppColors.surfaceContainerLowest,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  labelStyle: AppTypography.labelMd,
                  tabs: const [
                    Tab(text: 'Active Swaps'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // ACTIVE SWAPS TAB
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activeSwapsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  activeSwapsAsync.when(
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Skeleton(height: 160, borderRadius: 16),
                          ),
                          childCount: 3,
                        ),
                      ),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text('Could not load swaps', style: AppTypography.headlineMd),
                              const SizedBox(height: 8),
                              Text('$err', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.invalidate(activeSwapsProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    data: (activeSwaps) {
                      if (activeSwaps.isEmpty) {
                        return SliverFillRemaining(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: EmptyState(
                              title: 'No active swaps',
                              description: 'Find a match and schedule your first session to start learning.',
                              icon: LucideIcons.bookOpen,
                              buttonText: 'Discover Matches',
                              onButtonTap: () => ref.read(mainNavIndexProvider.notifier).setIndex(1),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final session = activeSwaps[index];
                              Map<String, dynamic>? peerProfile = session['peer_profile'] as Map<String, dynamic>?;
                              
                              if (peerProfile == null) {
                                final participants = session['session_participants'] as List? ?? [];
                                for (var p in participants) {
                                  if (p['participant_id'] != currentUserId && p['profiles'] != null) {
                                    peerProfile = p['profiles'] as Map<String, dynamic>;
                                    break;
                                  }
                                }
                              }

                              if (peerProfile == null && session['organizer_id'] != currentUserId) {
                                final org = session['organizer'] as Map<String, dynamic>?;
                                if (org != null) peerProfile = org;
                              }

                              if (peerProfile == null) {
                                final titleStr = session['title'] as String? ?? '';
                                final match = RegExp(r'with\s+(.+)$', caseSensitive: false).firstMatch(titleStr);
                                final extracted = match != null ? match.group(1)?.trim() : null;
                                if (extracted != null && extracted.isNotEmpty) {
                                  peerProfile = {
                                    'id': '',
                                    'full_name': extracted,
                                    'username': extracted.toLowerCase().replaceAll(' ', ''),
                                    'experience_level': 'Learner',
                                  };
                                }
                              }
                              
                              final peerName = peerProfile?['full_name'] ?? peerProfile?['username'] ?? 'Partner';
                              final peerAvatar = peerProfile?['avatar_url'] as String?;
                              final peerExperience = peerProfile?['experience_level'] as String? ?? 'Learner';
                              final hasAvatar = peerAvatar != null && peerAvatar.isNotEmpty;

                              final title = session['title'] ?? 'Session';
                              final status = session['status'] == 'in_progress' ? 'In Progress' : 'Scheduled';
                              final scheduledTimeStr = session['scheduled_time'];
                              final scheduledTime = scheduledTimeStr != null ? DateTime.parse(scheduledTimeStr).toLocal() : null;
                              final formattedTime = scheduledTime != null ? DateFormat('EEEE, h:mm a').format(scheduledTime) : 'TBD';

                                      final meetingLink = session['meeting_link'] as String?;

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
                                              InkWell(
                                                onTap: () => _showSwapDetailsSheet(
                                                  context,
                                                  ref,
                                                  session,
                                                  peerProfile,
                                                  currentUserId,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 22,
                                                              backgroundColor: AppColors.primaryContainer,
                                                              backgroundImage: hasAvatar ? NetworkImage(peerAvatar) : null,
                                                              child: !hasAvatar
                                                                  ? Text(
                                                                      peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                                                    )
                                                                  : null,
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Flexible(
                                                                        child: Text(
                                                                          peerName,
                                                                          style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                        decoration: BoxDecoration(
                                                                          color: AppColors.primaryContainer.withOpacity(0.12),
                                                                          borderRadius: BorderRadius.circular(6),
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            const Icon(LucideIcons.sparkles, size: 10, color: AppColors.primaryContainer),
                                                                            const SizedBox(width: 3),
                                                                            Text(
                                                                              peerExperience,
                                                                              style: const TextStyle(
                                                                                color: AppColors.primaryContainer,
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.w700,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Text(
                                                                    title,
                                                                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryContainer.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(status, style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                                                            const SizedBox(width: 4),
                                                            const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.primary),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  const Icon(LucideIcons.calendarClock, size: 16, color: AppColors.onSurfaceVariant),
                                                  const SizedBox(width: 8),
                                                  Text('Next: $formattedTime', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('Progress', style: AppTypography.labelSm),
                                                      Text('50%', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: LinearProgressIndicator(
                                                      value: 0.5,
                                                      backgroundColor: AppColors.surfaceContainer,
                                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                      minHeight: 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              const Divider(height: 1, color: AppColors.surfaceStroke),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (meetingLink != null && meetingLink.isNotEmpty) ...[
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        ref.read(sessionServiceProvider).openMeetingLink(meetingLink);
                                                      },
                                                      icon: const Icon(LucideIcons.video, size: 15, color: Colors.white),
                                                      label: const Text(
                                                        'Join Call',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primary,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      final peerId = peerProfile?['id'] as String?;
                                                      _showCompleteSessionDialog(
                                                        context,
                                                        ref,
                                                        session,
                                                        peerName,
                                                        peerId,
                                                        currentUserId ?? '',
                                                      );
                                                    },
                                                    icon: const Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.primary),
                                                    label: const Text(
                                                      'Complete Session',
                                                      style: TextStyle(
                                                        color: AppColors.primary,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(color: AppColors.primary),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                ).animate().fade(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0),
                              );
                            },
                            childCount: activeSwaps.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            
            // COMPLETED TAB
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(completedSkillsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  completedSkillsAsync.when(
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Skeleton(height: 80, borderRadius: 16),
                          ),
                          childCount: 3,
                        ),
                      ),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text('Could not load completed exchanges', style: AppTypography.headlineMd),
                              const SizedBox(height: 8),
                              Text('$err', textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.invalidate(completedSkillsProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    data: (completedSkills) {
                      if (completedSkills.isEmpty) {
                        return SliverFillRemaining(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: EmptyState(
                              title: 'No completed skills yet',
                              description: 'Complete your first session to see it here.',
                              icon: LucideIcons.award,
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final exchange = completedSkills[index];
                              final skill = exchange['skills'] as Map<String, dynamic>?;
                              final skillName = skill?['name'] ?? 'Unknown Skill';
                              final provider = exchange['provider'] as Map<String, dynamic>?;
                              final providerName = provider?['full_name'] ?? provider?['username'] ?? 'Unknown Mentor';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.surfaceStroke),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(LucideIcons.checkCircle2, color: Colors.green),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(skillName, style: AppTypography.labelMd),
                                            Text('Mentored by $providerName', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fade(duration: 400.ms, delay: (index * 50).ms),
                              );
                            },
                            childCount: completedSkills.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
