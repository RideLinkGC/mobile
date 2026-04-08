
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/core/widgets/shell_drawer_scope.dart';

AppBar passengerAppBar(BuildContext context, String title) {
 
    return AppBar(
      leading:  ShellMenuButton(
        color: Theme.of(context).colorScheme.primaryFixedDim.withAlpha(200),
      ),
      title: Text(title),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_rounded,
          color: Theme.of(context).colorScheme.primaryFixedDim.withAlpha(200),
          ),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  
}