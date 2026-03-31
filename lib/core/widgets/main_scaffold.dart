import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../theme/app_colors.dart';
import 'connection_status_bar.dart';
import 'shell_drawer_scope.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openShellDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  int _shellIndex(BuildContext context, bool isDriver) {
    final location = GoRouterState.of(context).matchedLocation;
    if (isDriver) {
      if (location.startsWith('/passenger') || location.startsWith('/driver')) {
        return 0;
      }
      if (location.startsWith('/chat-list')) return 1;
      if (location.startsWith('/notifications')) return 2;
      if (location.startsWith('/profile')) return 3;
      return 0;
    }
    if (location.startsWith('/passenger')) return 0;
    if (location.startsWith('/chat-list')) return 1;
    if (location.startsWith('/passenger-bookings')) return 2;
    if (location.startsWith('/search')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  Widget _passengerDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 16,
          bottom: 16,
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => go('/passenger'),
          ),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Bookings'),
            onTap: () => go('/passenger-bookings'),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('Rides'),
            onTap: () => go('/search'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat'),
            onTap: () => go('/chat-list'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _driverDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 16,
          bottom: 16,
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => go('/driver'),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat'),
            onTap: () => go('/chat-list'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Alerts'),
            onTap: () => go('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => go('/profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final isDriver = authProvider.isDriver;
    final currentIdx = _shellIndex(context, isDriver);
    final unread = notificationProvider.unreadCount;
    final scheme = Theme.of(context).colorScheme;
    Color navIconColor(bool selected) => selected
        ? AppColors.primary
        : scheme.onSurface.withValues(alpha: 0.48);

    void onPassengerTab(int index) {
      switch (index) {
        case 0:
          context.go('/passenger');
          break;
        case 1:
          context.go('/chat-list');
          break;
        case 2:
          context.go('/passenger-bookings');
          break;
        case 3:
          context.go('/search');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }

    void onDriverTab(int index) {
      switch (index) {
        case 0:
          context.go('/driver');
          break;
        case 1:
          context.go('/chat-list');
          break;
        case 2:
          context.go('/notifications');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    }

    final destinations = isDriver
        ? <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: navIconColor(currentIdx == 0)),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline,
                  color: navIconColor(currentIdx == 1)),
              selectedIcon:
                  const Icon(Icons.chat_bubble, color: AppColors.primary),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: Icon(Icons.notifications_outlined,
                    color: navIconColor(currentIdx == 2)),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child:
                    const Icon(Icons.notifications, color: AppColors.primary),
              ),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: navIconColor(currentIdx == 3)),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ]
        : <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined,
                  color: navIconColor(currentIdx == 0)),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline,
                  color: navIconColor(currentIdx == 1)),
              selectedIcon:
                  const Icon(Icons.chat_bubble, color: AppColors.primary),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined,
                  color: navIconColor(currentIdx == 2)),
              selectedIcon:
                  const Icon(Icons.event_note, color: AppColors.primary),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car_outlined,
                  color: navIconColor(currentIdx == 3)),
              selectedIcon:
                  const Icon(Icons.directions_car, color: AppColors.primary),
              label: 'Rides',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                  color: navIconColor(currentIdx == 4)),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDriver ? _driverDrawer(context) : _passengerDrawer(context),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: ShellDrawerScope(
              openDrawer: _openShellDrawer,
              child: widget.child,
            ),
          ),
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
        onDestinationSelected:
            isDriver ? onDriverTab : onPassengerTab,
        destinations: destinations,
      ),
    );
  }
}
