import 'package:flutter/material.dart';

/// Exposes the shell [Scaffold] drawer to nested routes that use their own
/// [Scaffold] (so [Scaffold.of] would otherwise target the inner scaffold).
class ShellDrawerScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const ShellDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static ShellDrawerScope? _maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellDrawerScope>();
  }

  /// Opens the shell drawer if this scope is present (main tab shell).
  static void open(BuildContext context) {
    _maybeOf(context)?.openDrawer();
  }

  @override
  bool updateShouldNotify(covariant ShellDrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

/// Opens the shell drawer; use as [AppBar.leading] on main-tab screens.
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: () => ShellDrawerScope.open(context),
    );
  }
}
