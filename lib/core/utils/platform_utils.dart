import 'dart:io';

/// Platform checks used by scanner and camera features.
abstract final class PlatformUtils {
  static bool get isAndroid => Platform.isAndroid;

  static bool get supportsDocumentScanner => Platform.isAndroid;
}
