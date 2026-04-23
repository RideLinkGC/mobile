import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/core/widgets/shell_drawer_scope.dart';

  AppBar driverAppBarWitDrawer(BuildContext context, String title, bool hasDrawer) {
 
    return AppBar(
      leading: hasDrawer ? ShellMenuButton(
        color: Colors.white,
      ) : null,
      title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
      backgroundColor: Colors.blue,
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_rounded,
          color: Colors.white,
          ),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  
}

