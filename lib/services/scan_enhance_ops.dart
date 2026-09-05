import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

/// Isolate entry: apply [filter] to JPEG [bytes], return JPEG bytes.
Uint8List applyScanFilterIsolate(({
  Uint8List bytes,
  String filterName,
  int quality,
}) args) {
  final img.Image? decoded = img.decodeImage(args.bytes);
  if (decoded == null) {
    throw StateError('Could not decode image for filter.');
  }

  final ScanFilter filter = ScanFilter.values.firstWhere(
    (ScanFilter f) => f.name == args.filterName,
    orElse: () => ScanFilter.original,
  );

  final img.Image out = switch (filter) {
    ScanFilter.original => decoded,
    ScanFilter.color => img.adjustColor(
        decoded,
        contrast: 1.12,
        saturation: 1.05,
      ),
    ScanFilter.bw => img.adjustColor(
        img.grayscale(decoded),
        contrast: 1.25,
      ),
    ScanFilter.enhance => img.adjustColor(
        img.convolution(
          decoded,
          filter: <num>[
            0,
            -1,
            0,
            -1,
            5,
            -1,
            0,
            -1,
            0,
          ],
        ),
        contrast: 1.2,
        brightness: 1.02,
      ),
  };

  return Uint8List.fromList(
    img.encodeJpg(out, quality: args.quality),
  );
}

const int kDefaultFilterJpegQuality = AppConstants.scanJpegQuality;
