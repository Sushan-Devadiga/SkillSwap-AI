import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/chat_service.dart';
import '../services/connection_service.dart';
import '../services/auth_service.dart';
import '../providers/navigation_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTab = 'all'; // 'all', 'unread', 'requests'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final connService = ref.read(connectionServiceProvider);

      final results = await Future.wait([
        chatService.getConversations(),
        connService.getPendingRequests(),
      ]);

      if (mounted) {
        setState(() {
          _conversations = results[0];
          _pendingRequests = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest(String connectionId, String requesterId) async {
    final connService = ref.read(connectionServiceProvider);
    final success = await connService.acceptRequest(connectionId, requesterId);
    if (success && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Request accepted! You can now chat.'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _declineRequest(String connectionId) async {
    final connService = ref.read(connectionServiceProvider);
    final success = await connService.declineRequest(connectionId);
    if (success && mounted) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request declined'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = ref.watch(authServiceProvider).currentUser?.id;
    final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.surfaceBg;
    final cardBg = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.surfaceStroke;
    final textColor = isDark ? Colors.white : AppColors.onSurface;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : AppColors.onSurfaceVariant;

    // Filter conversations
    final filteredConversations = _conversations.where((conv) {
      final peer = conv['peer'] as Map<String, dynamic>? ?? {};
      final fullName = (peer['full_name'] ?? '').toString().toLowerCase();
      final username = (peer['username'] ?? '').toString().toLowerCase();
      final lastMsg = (conv['lastMessage']?['content'] ?? '').toString().toLowerCase();
      final unreadCount = (conv['unreadCount'] as int?) ?? 0;

      if (_selectedTab == 'unread' && unreadCount == 0) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = fullName.contains(query) || username.contains(query) || lastMsg.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();

    final totalUnread = _conversations.fold<int>(0, (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(
              'Messages',
              style: AppTypography.headlineLg.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '$totalUnread new',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.compass, size: 20, color: AppColors.primary),
            tooltip: 'Discover New Partners',
            onPressed: () => ref.read(mainNavIndexProvider.notifier).setIndex(1),
          ),
          IconButton(
            icon: Icon(LucideIcons.refreshCw, size: 18, color: subtextColor),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),

                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search chats or people...',
                        hintStyle: AppTypography.bodyMd.copyWith(color: subtextColor.withOpacity(0.7)),
                        prefixIcon: Icon(LucideIcons.search, size: 18, color: subtextColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(LucideIcons.x, size: 16, color: subtextColor),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip(
                          title: 'All Chats',
                          count: _conversations.length,
                          isActive: _selectedTab == 'all',
                          onTap: () => setState(() => _selectedTab = 'all'),
                          isDark: isDark,
                          textColor: textColor,
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(width: 8),
                        _buildTabChip(
                          title: 'Unread',
                          count: totalUnread,
                          isActive: _selectedTab == 'unread',
                          onTap: () => setState(() => _selectedTab = 'unread'),
                          isDark: isDark,
                          textColor: textColor,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          accentColor: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildTabChip(
                          title: 'Requests',
                          count: _pendingRequests.length,
                          isActive: _selectedTab == 'requests',
                          onTap: () => setState(() => _selectedTab = 'requests'),
                          isDark: isDark,
                          textColor: textColor,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          accentColor: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pending Requests Section
                  if (_pendingRequests.isNotEmpty && (_selectedTab == 'all' || _selectedTab == 'requests')) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.userCheck, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            'Pending Swap Requests (${_pendingRequests.length})',
                            style: AppTypography.labelMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ..._pendingRequests.map((req) {
                      final requester = req['profiles'] as Map<String, dynamic>? ?? {};
                      final username = requester['username'] ?? 'user';
                      final fullName = requester['full_name'] ?? 'Creator';
                      final avatarUrl = requester['avatar_url'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildAvatar(fullName, avatarUrl, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@$username • Wants to swap skills',
                                    style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, color: AppColors.error, size: 18),
                              tooltip: 'Decline',
                              onPressed: () => _declineRequest(req['id']),
                            ),
                            ElevatedButton(
                              onPressed: () => _acceptRequest(req['id'], requester['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                  ],

                  // Tab is requests and none exist
                  if (_selectedTab == 'requests' && _pendingRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(LucideIcons.userCheck, size: 48, color: subtextColor.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No pending requests',
                              style: AppTypography.headlineMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Incoming skill swap requests will appear here.',
                              style: AppTypography.bodyMd.copyWith(color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Conversations List
                  if (_selectedTab != 'requests') ...[
                    if (filteredConversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(LucideIcons.messageSquare, size: 56, color: subtextColor.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ? 'No chats found' : 'No conversations yet',
                                style: AppTypography.headlineMd.copyWith(color: textColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No conversations matching "$_searchQuery".'
                                    : 'Discover creators and request a skill swap to chat!',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(color: subtextColor),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => ref.read(mainNavIndexProvider.notifier).setIndex(1),
                                icon: const Icon(LucideIcons.compass, size: 18),
                                label: const Text('Find Skill Partners'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredConversations.map((conv) {
                        final peer = conv['peer'] as Map<String, dynamic>? ?? {};
                        final lastMessage = conv['lastMessage'] as Map<String, dynamic>?;
                        final unreadCount = (conv['unreadCount'] as int?) ?? 0;
                        final isUnread = unreadCount > 0;

                        final peerName = peer['full_name'] ?? 'Creator';
                        final peerUsername = peer['username'] ?? 'user';
                        final avatarUrl = peer['avatar_url'] as String?;

                        final lastSenderId = lastMessage?['sender_id'];
                        final isSentByMe = lastSenderId != null && lastSenderId == currentUserId;
                        final content = lastMessage?['content'] as String? ?? 'No messages yet';
                        final isMeeting = content.contains('meet.jit.si') || content.contains('📹');
                        final timeText = _formatRelativeTime(lastMessage?['created_at']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? (isDark ? const Color(0xFF132E27) : const Color(0xFFF0FDF4))
                                : cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnread ? AppColors.primary.withOpacity(0.4) : borderColor,
                              width: isUnread ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push('/chat/$peerUsername').then((_) => _loadData());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  _buildAvatar(peerName, avatarUrl, size: 48),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                peerName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (timeText.isNotEmpty)
                                              Text(
                                                timeText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isUnread ? AppColors.primary : subtextColor,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (isMeeting) ...[
                                              const Icon(LucideIcons.video, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              const Text('Video Session • ', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ] else if (isSentByMe) ...[
                                              Text('You: ', style: TextStyle(color: subtextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                            Expanded(
                                              child: Text(
                                                content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isUnread ? textColor : subtextColor,
                                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (unreadCount > 0)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],

                  // Safe bottom padding for floating navigation bar
                  const SizedBox(height: 110),
                ],
              ),
            ),
    );
  }

  Widget _buildTabChip({
    required String title,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color cardBg,
    required Color borderColor,
    Color? accentColor,
  }) {
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeText = isDark ? const Color(0xFF0F172A) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeBg : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeBg : borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? activeText : textColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
                    : (accentColor != null && count > 0 ? accentColor.withOpacity(0.15) : borderColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : (accentColor != null && count > 0 ? accentColor : textColor.withOpacity(0.8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl, {double size = 48}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(initial, size),
        ),
      );
    }

    return _buildFallbackAvatar(initial, size);
  }

  Widget _buildFallbackAvatar(String initial, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
