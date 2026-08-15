import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final service = ref.read(notificationServiceProvider);
    final notifs = await service.getNotifications();
    
    if (mounted) {
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
      // Mark all as read when opening the screen
      await service.markAllAsRead();
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'connection_request':
        return Icons.person_add;
      case 'connection_accepted':
        return Icons.handshake;
      case 'session_invitation':
        return Icons.calendar_month;
      case 'session_completion':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isRead = notif['is_read'] as bool;
                    final type = notif['type'] as String;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      tileColor: isRead ? null : AppColors.surfaceContainerLow,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(_getIconForType(type), color: AppColors.onPrimaryContainer),
                      ),
                      title: Text(
                        notif['content'],
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _formatTime(notif['created_at']),
                        style: const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      onTap: () {
                        // Routing logic based on type could go here
                        if (type == 'connection_request') {
                          context.push('/chat'); // Goes to message tab which has pending requests
                        } else if (type == 'session_invitation' || type == 'session_completion') {
                          context.go('/home'); // Home has upcoming sessions
                        }
                      },
                    );
                  },
                ),
    );
  }
  
  String _formatTime(String isoString) {
    final dt = DateTime.parse(isoString);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}
