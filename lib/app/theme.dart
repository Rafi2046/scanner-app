import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Clean light theme (ProScan-inspired, not a copy).
abstract final class AppTheme {
  static const Color scaffoldBg = Color(0xFFF7F8FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8EAED);
  static const Color primary = Color(0xFF3B6FF5);
  static const Color primarySoft = Color(0xFFE8EEFE);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color danger = Color(0xFFEF4444);

  // Pastel tool accents (distinct from reference apps).
  static const Color accentOrange = Color(0xFFFF8A3D);
  static const Color accentBrown = Color(0xFFB45309);
  static const Color accentRed = Color(0xFFFF5A5F);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);

  /// Alias used by older widgets.
  static const Color primaryMint = primary;
  static const Color primaryTeal = Color(0xFF2563EB);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: surfaceColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),
      dividerColor: cardBorder,
    );
  }

  /// Dark scan surfaces (camera / preview shells).
  static ThemeData darkScan() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF12141A),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: Color(0xFF1A1D24),
      ),
    );
  }
}
