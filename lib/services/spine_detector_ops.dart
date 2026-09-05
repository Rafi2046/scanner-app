import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;
import 'package:scanner_app/models/scan_quad.dart';

/// Detects open book spine crease and extracts the dominant single page.
class SpineDetectorOps {
  /// Isolates the dominant single page if [quad] spans across multiple pages.
  static ScanQuad isolateDominantPage({
    required ScanQuad quad,
    required Uint8List bytes,
    required int outW,
    required int outH,
    required int frameW,
    required int frameH,
    required int sensorOrientation,
  }) {
    final double minX = math.min(quad.topLeft.dx, quad.bottomLeft.dx);
    final double maxX = math.max(quad.topRight.dx, quad.bottomRight.dx);
    final double minY = math.min(quad.topLeft.dy, quad.topRight.dy);
    final double maxY = math.max(quad.bottomLeft.dy, quad.bottomRight.dy);

    final double quadW = maxX - minX;
    final double quadH = maxY - minY;
    if (quadW <= 0 || quadH <= 0) return quad;

    final double aspect = (quadW * frameW) / (quadH * frameH);

    // If already portrait single page (aspect < 0.85), no split needed
    if (aspect < 0.85 || quadW < 0.25) {
      return quad;
    }

    // Check vertical columns for book spine shadow crease
    double minLuma = 255.0;
    double bestT = -1.0;
    double totalLuma = 0;
    int samples = 0;

    for (double t = 0.20; t <= 0.80; t += 0.04) {
      final double x = (minX + t * quadW) * frameW;
      double colSum = 0;
      int count = 0;
      for (double yt = 0.20; yt <= 0.80; yt += 0.15) {
        final double y = (minY + yt * quadH) * frameH;
        colSum += sampleLuma(bytes, outW, outH, x, y, sensorOrientation);
        count++;
      }
      final double avgL = count > 0 ? colSum / count : 128.0;
      totalLuma += avgL;
      samples++;
      if (avgL < minLuma) {
        minLuma = avgL;
        bestT = t;
      }
    }

    final double meanLuma = samples > 0 ? totalLuma / samples : 128.0;

    // If a dark spine crease valley is found (at least 8 luma darker than mean)
    if (meanLuma - minLuma >= 8 && bestT > 0) {
      final double leftFrac = bestT;
      final double rightFrac = 1.0 - bestT;

      final double leftCenter = minX + quadW * (bestT * 0.5);
      final double rightCenter = minX + quadW * (bestT + rightFrac * 0.5);
      final double leftScore = leftFrac * (1.0 - (leftCenter - 0.5).abs());
      final double rightScore = rightFrac * (1.0 - (rightCenter - 0.5).abs());

      final Offset topSpine = Offset(
        quad.topLeft.dx + bestT * (quad.topRight.dx - quad.topLeft.dx),
        quad.topLeft.dy + bestT * (quad.topRight.dy - quad.topLeft.dy),
      );
      final Offset botSpine = Offset(
        quad.bottomLeft.dx + bestT * (quad.bottomRight.dx - quad.bottomLeft.dx),
        quad.bottomLeft.dy + bestT * (quad.bottomRight.dy - quad.bottomLeft.dy),
      );

      if (rightScore >= leftScore) {
        // Right page is dominant (Page 71)
        return ScanQuad(
          topLeft: topSpine,
          topRight: quad.topRight,
          bottomRight: quad.bottomRight,
          bottomLeft: botSpine,
        );
      } else {
        // Left page is dominant
        return ScanQuad(
          topLeft: quad.topLeft,
          topRight: topSpine,
          bottomRight: botSpine,
          bottomLeft: quad.bottomLeft,
        );
      }
    }

    // Fallback: return original quad
    return quad;
  }

  static double sampleLuma(
    Uint8List bytes,
    int w,
    int h,
    double px,
    double py,
    int orientation,
  ) {
    int origX = px.round().clamp(0, w - 1);
    int origY = py.round().clamp(0, h - 1);
    if (orientation == 90) {
      origX = py.round().clamp(0, w - 1);
      origY = (h - 1 - px.round()).clamp(0, h - 1);
    } else if (orientation == 270) {
      origX = (w - 1 - py.round()).clamp(0, w - 1);
      origY = px.round().clamp(0, h - 1);
    }
    final int idx = origY * w + origX;
    if (idx >= 0 && idx < bytes.length) {
      return bytes[idx].toDouble();
    }
    return 128.0;
  }

  static List<Offset> orderPoints(List<Offset> pts) {
    if (pts.length != 4) return pts;
    final List<Offset> bySum = List<Offset>.from(pts)
      ..sort((Offset a, Offset b) => (a.dx + a.dy).compareTo(b.dx + b.dy));
    final Offset tl = bySum.first;
    final Offset br = bySum.last;
    final List<Offset> byDiff = List<Offset>.from(pts)
      ..sort((Offset a, Offset b) => (a.dy - a.dx).compareTo(b.dy - b.dx));
    final Offset tr = byDiff.first;
    final Offset bl = byDiff.last;
    return <Offset>[tl, tr, br, bl];
  }
}
