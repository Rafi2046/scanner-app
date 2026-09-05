/// App-wide storage, limits, and UI design tokens.
abstract final class AppConstants {
  // --- Brand ---
  static const String appName = 'Scanner';

  // --- Storage ---
  static const String scansDirName = 'scans';
  static const String idCardsDirName = 'id_cards';
  static const String importsDirName = 'imports';
  static const String toolsDirName = 'tools';
  static const String foldersDirName = 'folders';
  static const String indexFileName = 'library_index.json';

  // --- Scan / PDF ---
  static const int documentPageLimit = 20;
  static const int idCardPageLimit = 1;
  static const double pdfMarginPoints = 36;
  static const String biometricLockPrefsKey = 'biometric_lock_enabled';
  static const int compressJpegQuality = 40;
  static const int compressMaxEdge = 1280;

  /// Max width/height after capture before edge detect / filters (OOM guard).
  static const int scanMaxEdge = 1920;
  static const int scanJpegQuality = 90;

  // --- Layout spacing ---
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double spaceXxl = 24;
  static const double pagePadding = 18;
  static const double bottomNavClearance = 100;

  // --- Radii ---
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 28;

  // --- Component sizes ---
  static const double toolCircleSize = 32;
  static const double toolIconSize = 16;
  static const double thumbWidth = 52;
  static const double thumbHeight = 64;
  static const double fabSize = 58;
  static const double bottomBarHeight = 64;
  static const double logoSize = 36;
}
