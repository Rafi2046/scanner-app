import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';

/// Isolate entry: downscale [bytes] so max edge ≤ [maxEdge], return JPEG bytes.
/// Throws [StateError] inside the isolate (Sendable).
Uint8List downscaleJpegBytesIsolate(({
  Uint8List bytes,
  int maxEdge,
  int quality,
}) args) {
  final img.Image? decoded = img.decodeImage(args.bytes);
  if (decoded == null) {
    throw StateError('Could not decode image for downscale.');
  }

  final int maxSide =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final img.Image sized;
  if (maxSide <= args.maxEdge) {
    sized = decoded;
  } else {
    final double scale = args.maxEdge / maxSide;
    sized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round().clamp(1, args.maxEdge),
      height: (decoded.height * scale).round().clamp(1, args.maxEdge),
      interpolation: img.Interpolation.linear,
    );
  }

  return Uint8List.fromList(
    img.encodeJpg(sized, quality: args.quality),
  );
}

/// Reads [inputPath], downscales in an isolate, writes JPEG to [outputPath].
Future<String> downscaleImageFile({
  required String inputPath,
  required String outputPath,
  int maxEdge = AppConstants.scanMaxEdge,
  int quality = AppConstants.scanJpegQuality,
}) async {
  final File input = File(inputPath);
  if (!await input.exists()) {
    throw ScannerException('Image file missing: $inputPath');
  }

  final Uint8List bytes = await input.readAsBytes();
  if (bytes.isEmpty) {
    throw ScannerException('Image file empty: $inputPath');
  }

  try {
    final Uint8List jpeg = await Isolate.run(
      () => downscaleJpegBytesIsolate(
        (
          bytes: bytes,
          maxEdge: maxEdge,
          quality: quality,
        ),
      ),
    );

    final File out = File(outputPath);
    await out.parent.create(recursive: true);
    await out.writeAsBytes(jpeg, flush: true);
    return outputPath;
  } on AppException {
    rethrow;
  } catch (error) {
    throw ScannerException('Failed to downscale image.', cause: error);
  }
}
