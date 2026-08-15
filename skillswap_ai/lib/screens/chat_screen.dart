import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String peerName; // Actually we pass username via route, so this is peerUsername
  const ChatScreen({super.key, required this.peerName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  String? _conversationId;
  Map<String, dynamic>? _peerData;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final chatService = ref.read(chatServiceProvider);
    final authService = ref.read(authServiceProvider);
    _currentUserId = authService.currentUser?.id;
    
    final conv = await chatService.getConversationByPeerUsername(widget.peerName);
    
    if (conv != null && mounted) {
      setState(() {
        _conversationId = conv['id'];
        _peerData = conv['peer'];
        _isLoading = false;
      });
      
      // Mark as read
      chatService.markMessagesAsRead(_conversationId!);
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _conversationId == null) return;
    
    _messageController.clear();
    
    final chatService = ref.read(chatServiceProvider);
    await chatService.sendMessage(_conversationId!, content);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_conversationId == null || _peerData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.peerName)),
        body: const Center(child: Text('Chat not found. Please connect first.')),
      );
    }
    
    final fullName = _peerData!['full_name'] as String;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.push('/profile/${widget.peerName}'),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                radius: 16,
                child: Text(fullName[0], style: const TextStyle(color: AppColors.onPrimaryContainer, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Text(fullName),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              context.push('/schedule/${widget.peerName}');
            },
          ),
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(chatServiceProvider).subscribeToMessages(_conversationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                
                final messages = snapshot.data ?? [];
                // Reverse the list for ListView with reverse: true so it auto-scrolls properly
                final reversedMessages = messages.reversed.toList();
                
                if (reversedMessages.isEmpty) {
                  return const Center(child: Text('Say hi!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    final isMe = msg['sender_id'] == _currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : null,
                            bottomLeft: !isMe ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          msg['content'] as String,
                          style: TextStyle(
                            color: isMe ? AppColors.onPrimary : AppColors.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16).copyWith(bottom: 32),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: AppColors.surfaceStroke)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.outline),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.surfaceBright,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
