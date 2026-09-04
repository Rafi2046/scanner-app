import 'package:flutter/material.dart';

/// Modern 2026 dark productivity theme.
abstract final class AppTheme {
  static const Color scaffoldBg = Color(0xFF0F1115);
  static const Color surfaceColor = Color(0xFF181B20);
  static const Color cardColor = Color(0xFF20242B);
  static const Color cardBorder = Color(0xFF2D333D);
  static const Color primaryMint = Color(0xFF00D2A0);
  static const Color primaryTeal = Color(0xFF06B6D4);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryMint,
        secondary: primaryTeal,
        surface: surfaceColor,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  /// Backward-compatibility alias.
  static ThemeData light() => dark();
}
