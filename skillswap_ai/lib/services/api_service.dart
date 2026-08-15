import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class MatchModel {
  final String userId;
  final String? username;
  final String fullName;
  final String? avatarUrl;
  final String skillName;
  final double similarity;
  final String explanation;
  final String suggestions;

  MatchModel({
    required this.userId,
    this.username,
    required this.fullName,
    this.avatarUrl,
    required this.skillName,
    required this.similarity,
    required this.explanation,
    this.suggestions = '',
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      skillName: json['skill_name'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      explanation: json['explanation'] as String? ?? 'A great match for you.',
      suggestions: json['suggestions'] as String? ?? '',
    );
  }
}

class ApiService {
  final AuthService _authService;
  // Use 127.0.0.1 for Windows Desktop apps. For Android Emulator use 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000';

  ApiService(this._authService);

  Future<List<MatchModel>> getMatches() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/match'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': user.id,
          'limit': 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matchesList = data['matches'] as List;
        return matchesList.map((m) => MatchModel.fromJson(m)).toList();
      } else {
        throw Exception('Failed to load matches');
      }
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }
}

final matchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMatches();
});
