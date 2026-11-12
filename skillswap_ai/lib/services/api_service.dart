import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'api_config.dart';

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
  final int learningStyleScore;
  final int timezoneScore;
  final int proficiencyScore;
  final int feedbackScore;

  MatchModel({
    required this.userId,
    this.username,
    required this.fullName,
    this.avatarUrl,
    required this.skillName,
    required this.similarity,
    required this.explanation,
    this.suggestions = '',
    this.learningStyleScore = 92,
    this.timezoneScore = 95,
    this.proficiencyScore = 88,
    this.feedbackScore = 94,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final dim = json['dimension_scores'] as Map<String, dynamic>? ?? {};
    return MatchModel(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      skillName: json['skill_name'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      explanation: json['explanation'] as String? ?? 'A great match for you.',
      suggestions: json['suggestions'] as String? ?? '',
      learningStyleScore: (dim['learning_style'] as num?)?.toInt() ?? 92,
      timezoneScore: (dim['timezone_alignment'] as num?)?.toInt() ?? 95,
      proficiencyScore: (dim['proficiency_balance'] as num?)?.toInt() ?? 88,
      feedbackScore: (dim['feedback_rating'] as num?)?.toInt() ?? 94,
    );
  }
}

class ApiService {
  final AuthService _authService;
  static String get baseUrl => ApiConfig.baseUrl;

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
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matchesList = data['matches'] as List;
        return matchesList.map((m) => MatchModel.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print('Notice fetching AI matches: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSessionPlan(String matchId) async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      final response = await http.post(
        Uri.parse('$baseUrl/api/session/plan'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'match_id': matchId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final curriculum = data['curriculum'] as List?;
        if (curriculum != null) {
          return List<Map<String, dynamic>>.from(curriculum);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching session plan: $e');
      return [];
    }
  }
}

final matchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMatches();
});
