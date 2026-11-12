import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/shadcn_ui.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String peerName;
  const ChatScreen({super.key, required this.peerName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isLoadingMessages = true;
  String? _conversationId;
  Map<String, dynamic>? _peerData;
  String? _currentUserId;

  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _streamSubscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final chatService = ref.read(chatServiceProvider);
    final authService = ref.read(authServiceProvider);
    _currentUserId = authService.currentUser?.id;

    try {
      final conv = await chatService.getConversationByPeerUsername(widget.peerName);

      if (conv != null && mounted) {
        setState(() {
          _conversationId = conv['id'];
          _peerData = conv['peer'];
          _isLoading = false;
        });

        // 1. Initial REST fetch for instant, reliable message rendering
        await _fetchMessages(showSpinner: true);

        // 2. Realtime WebSocket subscription with resilient error fallback
        _subscribeToRealtime();

        // 3. Background periodic sync timer (failsafe against WebSocket drops)
        _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
          if (mounted && _conversationId != null) {
            _fetchMessages(showSpinner: false);
          }
        });

        // Mark incoming messages as read
        chatService.markMessagesAsRead(_conversationId!);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _fetchMessages({bool showSpinner = false}) async {
    if (_conversationId == null) return;
    if (showSpinner && mounted) {
      setState(() => _isLoadingMessages = true);
    }

    try {
      final chatService = ref.read(chatServiceProvider);
      final fetched = await chatService.getMessages(_conversationId!);

      if (mounted) {
        // Only update state if message counts differ or last message updated to avoid unnecessary rebuilds
        if (_messages.length != fetched.length || (_messages.isNotEmpty && fetched.isNotEmpty && _messages.last['id'] != fetched.last['id'])) {
          setState(() {
            _messages = fetched;
            _isLoadingMessages = false;
          });
        } else {
          setState(() => _isLoadingMessages = false);
        }
      }
    } catch (e) {
      print('Error fetching messages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _subscribeToRealtime() {
    if (_conversationId == null) return;

    try {
      final chatService = ref.read(chatServiceProvider);
      _streamSubscription = chatService.subscribeToMessages(_conversationId!).listen(
        (updatedList) {
          if (mounted && updatedList.isNotEmpty) {
            setState(() {
              _messages = updatedList;
              _isLoadingMessages = false;
            });
          }
        },
        onError: (err) {
          // Never blow up the screen on WebSocket drops: REST polling seamlessly keeps chat alive
          print('Realtime chat warning (falling back to REST sync): $err');
          if (mounted) {
            setState(() => _isLoadingMessages = false);
          }
        },
      );
    } catch (e) {
      print('Realtime stream setup exception: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty || _conversationId == null) return;

    if (customText == null) {
      _messageController.clear();
    }

    // 1. Optimistic Message Insert for Instant Feedback
    final tempId = 'opt-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': tempId,
      'conversation_id': _conversationId,
      'sender_id': _currentUserId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_sending': true,
    };

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    // 2. Send to Supabase
    try {
      final chatService = ref.read(chatServiceProvider);
      final success = await chatService.sendMessage(_conversationId!, text);

      if (success) {
        await _fetchMessages(showSpinner: false);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _startVideoCall() async {
    final roomId = 'SkillSwap-${widget.peerName}-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    final meetingUrl = 'https://meet.jit.si/$roomId';

    // Post to conversation so peer can click to join directly
    if (_conversationId != null) {
      await _sendMessage('📹 Jitsi Video Meeting: $meetingUrl');
    }

    final uri = Uri.parse(meetingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showQuickActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : AppColors.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: strokeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick Actions',
                  style: AppTypography.headlineMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.calendarPlus, color: Color(0xFF059669), size: 22),
                  ),
                  title: Text('Schedule Skill Swap', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Book a 45-min swap session on the ledger', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/schedule/${widget.peerName}');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.video, color: Color(0xFF6366F1), size: 22),
                  ),
                  title: Text('Start Instant Video Meeting', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Create a live Jitsi room and invite partner', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _startVideoCall();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.user, color: Color(0xFFD97706), size: 22),
                  ),
                  title: Text('View Creator Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Inspect verified skills, rating, and feedback', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile/${widget.peerName}');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgScaffold = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppColors.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgScaffold,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_conversationId == null || _peerData == null) {
      return Scaffold(
        backgroundColor: bgScaffold,
        appBar: AppBar(
          backgroundColor: bgScaffold,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.peerName, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.messageSquare, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('Could not connect to chat', style: AppTypography.headlineMd.copyWith(color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Make sure the user profile exists and you are signed in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _initChat(),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fullName = (_peerData!['full_name'] as String?) ?? widget.peerName;
    final username = (_peerData!['username'] as String?) ?? widget.peerName;
    final avatarUrl = _peerData!['avatar_url'] as String?;
    final level = (_peerData!['experience_level'] as String?) ?? 'Creator';

    final reversedMessages = _messages.reversed.toList();

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg.withOpacity(0.92),
            border: Border(bottom: BorderSide(color: strokeColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.arrowLeft, color: textPrimary, size: 20),
                    onPressed: () => context.pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  // Peer Profile Header
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/profile/$username'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF059669).withOpacity(0.15),
                                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty)
                                      ? Text(
                                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cardBg, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          fullName,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          level,
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@$username • Active on SkillSwap',
                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  IconButton(
                    icon: Icon(LucideIcons.calendarPlus, color: textPrimary, size: 20),
                    tooltip: 'Schedule Swap',
                    onPressed: () => context.push('/schedule/$username'),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.video, color: Colors.white, size: 18),
                      tooltip: 'Instant Video Call',
                      onPressed: _startVideoCall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Swap Context Header Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              border: Border(bottom: BorderSide(color: const Color(0xFF10B981).withOpacity(0.18))),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct Peer Exchange • 1 Hour = 1 Time Token',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/schedule/$username'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Book Swap',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Feed
          Expanded(
            child: _isLoadingMessages && _messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : reversedMessages.isEmpty
                    ? _buildEmptyState(fullName, isDark, cardBg, strokeColor, textPrimary, textSecondary)
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: reversedMessages.length,
                        itemBuilder: (context, index) {
                          final msg = reversedMessages[index];
                          final isMe = msg['sender_id'] == _currentUserId;
                          final isSending = msg['is_sending'] == true;
                          final content = (msg['content'] as String?) ?? '';
                          final createdAt = msg['created_at'] != null
                              ? DateTime.parse(msg['created_at'] as String).toLocal()
                              : DateTime.now();

                          return _buildMessageBubble(
                            content: content,
                            isMe: isMe,
                            isSending: isSending,
                            time: createdAt,
                            isDark: isDark,
                            cardBg: cardBg,
                            strokeColor: strokeColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          );
                        },
                      ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: strokeColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // '+' Quick Actions Menu
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.plus, color: textPrimary, size: 20),
                      tooltip: 'Actions',
                      onPressed: _showQuickActionsSheet,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: strokeColor),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message to $fullName...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                      tooltip: 'Send',
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String fullName,
    bool isDark,
    Color cardBg,
    Color strokeColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: strokeColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.messageCircle, size: 40, color: Color(0xFF059669)),
          ),
          const SizedBox(height: 18),
          Text(
            'Start your swap with $fullName!',
            style: AppTypography.headlineMd.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Introduce yourself, discuss the skills you want to exchange, or propose a time to meet.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Icebreaker Chips
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Icebreakers',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildIcebreakerChip(
                '👋 Hi! Excited to swap skills with you.',
                isDark,
                cardBg,
                strokeColor,
                textPrimary,
              ),
              _buildIcebreakerChip(
                '📅 When is a good time for our first swap session?',
                isDark,
                cardBg,
                strokeColor,
                textPrimary,
              ),
              _buildIcebreakerChip(
                '🚀 What specific skill areas would you like to focus on?',
                isDark,
                cardBg,
                strokeColor,
                textPrimary,
              ),
              _buildIcebreakerChip(
                '🤝 Let\'s do a 45-min swap this week!',
                isDark,
                cardBg,
                strokeColor,
                textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcebreakerChip(
    String text,
    bool isDark,
    Color cardBg,
    Color strokeColor,
    Color textPrimary,
  ) {
    return InkWell(
      onTap: () => _sendMessage(text),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: strokeColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.send, size: 12, color: Color(0xFF059669)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isMe,
    required bool isSending,
    required DateTime time,
    required bool isDark,
    required Color cardBg,
    required Color strokeColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final formattedTime = DateFormat('h:mm a').format(time);
    final isMeeting = content.contains('https://meet.jit.si/');

    String? meetingUrl;
    if (isMeeting) {
      final exp = RegExp(r'https://meet\.jit\.si/[a-zA-Z0-9_\-]+');
      final match = exp.firstMatch(content);
      if (match != null) {
        meetingUrl = match.group(0);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: isMeeting && meetingUrl != null
            ? _buildMeetingCard(meetingUrl, isMe, formattedTime, isDark, cardBg, strokeColor, textPrimary, textSecondary)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF0D9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(18),
                    bottomLeft: !isMe ? const Radius.circular(3) : const Radius.circular(18),
                  ),
                  border: isMe ? null : Border.all(color: strokeColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.white : textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: isMe ? Colors.white.withOpacity(0.75) : textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isSending ? LucideIcons.clock : LucideIcons.checkCheck,
                            size: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMeetingCard(
    String meetingUrl,
    bool isMe,
    String timeStr,
    bool isDark,
    Color cardBg,
    Color strokeColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669).withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.video, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Skill Swap Video Call',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Text(
                  'Live',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encrypted Jitsi Meet Room created for your skill exchange session.',
                  style: TextStyle(color: textSecondary, fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(meetingUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(LucideIcons.video, size: 14, color: Colors.white),
                        label: const Text('Join Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: meetingUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meeting link copied!')),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: BorderSide(color: strokeColor),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(timeStr, style: TextStyle(color: textSecondary, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
