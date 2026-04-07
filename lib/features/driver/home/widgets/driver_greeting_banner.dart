import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

String driverGreetingForNow(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 21) return 'Good evening';
  return 'Welcome back';
}

class DriverGreetingBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onDismiss;

  const DriverGreetingBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              scheme.surfaceContainerHighest.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.16 : 0.28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

