import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Stream of connectivity results from connectivity_plus
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged;
});

/// Boolean provider indicating whether the device currently has active network connectivity
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  
  // Initial network check
  final initialStatus = await connectivity.checkConnectivity();
  yield initialStatus.any((r) => r != ConnectivityResult.none);

  // Stream changes when connection status transitions
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.any((r) => r != ConnectivityResult.none);
  }
});
