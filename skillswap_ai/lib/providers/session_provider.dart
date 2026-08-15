import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';

final activeSwapsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return await sessionService.getUpcomingSessions();
});

final completedSkillsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return await sessionService.getCompletedExchanges();
});
