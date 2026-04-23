import 'package:flutter/material.dart';

/// Design tokens (light-first). Map layers use [primaryHex] / [primaryMapHex].
class AppColors {
  AppColors._();

  // —— User tokens ——
  /// --text
  /// 
  static const Color testColor = Color.fromARGB(255, 28, 141, 233);
  static const Color textPrimaryLight = Color(0xFF0C0E0E);
  /// --background
  static const Color lightBackground = Color(0xFFF6F8F8);
  /// --primary
  static const Color primary = Color.fromARGB(255, 28, 141, 233);
  /// --secondary
  static const Color secondary = Color.fromARGB(255, 175, 208, 206);
  /// --accent
  static const Color accent = Color.fromARGB(255, 116, 190, 185);

  // —— Derived (primary) ——
  static const Color primaryLight = Color.fromARGB(255, 91, 221, 245);
  static const Color primaryDark = Color.fromARGB(255, 10, 164, 189);

  // —— Derived (secondary) ——
  static const Color secondaryLight = Color.fromARGB(255, 201, 227, 225);
  static const Color secondaryDark = Color.fromARGB(255, 143, 191, 188);

  // —— Surfaces (light) ——
    static const Color lightSurface = Color.fromARGB(255, 255, 255, 255);
  static const Color lightCard = Color.fromARGB(255, 255, 255, 255);
  static const Color lightDivider = Color.fromARGB(255, 221, 232, 231);

  // —— Text (light) ——
  static const Color textSecondaryLight = Color.fromARGB(255, 74, 88, 87);
  static const Color textHintLight = Color.fromARGB(255, 143, 163, 161);

  // —— Dark theme (harmonized with palette, not in original spec) ——
  static const Color darkBackground = Color.fromARGB(255, 12, 16, 17);
  static const Color darkSurface = Color(0xFF141A1B);
  static const Color darkCard = Color(0xFF1A2223);
  static const Color darkDivider = Color.fromARGB(255, 42, 52, 53);

  static const Color textPrimaryDark = Color.fromARGB(255, 238, 241, 241);
  static const Color textSecondaryDark = Color(0xFF9DB5B3);
  static const Color textHintDark = Color.fromARGB(255, 109, 130, 128);

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
