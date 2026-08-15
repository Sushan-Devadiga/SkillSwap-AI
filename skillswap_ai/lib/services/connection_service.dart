import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'notification_service.dart';

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ConnectionService(supabase, notificationService);
});

class ConnectionService {
  final SupabaseClient _client;
  final NotificationService _notificationService;

  ConnectionService(this._client, this._notificationService);

  Future<String> getConnectionStatus(String peerId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return 'none';

    try {
      final response = await _client.from('connections').select('status, requester_id, receiver_id').or('and(requester_id.eq.$currentUserId,receiver_id.eq.$peerId),and(requester_id.eq.$peerId,receiver_id.eq.$currentUserId)').maybeSingle();
      
      if (response == null) return 'none';
      return response['status'] as String;
    } catch (e) {
      print('Error getting connection status: $e');
      return 'none';
    }
  }

  Future<bool> sendRequest(String receiverId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == receiverId) return false;

    try {
      await _client.from('connections').insert({
        'requester_id': currentUserId,
        'receiver_id': receiverId,
        'status': 'pending',
      });
      
      final profileResp = await _client.from('profiles').select('full_name').eq('id', currentUserId).single();
      
      await _notificationService.createNotification(
        userId: receiverId,
        type: 'connection_request',
        content: '${profileResp['full_name']} sent you a skill swap request.',
        relatedEntityId: currentUserId,
      );
      
      return true;
    } catch (e) {
      print('Error sending connection request: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _client.from('connections').select('''
        id,
        created_at,
        profiles!connections_requester_id_fkey(
          id,
          username,
          full_name,
          avatar_url
        )
      ''').eq('receiver_id', currentUserId).eq('status', 'pending');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  Future<bool> acceptRequest(String connectionId, String requesterId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      // Update connection status
      await _client.from('connections').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', connectionId);

      // Create conversation
      // Check if one already exists to be safe
      final existingConv = await _client.from('conversations').select('id').or('and(participant1_id.eq.$currentUserId,participant2_id.eq.$requesterId),and(participant1_id.eq.$requesterId,participant2_id.eq.$currentUserId)').maybeSingle();
      
      if (existingConv == null) {
        await _client.from('conversations').insert({
          'participant1_id': requesterId,
          'participant2_id': currentUserId,
        });
      }
      
      final profileResp = await _client.from('profiles').select('full_name').eq('id', currentUserId).single();
      
      await _notificationService.createNotification(
        userId: requesterId,
        type: 'connection_accepted',
        content: '${profileResp['full_name']} accepted your skill swap request!',
        relatedEntityId: currentUserId,
      );
      
      return true;
    } catch (e) {
      print('Error accepting connection request: $e');
      return false;
    }
  }

  Future<bool> declineRequest(String connectionId) async {
    try {
      await _client.from('connections').update({
        'status': 'declined',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', connectionId);
      return true;
    } catch (e) {
      print('Error declining connection request: $e');
      return false;
    }
  }
}
