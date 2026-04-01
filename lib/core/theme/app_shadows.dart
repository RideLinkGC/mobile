import 'package:flutter/material.dart';

/// Shared elevation for surfaces — prefer this over hairline borders on cards.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> softCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0x14000000),
        blurRadius: 14,
        offset: const Offset(0, 4),
      ),
    ];
  }
  static List<BoxShadow> myShadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: dark
            ? const Color.fromARGB(255, 187, 184, 184).withValues(alpha: 0.45)
            : const Color(0x14000000),
        blurRadius: 2,
        spreadRadius: 1
      ),
    ];
  }

  /// Slightly stronger — pills / chips floating on content.
  static List<BoxShadow> softElevated(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0x18000000),
        blurRadius: 5,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
