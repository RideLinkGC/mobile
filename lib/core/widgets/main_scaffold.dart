import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../services/locale_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
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

  void _showLanguageSheet(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final name =
                LocaleProvider.localeNames[locale.languageCode] ??
                    locale.languageCode;
            final isSelected =
                localeProvider.locale.languageCode == locale.languageCode;
            return ListTile(
              title: Text(name),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _accountMenuDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.primary;
    final isAdmin = context.read<AuthProvider>().user?.role.name == 'admin';

    void closeDrawer() => Navigator.of(context).pop();

    void afterClose(VoidCallback action) {
      closeDrawer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        action();
      });
    }

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            bottom: 16,
          ),
          children: [
            ListTile(
              leading:  Icon(
                Icons.verified_user_outlined,
                color: iconColor
                ),
              title: Text(l10n.verifyIdentity),
              onTap: () => afterClose(() => context.push('/verification')),
            ),
            ListTile(
              leading:  Icon(
                Icons.repeat_rounded,
                color: iconColor,
                ),
              title: Text(l10n.mySubscriptions),
              onTap: () => afterClose(() => context.push('/my-subscriptions')),
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: iconColor,
              ),
              title: Text(l10n.paymentHistory),
              onTap: () => afterClose(() => context.push('/payment-history')),
            ),
            if (isAdmin)
              ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: iconColor,
                ),
                title: const Text('Review documents'),
                onTap: () => afterClose(() => context.push('/admin/documents')),
              ),
            ListTile(
              leading:  Icon(
                Icons.language_outlined,
                color: iconColor,
                ),
              title: Text(l10n.language),
              subtitle: Consumer<LocaleProvider>(
                builder: (ctx, lp, _) => Text(
                  LocaleProvider.localeNames[lp.locale.languageCode] ??
                      lp.locale.languageCode,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ),
              onTap: () => afterClose(() => _showLanguageSheet(context)),
            ),
            ListTile(
              leading: Icon(
                Icons.notifications_outlined,
                color: iconColor,
                ),
              title: Text(l10n.notifications),
              onTap: () => afterClose(() => context.go('/notifications')),
            ),
            Consumer<ThemeProvider>(
              builder: (context, theme, _) {
                return SwitchListTile(
                  secondary: Icon(
                    color: iconColor,
                    theme.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(l10n.darkMode),
                  value: theme.themeMode == ThemeMode.dark,
                  onChanged: (_) => theme.toggleTheme(),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text(
                l10n.logout,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                closeDrawer();
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final isDriver = authProvider.isDriver;
    final unread = notificationProvider.unreadCount;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        );

    final location = GoRouterState.of(context).uri.toString();
    int currentIdx = 0;
    if (isDriver) {
      if (location.startsWith('/driver-active')) {
        currentIdx = 1;
      } else if (location.startsWith('/chat-list')) {
        currentIdx = 2;
      } else if (location.startsWith('/notifications')) {
        currentIdx = 3;
      } else if (location.startsWith('/profile')) {
        currentIdx = 4;
      } else {
        currentIdx = 0;
      }
    } else {
      if (location.startsWith('/chat-list')) {
        currentIdx = 1;
      } else if (location.startsWith('/passenger-bookings')) {
        currentIdx = 2;
      } else if (location.startsWith('/search')) {
        currentIdx = 3;
      } else if (location.startsWith('/profile')) {
        currentIdx = 4;
      } else {
        currentIdx = 0;
      }
    }

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
      setState(() {
        currentIdx = index;
      });
    }

    void onDriverTab(int index) {
      switch (index) {
        case 0:
          context.go('/driver');
          break;
        case 1:
          context.go('/driver-active');
          break;
        case 2:
          context.go('/chat-list');
          break;
        case 3:
          context.go('/notifications');
          break;
        case 4:
          context.go('/profile');
          break;
      }
      setState(() {
        currentIdx = index;
      });
    }

    final items = isDriver
        ? <CurvedNavigationBarItem>[
            CurvedNavigationBarItem(
              label: 'Home',
              labelStyle: labelStyle,
              child: const Icon(Icons.home_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Active',
              labelStyle: labelStyle,
              child: const Icon(Icons.directions,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Chat',
              labelStyle: labelStyle,
              child: const Icon(Icons.chat_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Alerts',
              labelStyle: labelStyle,
              child: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_rounded,
                    color: AppColors.primary, size: 26),
              ),
            ),
            CurvedNavigationBarItem(
              label: 'Profile',
              labelStyle: labelStyle,
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 26),
            ),
          ]
        : <CurvedNavigationBarItem>[
            CurvedNavigationBarItem(
              label: 'Home',
              labelStyle: labelStyle,
              child: const Icon(Icons.home_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Chat',
              labelStyle: labelStyle,
              child: const Icon(Icons.chat_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Bookings',
              labelStyle: labelStyle,
              child: const Icon(Icons.event_note_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Rides',
              labelStyle: labelStyle,
              child: const Icon(Icons.directions_car_rounded,
                  color: AppColors.primary, size: 26),
            ),
            CurvedNavigationBarItem(
              label: 'Profile',
              labelStyle: labelStyle,
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 26),
            ),
          ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _accountMenuDrawer(context),
      body: ShellDrawerScope(
        openDrawer: _openShellDrawer,
        child: widget.child,
      ),
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          index: currentIdx,
          items: items,
          
          color: scheme.surface,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          buttonBackgroundColor: scheme.surface,
          iconPadding: 10,
          height: 72,
          animationDuration: const Duration(milliseconds: 450),
          animationCurve: Curves.easeOutCubic,
          onTap: isDriver ? onDriverTab : onPassengerTab,
        ),
      ),
    );
  }
}
