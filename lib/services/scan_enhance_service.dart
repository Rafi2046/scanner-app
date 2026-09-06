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

/// Applies CamScanner-grade document enhancements and image rotations off the UI isolate.
///
/// Features a high-performance dual-engine pipeline:
/// 1. Primary Engine: Native OpenCV C++ FFI (`opencv_dart`) executing inside [Isolate.run].
/// 2. Secondary Engine: Pure-Dart matrix operations (`image` package) fallback inside [Isolate.run].
class ScanEnhanceService {
  const ScanEnhanceService();

  /// Reads [sourceImagePath], applies the requested mathematical document enhancement [filter],
  /// saves the resulting image to a new temporary file in the cache directory, and returns the new file path.
  ///
  /// Mathematical execution is strictly offloaded to [Isolate.run] to guarantee
  /// 0 dropped frames or UI thread freezes during intensive matrix operations.
  ///
  /// Enhancement Techniques:
  /// - [ScanFilter.magicEnhance]: Optical background illumination division removes paper shadows and creases,
  ///   followed by contrast stretching, HSV saturation boost (+25%), and an unsharp mask filter to sharpen blurry text.
  /// - [ScanFilter.bwPrint] / [ScanFilter.bw]: Grayscale conversion, optical illumination flattening,
  ///   sensor noise suppression, and Gaussian C adaptive thresholding for pure black text on pure white paper.
  /// - [ScanFilter.grayscale]: Illumination normalization with moderate contrast bump and subtle sharpening,
  ///   preserving continuous-tone photos, seals, and stamps.
  /// - [ScanFilter.original]: Direct passthrough without re-encoding.
  Future<String> applyFilter(
    String sourceImagePath, [
    ScanFilter filter = ScanFilter.magicEnhance,
    bool forIdCard = false,
  ]) async {
    if (sourceImagePath.isEmpty) {
      throw const ScannerException('No image path provided for enhancement.');
    }
    final File input = File(sourceImagePath);
    if (!await input.exists()) {
      throw ScannerException('Enhancement source file missing: $sourceImagePath');
    }

    // Original returns the source perspective-warped image directly without re-encoding
    if (filter == ScanFilter.original) {
      return sourceImagePath;
    }

    final String profile = forIdCard ? 'idCard' : 'document';

    try {
      final Directory cache = await getTemporaryDirectory();
      final String outPath = p.join(
        cache.path,
        'scan_fx_${filter.name}_${profile}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      try {
        // 1. Primary Engine: Blazing-fast native OpenCV C++ FFI in background Isolate
        return await Isolate.run(
          () => applyScanFilterFastSync(
            (
              inputPath: sourceImagePath,
              outputPath: outPath,
              filterName: filter.name,
              profile: profile,
            ),
          ),
        );
      } catch (_) {
        // 2. Fallback Engine: Pure-Dart matrix image pipeline in background Isolate
        final Uint8List bytes = await input.readAsBytes();
        final Uint8List jpeg = await Isolate.run(
          () => applyScanFilterIsolate(
            (
              bytes: bytes,
              filterName: filter.name,
              quality: AppConstants.scanJpegQuality,
              forIdCard: forIdCard,
            ),
          ),
        );
        await File(outPath).writeAsBytes(jpeg, flush: true);
        return outPath;
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException(
        'Failed to apply filter ${filter.name} on $sourceImagePath.',
        cause: error,
      );
    }
  }

  /// Named-parameter convenience adapter for backward compatibility.
  Future<String> applyFilterNamed({
    required String imagePath,
    ScanFilter? filterType,
    ScanFilter? filter,
  }) =>
      applyFilter(imagePath, filterType ?? filter ?? ScanFilter.magicEnhance);

  /// Rotates [imagePath] by [angle] degrees (e.g. -90, 90, 180).
  ///
  /// Executed strictly inside [Isolate.run] to prevent UI stutter.
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
        // Fast native OpenCV rotation
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
        // Fallback pure Dart rotation
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
