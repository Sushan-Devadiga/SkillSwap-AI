import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'theme/app_theme.dart';
import 'router.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Firebase and background messaging handler on mobile platforms
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  runApp(const ProviderScope(child: SkillSwapApp()));
}

class SkillSwapApp extends ConsumerStatefulWidget {
  const SkillSwapApp({super.key});

  @override
  ConsumerState<SkillSwapApp> createState() => _SkillSwapAppState();
}

class _SkillSwapAppState extends ConsumerState<SkillSwapApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  void _initNotifications() {
    final router = ref.read(routerProvider);
    ref.read(notificationServiceProvider).initializeFCM(
      onNavigate: (route) => router.push(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SkillSwap AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

