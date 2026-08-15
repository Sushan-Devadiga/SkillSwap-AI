import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationService(supabase);
});

// Stream provider for unread count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.subscribeToUnreadCount();
});

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  Future<void> createNotification({
    required String userId,
    required String type,
    required String content,
    String? relatedEntityId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'content': content,
        if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _client.from('notifications')
          .select('*')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(50);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'is_read': true,
      }).eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      await _client.from('notifications').update({
        'is_read': true,
      }).eq('user_id', currentUserId).eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Stream<int> subscribeToUnreadCount() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value(0);

    // Initial fetch, then listen to realtime updates
    // Supabase stream emits full updated lists for the query
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .eq('is_read', false)
        .map((events) => events.length);
  }
}
