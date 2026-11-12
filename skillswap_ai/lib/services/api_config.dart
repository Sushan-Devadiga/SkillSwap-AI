import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Resolves the backend base URL dynamically depending on whether the app is running on Web,
  /// an Android emulator, or a physical mobile device.
  static String get baseUrl {
    // 1. Allow explicit override via --dart-define=BACKEND_URL=http://192.168.1.X:8000
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 2. Web / Desktop use localhost loopback
    if (kIsWeb) return 'http://127.0.0.1:8000';

    // 3. Android Emulator routes host loopback through 10.0.2.2
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}

    return 'http://127.0.0.1:8000';
  }

  static String get apiUrl => '$baseUrl/api';
}

