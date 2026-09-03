import 'dart:typed_data';
import 'dart:ui';

/// One rasterized PDF page plus its original page size in PDF points.
class RasterizedPdfPage {
  const RasterizedPdfPage({
    required this.jpegBytes,
    required this.pageSize,
  });

  final Uint8List jpegBytes;
  final Size pageSize;
}
