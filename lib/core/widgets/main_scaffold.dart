import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'connection_status_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/passenger') || location.startsWith('/driver')) {
      return 0;
    }
    if (location.startsWith('/chat-list')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDriver = authProvider.isDriver;
    final currentIdx = _currentIndex(context);

    return Scaffold(
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(isDriver ? '/driver' : '/passenger');
              break;
            case 1:
              context.go('/chat-list');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined,
                color: currentIdx == 0 ? AppColors.primary : AppColors.textHintLight),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline,
                color: currentIdx == 1 ? AppColors.primary : AppColors.textHintLight),
            selectedIcon: const Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline,
                color: currentIdx == 2 ? AppColors.primary : AppColors.textHintLight),
            selectedIcon: const Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
