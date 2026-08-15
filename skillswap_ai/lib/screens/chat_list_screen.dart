import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/connection_service.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          _conversations = results[0] as List<Map<String, dynamic>>;
          _pendingRequests = results[1] as List<Map<String, dynamic>>;
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
      _loadData(); // Reload everything
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted!')));
    }
  }
  
  Future<void> _declineRequest(String connectionId) async {
    final connService = ref.read(connectionServiceProvider);
    final success = await connService.declineRequest(connectionId);
    if (success && mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  if (_pendingRequests.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text('Pending Requests', style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final req = _pendingRequests[index];
                          final requester = req['profiles'];
                          final username = requester['username'];
                          final fullName = requester['full_name'];
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(fullName[0], style: const TextStyle(color: AppColors.onPrimaryContainer)),
                            ),
                            title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('@$username', style: const TextStyle(color: AppColors.primary)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppColors.error),
                                  onPressed: () => _declineRequest(req['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: AppColors.primary),
                                  onPressed: () => _acceptRequest(req['id'], requester['id']),
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push('/profile/$username');
                            },
                          );
                        },
                        childCount: _pendingRequests.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(height: 32, color: AppColors.surfaceStroke),
                    ),
                  ],
                  
                  if (_conversations.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.outline),
                            const SizedBox(height: 16),
                            Text('No conversations yet', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            const Text('Connect with people to start chatting.'),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = _conversations[index];
                          final peer = conv['peer'];
                          final lastMessage = conv['lastMessage'];
                          final unreadCount = conv['unreadCount'] as int;
                          
                          final peerName = peer['full_name'];
                          final peerUsername = peer['username'];
                          
                          String msgText = 'No messages yet';
                          String timeText = '';
                          
                          if (lastMessage != null) {
                            msgText = lastMessage['content'];
                            // Very simple time format
                            final dt = DateTime.parse(lastMessage['created_at']);
                            final diff = DateTime.now().difference(dt);
                            if (diff.inDays > 0) {
                              timeText = '${diff.inDays}d';
                            } else if (diff.inHours > 0) {
                              timeText = '${diff.inHours}h';
                            } else if (diff.inMinutes > 0) {
                              timeText = '${diff.inMinutes}m';
                            } else {
                              timeText = 'now';
                            }
                          }
                          
                          return InkWell(
                            onTap: () {
                              context.push('/chat/$peerUsername').then((_) => _loadData());
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryContainer,
                                    radius: 28,
                                    child: Text(peerName[0], style: const TextStyle(color: AppColors.onPrimaryContainer, fontSize: 20)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(
                                          msgText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: unreadCount > 0 ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (timeText.isNotEmpty)
                                        Text(timeText, style: const TextStyle(fontSize: 12, color: AppColors.outline)),
                                      if (unreadCount > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _conversations.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
