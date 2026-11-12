import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';

/// Top-level background message handler required by Firebase Messaging.
/// This runs in an isolated background thread when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // If Firebase isn't initialized in this isolate, initialize it safely.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    
    final data = message.data;
    final notificationType = data['type'] as String?;
    final senderName = data['sender_name'] as String? ?? 'Someone';

    debugPrint('🔔 [FCM Background Handler] Message ID: ${message.messageId}');
    debugPrint('🔔 [FCM Background Handler] Type: $notificationType, Data: $data');

    // Handle offline notification types:
    // 1. Swap Request ('connection_request')
    // 2. New Chat Message ('new_message' or 'chat_message')
    if (notificationType == 'connection_request') {
      final skill = data['skill'] as String? ?? 'skills';
      debugPrint('🔔 Offline Push: Swap request from $senderName for $skill');
    } else if (notificationType == 'new_message' || notificationType == 'chat_message') {
      final preview = data['content'] as String? ?? data['message'] as String? ?? '';
      debugPrint('🔔 Offline Push: New message from $senderName: $preview');
    }
  } catch (e) {
    debugPrint('🔔 Error in FCM Background Handler: $e');
  }
}

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

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (e) {
      debugPrint('🔔 [FCM] FirebaseMessaging unavailable on this platform: $e');
    }
    return null;
  }

  NotificationService(this._client);

  /// Initialize Firebase Cloud Messaging listeners and register device token
  Future<void> initializeFCM({Function(String route)? onNavigate}) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('🔔 [FCM] Skipping FCM initialization: No default Firebase app initialized on this platform.');
        return;
      }

      final fcm = _fcm;
      if (fcm == null) return;

      // 1. Request notification permissions from mobile OS
      final settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      // 2. Fetch and register device FCM token with backend
      final token = await fcm.getToken();
      if (token != null) {
        debugPrint('🔔 FCM Device Token retrieved: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
        await updateFcmToken(token);
      }

      // 3. Listen for token refresh events
      fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('🔔 FCM Device Token refreshed');
        await updateFcmToken(newToken);
      });

      // 4. Foreground message listener (App is open and active)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 Foreground FCM Message received: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      // 5. Background click listener (App in background, user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 FCM Notification tapped from background');
        handleNotificationTap(message, onNavigate);
      });

      // 6. Cold start click listener (App was terminated, launched via notification)
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 FCM App launched from terminated state via notification');
        handleNotificationTap(initialMessage, onNavigate);
      }
    } catch (e) {
      debugPrint('🔔 FCM Initialization Note: $e');
    }
  }

  /// Update the current user's FCM device token in Supabase
  Future<void> updateFcmToken(String token) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', currentUserId);
      debugPrint('🔔 Synced FCM token to user profile: $currentUserId');
    } catch (e) {
      debugPrint('🔔 Notice syncing FCM token to profile: $e');
    }
  }

  /// Handle navigation when a notification is tapped
  void handleNotificationTap(RemoteMessage message, Function(String route)? onNavigate) {
    if (onNavigate == null) return;

    final data = message.data;
    final type = data['type'] as String?;
    final senderName = data['sender_name'] as String? ?? data['peer_name'] as String?;

    if (type == 'connection_request') {
      onNavigate('/notifications');
    } else if ((type == 'new_message' || type == 'chat_message') && senderName != null && senderName.isNotEmpty) {
      onNavigate('/chat/$senderName');
    } else {
      onNavigate('/notifications');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    debugPrint('🔔 Foreground Notification: ${notification?.title ?? data['type']} - ${notification?.body ?? data['content']}');
  }

  // --- Supabase In-App Notifications ---

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
      debugPrint('Error creating notification: $e');
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
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'is_read': true,
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
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
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Stream<int> subscribeToUnreadCount() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value(0);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .eq('is_read', false)
        .map((events) => events.length);
  }
}
