/// App-wide path and limit constants.
abstract final class AppConstants {
  static const String scansDirName = 'scans';
  static const String idCardsDirName = 'id_cards';
  static const String importsDirName = 'imports';
  static const String toolsDirName = 'tools';
  static const String foldersDirName = 'folders';
  static const String indexFileName = 'library_index.json';

  /// Max pages for a multi-page document scan session.
  static const int documentPageLimit = 20;

  /// ID card scan: one page per side.
  static const int idCardPageLimit = 1;

  /// Default PDF page margins in points (1/72 inch).
  static const double pdfMarginPoints = 36;

  static const String biometricLockPrefsKey = 'biometric_lock_enabled';

  /// JPEG quality used when compressing rasterized PDF pages.
  static const int compressJpegQuality = 40;

  /// Longest edge in pixels for compressed/rebuild pages.
  static const int compressMaxEdge = 1280;
}
