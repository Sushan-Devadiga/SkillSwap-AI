import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/connectivity_service.dart';

/// A banner widget that automatically observes network connectivity.
/// Displays a red warning bar at the top whenever the device loses internet access.
class OfflineBanner extends ConsumerWidget {
  final Widget? child;

  const OfflineBanner({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;

    if (isOnline) {
      return child ?? const SizedBox.shrink();
    }

    final banner = SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFDC2626), // Error Red
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'No internet connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (child == null) {
      return banner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        Expanded(child: child!),
      ],
    );
  }
}
