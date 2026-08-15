import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/main_layout.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/teaching_skills_screen.dart';
import 'screens/learning_skills_screen.dart';
import 'screens/proficiency_screen.dart';
import 'screens/learning_goals_screen.dart';
import 'screens/availability_screen.dart';
import 'screens/profile_preview_screen.dart';
import 'screens/public_profile_screen.dart';
import 'screens/match_details_screen.dart';
import 'screens/swap_request_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/schedule_session_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/auth_service.dart';
import 'providers/profile_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(userProfileProvider, (_, __) => notifier.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authStateAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(userProfileProvider);
      
      if (authStateAsync.isLoading) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignup = state.matchedLocation == '/signup';
      final isSplash = state.matchedLocation == '/';
      
      final onboardingRoutes = [
        '/profile-setup', '/teaching-skills', '/learning-skills', 
        '/proficiency', '/learning-goals', '/availability', '/profile-preview'
      ];
      final isGoingToOnboarding = onboardingRoutes.contains(state.matchedLocation);

      if (isSplash) return null;

      if (!isAuth && !isGoingToLogin && !isGoingToSignup) {
        return '/login';
      }

      if (isAuth) {
         if (profileAsync.isLoading) return null;
         
         final isProfileComplete = profileAsync.value?.isComplete ?? false;

         if (!isProfileComplete && !isGoingToOnboarding) {
           return '/profile-setup';
         }

         if (isProfileComplete && (isGoingToLogin || isGoingToSignup || isSplash || isGoingToOnboarding)) {
           return '/home';
         }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/teaching-skills',
        builder: (context, state) => const TeachingSkillsScreen(),
      ),
      GoRoute(
        path: '/learning-skills',
        builder: (context, state) => const LearningSkillsScreen(),
      ),
      GoRoute(
        path: '/proficiency',
        builder: (context, state) => const ProficiencyScreen(),
      ),
      GoRoute(
        path: '/learning-goals',
        builder: (context, state) => const LearningGoalsScreen(),
      ),
      GoRoute(
        path: '/availability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/profile-preview',
        builder: (context, state) => const ProfilePreviewScreen(),
      ),
      GoRoute(
        path: '/profile/:username',
        builder: (context, state) {
          return PublicProfileScreen(username: state.pathParameters['username']!);
        },
      ),
      GoRoute(
        path: '/match',
        builder: (context, state) {
          return MatchDetailsScreen(
            userId: state.uri.queryParameters['id'] ?? '',
            fullName: state.uri.queryParameters['name'] ?? '',
            skillName: state.uri.queryParameters['skill'] ?? '',
            similarity: state.uri.queryParameters['similarity'] ?? '0',
            avatarUrl: state.uri.queryParameters['avatar'],
          );
        },
      ),
      GoRoute(
        path: '/swap-request/:userId',
        builder: (context, state) {
          return SwapRequestScreen(userId: state.pathParameters['userId']!);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:peerName',
        builder: (context, state) {
          return ChatScreen(peerName: state.pathParameters['peerName']!);
        },
      ),
      GoRoute(
        path: '/schedule/:peerName',
        builder: (context, state) {
          return ScheduleSessionScreen(peerName: state.pathParameters['peerName']!);
        },
      ),
      GoRoute(
        path: '/ai',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
