import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/edge_detect_ops.dart';
import 'package:scanner_app/services/scan_enhance_ops.dart';

/// Applies document filters and image rotation off the UI isolate.
class ScanEnhanceService {
  const ScanEnhanceService();

  /// Returns a new JPEG path with [filterType] applied (Original returns original path).
  /// Executed strictly inside an isolate to prevent UI thread blocking.
  Future<String> applyFilter({
    required String imagePath,
    ScanFilter? filterType,
    ScanFilter? filter,
  }) async {
    final ScanFilter target = filterType ?? filter ?? ScanFilter.magicEnhance;

    if (imagePath.isEmpty) {
      throw const ScannerException('No image path for enhance.');
    }
    final File input = File(imagePath);
    if (!await input.exists()) {
      throw ScannerException('Enhance source missing: $imagePath');
    }

    // Original returns perspective-warped image directly without copying
    if (target == ScanFilter.original) {
      return imagePath;
    }

    try {
      final Directory cache = await getTemporaryDirectory();
      final String outPath = p.join(
        cache.path,
        'scan_fx_${target.name}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      try {
        // High performance native OpenCV processing inside Isolate.run
        return await Isolate.run(
          () => applyScanFilterFastSync(
            (
              inputPath: imagePath,
              outputPath: outPath,
              filterName: target.name,
            ),
          ),
        );
      } catch (_) {
        // Safe fallback: Pure Dart image package inside Isolate.run
        final Uint8List bytes = await input.readAsBytes();
        final Uint8List jpeg = await Isolate.run(
          () => applyScanFilterIsolate(
            (
              bytes: bytes,
              filterName: target.name,
              quality: AppConstants.scanJpegQuality,
            ),
          ),
        );
        await File(outPath).writeAsBytes(jpeg, flush: true);
        return outPath;
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Failed to apply filter.', cause: error);
    }
  }

  /// Rotates [imagePath] by [angle] degrees (e.g. -90 for left rotate).
  Future<String> rotateImage({
    required String imagePath,
    required int angle,
  }) async {
    if (imagePath.isEmpty || !File(imagePath).existsSync()) {
      throw ScannerException('Rotate source missing: $imagePath');
    }
    try {
      final Directory cache = await getTemporaryDirectory();
      final String outPath = p.join(
        cache.path,
        'scan_rot_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      try {
        return await Isolate.run(
          () => rotateImageFastSync(
            (
              inputPath: imagePath,
              outputPath: outPath,
              angle: angle,
            ),
          ),
        );
      } catch (_) {
        final Uint8List bytes = await File(imagePath).readAsBytes();
        final Uint8List jpeg = await Isolate.run(
          () => rotateJpegBytesIsolate(
            (
              bytes: bytes,
              angle: angle,
              quality: AppConstants.scanJpegQuality,
            ),
          ),
        );
        await File(outPath).writeAsBytes(jpeg, flush: true);
        return outPath;
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Failed to rotate image.', cause: error);
    }
  }
}
