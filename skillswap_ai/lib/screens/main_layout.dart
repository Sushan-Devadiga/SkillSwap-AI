import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'chat_list_screen.dart';
import 'learning_progress_screen.dart';
import 'profile_view_screen.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    DiscoverScreen(),
    LearningProgressScreen(),
    ChatListScreen(),
    ProfileViewScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allows body to go under the floating nav
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: _screens[currentIndex],
        ),
      ),
      floatingActionButton: Tooltip(
        message: 'Ask SkillSwap AI',
        child: Container(
          margin: const EdgeInsets.only(bottom: 80),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => context.push('/ai'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.92) : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(31),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, LucideIcons.home, currentIndex, ref),
                        _buildNavItem(1, LucideIcons.search, currentIndex, ref),
                        _buildNavItem(2, LucideIcons.bookOpen, currentIndex, ref),
                        _buildNavItem(3, LucideIcons.messageSquare, currentIndex, ref),
                        _buildNavItem(4, LucideIcons.user, currentIndex, ref),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, int currentIndex, WidgetRef ref) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(mainNavIndexProvider.notifier).setIndex(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant.withOpacity(0.6),
        ),
      ),
    );
  }
}
