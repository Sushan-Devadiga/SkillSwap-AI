import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_config.dart';

class AIService {
  static String get baseUrl => ApiConfig.apiUrl;

  Future<Map<String, dynamic>> extractOnboardingSkills(String description) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception("Not logged in");

    final response = await http.post(
      Uri.parse('$baseUrl/onboarding/extract'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'description': description}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to extract skills: ${response.body}');
    }
  }
}
