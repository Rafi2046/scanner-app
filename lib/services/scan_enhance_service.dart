import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/scan_enhance_ops.dart';

/// Applies document filters off the UI isolate.
class ScanEnhanceService {
  const ScanEnhanceService();

  /// Returns a new JPEG path with [filter] applied (Original may copy).
  Future<String> applyFilter({
    required String imagePath,
    required ScanFilter filter,
  }) async {
    if (imagePath.isEmpty) {
      throw const ScannerException('No image path for enhance.');
    }
    final File input = File(imagePath);
    if (!await input.exists()) {
      throw ScannerException('Enhance source missing: $imagePath');
    }

    if (filter == ScanFilter.original) {
      return imagePath;
    }

    try {
      final Uint8List bytes = await input.readAsBytes();
      final Uint8List jpeg = await Isolate.run(
        () => applyScanFilterIsolate(
          (
            bytes: bytes,
            filterName: filter.name,
            quality: AppConstants.scanJpegQuality,
          ),
        ),
      );

      final Directory cache = await getTemporaryDirectory();
      final String outPath = p.join(
        cache.path,
        'scan_fx_${filter.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(outPath).writeAsBytes(jpeg, flush: true);
      return outPath;
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Failed to apply filter.', cause: error);
    }
  }
}
