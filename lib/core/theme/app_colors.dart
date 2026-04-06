import 'package:flutter/material.dart';

/// Design tokens (light-first). Map layers use [primaryHex] / [primaryMapHex].
class AppColors {
  AppColors._();

  // —— User tokens ——
  /// --text
  static const Color textPrimaryLight = Color(0xFF0C0E0E);
  /// --background
  static const Color lightBackground = Color(0xFFF6F8F8);
  /// --primary
  static const Color primary = Color(0xFF0CCFED);
  /// --secondary
  static const Color secondary = Color(0xFFAFD0CE);
  /// --accent
  static const Color accent = Color(0xFF74BEB9);

  // —— Derived (primary) ——
  static const Color primaryLight = Color(0xFF5BDDF5);
  static const Color primaryDark = Color(0xFF0AA4BD);

  // —— Derived (secondary) ——
  static const Color secondaryLight = Color(0xFFC9E3E1);
  static const Color secondaryDark = Color(0xFF8FBFBC);

  // —— Surfaces (light) ——
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFDDE8E7);

  // —— Text (light) ——
  static const Color textSecondaryLight = Color(0xFF4A5857);
  static const Color textHintLight = Color(0xFF8FA3A1);

  // —— Dark theme (harmonized with palette, not in original spec) ——
  static const Color darkBackground = Color(0xFF0C1011);
  static const Color darkSurface = Color(0xFF141A1B);
  static const Color darkCard = Color(0xFF1A2223);
  static const Color darkDivider = Color(0xFF2A3435);

  static const Color textPrimaryDark = Color(0xFFEEF1F1);
  static const Color textSecondaryDark = Color(0xFF9DB5B3);
  static const Color textHintDark = Color(0xFF6D8280);

  // —— Semantic ——
  static const Color success = Color(0xFF43A048);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFB8A00);
  static const Color info = primary;

  /// Stars stay warm for contrast on cool primaries.
  static const Color ratingStar = Color(0xFFFFB020);
  static const Color sosRed = Color(0xFFD32F2F);

  /// `#RRGGBB` for Gebeta / map polylines.
  static const String primaryMapHex = '#0CCFED';
}
