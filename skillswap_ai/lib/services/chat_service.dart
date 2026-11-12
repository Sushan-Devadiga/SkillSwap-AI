import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatService(supabase);
});

class ChatService {
  final SupabaseClient _client;

  ChatService(this._client);

  Future<List<Map<String, dynamic>>> getConversations() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Fetch conversations where current user is a participant
      final response = await _client.from('conversations').select('''
        id,
        created_at,
        participant1_id,
        participant2_id,
        profiles!conversations_participant1_id_fkey(id, username, full_name, avatar_url),
        profiles_2:profiles!conversations_participant2_id_fkey(id, username, full_name, avatar_url),
        messages(content, created_at, sender_id, read_at)
      ''').or('participant1_id.eq.$currentUserId,participant2_id.eq.$currentUserId');
      
      final conversations = List<Map<String, dynamic>>.from(response);
      
      // Format response to make it easy for UI
      final formatted = conversations.map((conv) {
        final isP1 = conv['participant1_id'] == currentUserId;
        final peerProfile = isP1 ? conv['profiles_2'] : conv['profiles'];
        
        final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
        messages.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
        
        final lastMessage = messages.isNotEmpty ? messages.first : null;
        
        return {
          'id': conv['id'],
          'peer': peerProfile,
          'lastMessage': lastMessage,
          'unreadCount': messages.where((m) => m['sender_id'] != currentUserId && m['read_at'] == null).length,
        };
      }).toList();
      
      // Sort by last message time
      formatted.sort((a, b) {
        final aTime = a['lastMessage'] != null ? DateTime.parse(a['lastMessage']['created_at']) : DateTime.parse(a['created_at'] ?? '1970-01-01');
        final bTime = b['lastMessage'] != null ? DateTime.parse(b['lastMessage']['created_at']) : DateTime.parse(b['created_at'] ?? '1970-01-01');
        return bTime.compareTo(aTime);
      });
      
      return formatted;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getConversationByPeerUsername(String peerUsername) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return null;
    
    try {
      // 1. Resolve peer profile by username, id (UUID), or full_name (case-insensitive)
      Map<String, dynamic>? peerResp;
      
      try {
        peerResp = await _client.from('profiles')
            .select('id, username, full_name, avatar_url, bio, experience_level')
            .ilike('username', peerUsername)
            .maybeSingle();
      } catch (_) {}
      
      if (peerResp == null) {
        try {
          peerResp = await _client.from('profiles')
              .select('id, username, full_name, avatar_url, bio, experience_level')
              .eq('id', peerUsername)
              .maybeSingle();
        } catch (_) {}
      }
      
      if (peerResp == null) {
        try {
          peerResp = await _client.from('profiles')
              .select('id, username, full_name, avatar_url, bio, experience_level')
              .ilike('full_name', peerUsername)
              .maybeSingle();
        } catch (_) {}
      }
      
      if (peerResp == null) return null;
      
      final peerId = peerResp['id'] as String;
      
      // 2. Fetch existing conversation
      final convResp = await _client.from('conversations')
          .select('id')
          .or('and(participant1_id.eq.$currentUserId,participant2_id.eq.$peerId),and(participant1_id.eq.$peerId,participant2_id.eq.$currentUserId)')
          .maybeSingle();
      
      if (convResp != null) {
        return {
          'id': convResp['id'],
          'peer': peerResp,
        };
      }
      
      // 3. Auto-create conversation if none exists yet so chat works immediately
      try {
        final newConv = await _client.from('conversations').insert({
          'participant1_id': currentUserId,
          'participant2_id': peerId,
        }).select('id').single();
        
        return {
          'id': newConv['id'],
          'peer': peerResp,
        };
      } catch (e) {
        print('Notice: Auto-creating conversation: $e');
        // Retry fetch in case of race condition
        final retryConv = await _client.from('conversations')
            .select('id')
            .or('and(participant1_id.eq.$currentUserId,participant2_id.eq.$peerId),and(participant1_id.eq.$peerId,participant2_id.eq.$currentUserId)')
            .maybeSingle();
        if (retryConv != null) {
          return {
            'id': retryConv['id'],
            'peer': peerResp,
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting conversation by username: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await _client.from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
        
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'content': content,
      });
      
      // Update conversation updated_at
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }
  
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    try {
      await _client.from('messages').update({
        'read_at': DateTime.now().toIso8601String()
      }).eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .isFilter('read_at', null);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
