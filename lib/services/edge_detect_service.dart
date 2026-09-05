import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/services/edge_detect_ops.dart';

/// Document edge detection + perspective warp via OpenCV (isolate-backed).
class EdgeDetectService {
  const EdgeDetectService();

  /// Detects a document quad from the **still photo** (OpenCV).
  ///
  /// [liveQuad] is only a fallback if OpenCV finds nothing — preview quads are
  /// often too loose and would keep background objects in the crop.
  Future<ScanQuad> detectCorners(String imagePath, {ScanQuad? liveQuad}) async {
    if (imagePath.isEmpty) {
      throw const ScannerException('No image path for edge detection.');
    }
    if (!File(imagePath).existsSync()) {
      throw ScannerException('Image missing for edge detection: $imagePath');
    }

    try {
      final DetectCornersResult result = await Isolate.run(
        () => detectCornersSync(imagePath),
      );
      return ScanQuad.fromFlat(result.flat);
    } on AppException {
      rethrow;
    } catch (_) {
      if (liveQuad != null) {
        try {
          final Uint8List bytes = await File(imagePath).readAsBytes();
          final img.Image? decoded =
              await Isolate.run(() => img.decodeImage(bytes));
          if (decoded != null) {
            return ScanQuad.fromNormalized(
              liveQuad,
              decoded.width,
              decoded.height,
            );
          }
        } catch (_) {}
      }
      final ScanQuad? fallback = await _insetFromImage(imagePath);
      if (fallback != null) {
        return fallback;
      }
      throw const ScannerException('Edge detection failed.');
    }
  }

  /// Perspective-warps [imagePath] using [quad]; returns JPEG path.
  Future<String> warp({
    required String imagePath,
    required ScanQuad quad,
  }) async {
    if (imagePath.isEmpty) {
      throw const ScannerException('No image path for warp.');
    }

    final Directory cache = await getTemporaryDirectory();
    final String outputPath = p.join(
      cache.path,
      'scan_warp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    try {
      return await Isolate.run(
        () => warpPerspectiveSync(
          (
            path: imagePath,
            flat: quad.toFlat(),
            outputPath: outputPath,
          ),
        ),
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Perspective warp failed.', cause: error);
    }
  }

  Future<ScanQuad?> _insetFromImage(String path) async {
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      final img.Image? decoded = await Isolate.run(() => img.decodeImage(bytes));
      if (decoded == null) {
        return null;
      }
      return ScanQuad.insetRect(
        width: decoded.width,
        height: decoded.height,
        insetFraction: 0.12,
      );
    } catch (_) {
      return null;
    }
  }
}
