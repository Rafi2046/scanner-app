import 'dart:ui' show Offset;

/// Four document corners in image pixel coordinates (TL → TR → BR → BL).
class ScanQuad {
  const ScanQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;

  /// Inset rectangle used when auto-detect fails.
  factory ScanQuad.insetRect({
    required int width,
    required int height,
    double insetFraction = 0.08,
  }) {
    final double dx = width * insetFraction;
    final double dy = height * insetFraction;
    return ScanQuad(
      topLeft: Offset(dx, dy),
      topRight: Offset(width - dx, dy),
      bottomRight: Offset(width - dx, height - dy),
      bottomLeft: Offset(dx, height - dy),
    );
  }

  /// Scales normalized (0..1) quad coordinates to pixel image dimensions.
  factory ScanQuad.fromNormalized(ScanQuad quad, int width, int height) {
    final double w = width.toDouble();
    final double h = height.toDouble();
    return ScanQuad(
      topLeft: Offset(
        (quad.topLeft.dx * w).clamp(0.0, w),
        (quad.topLeft.dy * h).clamp(0.0, h),
      ),
      topRight: Offset(
        (quad.topRight.dx * w).clamp(0.0, w),
        (quad.topRight.dy * h).clamp(0.0, h),
      ),
      bottomRight: Offset(
        (quad.bottomRight.dx * w).clamp(0.0, w),
        (quad.bottomRight.dy * h).clamp(0.0, h),
      ),
      bottomLeft: Offset(
        (quad.bottomLeft.dx * w).clamp(0.0, w),
        (quad.bottomLeft.dy * h).clamp(0.0, h),
      ),
    );
  }

  List<Offset> get points =>
      <Offset>[topLeft, topRight, bottomRight, bottomLeft];

  /// Flat list for isolate messages: [tlx,tly, trx,try, brx,bry, blx,bly].
  List<double> toFlat() => <double>[
        topLeft.dx,
        topLeft.dy,
        topRight.dx,
        topRight.dy,
        bottomRight.dx,
        bottomRight.dy,
        bottomLeft.dx,
        bottomLeft.dy,
      ];

  factory ScanQuad.fromFlat(List<double> flat) {
    if (flat.length != 8) {
      throw ArgumentError('ScanQuad.fromFlat expects 8 values.');
    }
    return ScanQuad(
      topLeft: Offset(flat[0], flat[1]),
      topRight: Offset(flat[2], flat[3]),
      bottomRight: Offset(flat[4], flat[5]),
      bottomLeft: Offset(flat[6], flat[7]),
    );
  }
}
