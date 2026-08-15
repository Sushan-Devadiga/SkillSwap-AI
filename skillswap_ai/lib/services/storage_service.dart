import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StorageService(supabase);
});

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String?> uploadAvatar(XFile file, String userId) async {
    try {
      final fileExt = file.name.split('.').last;
      final fileName = 'profile.$fileExt';
      final filePath = '$userId/$fileName';
      
      final bytes = await file.readAsBytes();

      await _client.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: file.mimeType ?? 'image/$fileExt',
        ),
      );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      
      // Update the profile table
      await _client.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', userId);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  Future<bool> deleteAvatar(String userId) async {
    try {
      // We don't necessarily know the exact extension, so we could list files in the folder and delete them
      final files = await _client.storage.from('avatars').list(path: userId);
      if (files.isNotEmpty) {
        final pathsToDelete = files.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from('avatars').remove(pathsToDelete);
      }
      
      // Clear from profile
      await _client.from('profiles').update({
        'avatar_url': null,
      }).eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error deleting avatar: $e');
      return false;
    }
  }
}
