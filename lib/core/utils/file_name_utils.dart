import 'package:intl/intl.dart';

/// Helpers for generating unique, human-readable file names.
abstract final class FileNameUtils {
  static final DateFormat _stampFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Example: `doc_20260304_143022` or `doc_20260304_143022_a1b2`.
  static String stamped(String prefix, {String? suffix}) {
    final String stamp = _stampFormat.format(DateTime.now());
    if (suffix == null || suffix.isEmpty) {
      return '${prefix}_$stamp';
    }
    return '${prefix}_${stamp}_$suffix';
  }

  static String withExtension(String baseName, String extension) {
    final String ext = extension.startsWith('.') ? extension : '.$extension';
    return '$baseName$ext';
  }
}
