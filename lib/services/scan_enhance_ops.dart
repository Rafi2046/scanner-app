import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:scanner_app/core/enums/scan_filter.dart';

/// Isolate entry: applies CamScanner-grade document filters to JPEG [bytes].
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
    orElse: () => args.filterName == 'bwPrint' ? ScanFilter.bw : ScanFilter.magicEnhance,
  );

  final img.Image out = switch (filter) {
    ScanFilter.original => decoded,
    ScanFilter.magicEnhance => _magicColorFilter(decoded),
    ScanFilter.vivid => _vividColorFilter(decoded),
    ScanFilter.noShadow => _noShadowFilter(decoded),
    ScanFilter.bw => _bwScanFilter(decoded),
    ScanFilter.grayscale => _grayscaleFilter(decoded),
    ScanFilter.lighten => _lightenFilter(decoded),
    ScanFilter.invert => _invertFilter(decoded),
  };

  return Uint8List.fromList(
    img.encodeJpg(out, quality: args.quality),
  );
}

/// Isolate entry: rotates image bytes by [angle] degrees (e.g. -90, 90).
Uint8List rotateJpegBytesIsolate(({
  Uint8List bytes,
  int angle,
  int quality,
}) args) {
  final img.Image? decoded = img.decodeImage(args.bytes);
  if (decoded == null) {
    throw StateError('Could not decode image for rotate.');
  }
  final img.Image rotated = img.copyRotate(decoded, angle: args.angle);
  return Uint8List.fromList(
    img.encodeJpg(rotated, quality: args.quality),
  );
}

/// Magic Enhance (Dart fallback): clarity without paper-bleach.
img.Image _magicColorFilter(img.Image src) {
  // Avoid heavy background-division (washes ID card whites).
  final img.Image contrast = img.adjustColor(
    src,
    contrast: 1.10,
    saturation: 1.08,
    brightness: 1.01,
  );
  final img.Image deepInk = _deepenInk(contrast, lumaCut: 55, amount: 0.08);
  return _unsharpMaskDart(deepInk, amount: 0.32, clampDelta: 12);
}

/// Apple "Vivid" (True Color Vibrance & Micro-Contrast):
img.Image _vividColorFilter(img.Image src) {
  final img.Image enhanced = _processDocument(
    src,
    blackCut: 0.22,
    whiteCut: 0.94,
    isColor: true,
    boostSaturation: true,
    satFactor: 1.18,
  );
  final img.Image punchy =
      img.adjustColor(enhanced, saturation: 1.22, contrast: 1.10);
  return _unsharpMaskDart(punchy, amount: 0.32, clampDelta: 18);
}

/// CamScanner "No Shadow": Soft shadow flattening, preserving fine handwriting and stamps.
img.Image _noShadowFilter(img.Image src) {
  return _processDocument(
    src,
    blackCut: 0.32,
    whiteCut: 0.82,
    isColor: true,
    boostSaturation: false,
  );
}

/// Pure Black & White (CamScanner bwPrint):
/// Optical background division followed by adaptive local thresholding for pure 0 (black ink)
/// and 255 (paper white), eliminating shadows and uneven lighting for crisp printing.
img.Image _bwScanFilter(img.Image src) {
  final int w = src.width;
  final int h = src.height;
  final Uint8List luma = _computeLuminance(src, w, h);
  const int gridCols = 24;
  const int gridRows = 32;
  final Float32List bgGrid = _estimateBackgroundGrid(luma, w, h, gridCols, gridRows);
  final img.Image dst = img.Image(width: w, height: h);

  // Print-ready threshold: relative ratio of pixel luminance to local background sheet
  const double thresholdRatio = 0.78;

  for (int y = 0; y < h; y++) {
    final double gy = (y / h) * (gridRows - 1);
    final int gy0 = gy.floor().clamp(0, gridRows - 1);
    final int gy1 = (gy0 + 1).clamp(0, gridRows - 1);
    final double ty = gy - gy0;
    final int rowOff = y * w;

    for (int x = 0; x < w; x++) {
      final double gx = (x / w) * (gridCols - 1);
      final int gx0 = gx.floor().clamp(0, gridCols - 1);
      final int gx1 = (gx0 + 1).clamp(0, gridCols - 1);
      final double tx = gx - gx0;

      final double b00 = bgGrid[gy0 * gridCols + gx0];
      final double b10 = bgGrid[gy0 * gridCols + gx1];
      final double b01 = bgGrid[gy1 * gridCols + gx0];
      final double b11 = bgGrid[gy1 * gridCols + gx1];
      final double bg = (b00 + tx * (b10 - b00)) +
          ty * ((b01 + tx * (b11 - b01)) - (b00 + tx * (b10 - b00)));

      final int curLuma = luma[rowOff + x];
      final double ratio = curLuma / (bg > 12.0 ? bg : 12.0);

      // Pure binary decision: solid black text (0) or pure white paper (255)
      final int val = ratio < thresholdRatio ? 0 : 255;
      dst.setPixelRgb(x, y, val, val, val);
    }
  }

  return dst;
}

/// Clean grayscale flatbed scanner look: smooth continuous midtones with crisp white paper.
img.Image _grayscaleFilter(img.Image src) {
  final img.Image gray = _processDocument(
    src,
    blackCut: 0.40,
    whiteCut: 0.88,
    isColor: false,
    boostSaturation: false,
  );
  return _unsharpMaskDart(gray, amount: 0.25);
}

/// Lightens shadows and boosts brightness while keeping original color palette.
img.Image _lightenFilter(img.Image src) {
  final img.Image brightened = img.adjustColor(src, brightness: 1.20, contrast: 1.10);
  return img.adjustColor(brightened, gamma: 0.90);
}

/// Inverted scan: white text on dark background.
img.Image _invertFilter(img.Image src) {
  return img.invert(_bwScanFilter(src));
}

/// Core adaptive background leveling engine.
img.Image _processDocument(
  img.Image src, {
  required double blackCut,
  required double whiteCut,
  required bool isColor,
  required bool boostSaturation,
  double satFactor = 1.08,
  double maxDelta = 120,
}) {
  final int w = src.width;
  final int h = src.height;

  final Uint8List luma = _computeLuminance(src, w, h);
  const int gridCols = 24;
  const int gridRows = 32;
  final Float32List bgGrid =
      _estimateBackgroundGrid(luma, w, h, gridCols, gridRows);

  final img.Image dst = img.Image(width: w, height: h);

  for (int y = 0; y < h; y++) {
    final double gy = (y / h) * (gridRows - 1);
    final int gy0 = gy.floor().clamp(0, gridRows - 1);
    final int gy1 = (gy0 + 1).clamp(0, gridRows - 1);
    final double ty = gy - gy0;
    final int rowOff = y * w;

    for (int x = 0; x < w; x++) {
      final double gx = (x / w) * (gridCols - 1);
      final int gx0 = gx.floor().clamp(0, gridCols - 1);
      final int gx1 = (gx0 + 1).clamp(0, gridCols - 1);
      final double tx = gx - gx0;

      final double b00 = bgGrid[gy0 * gridCols + gx0];
      final double b10 = bgGrid[gy0 * gridCols + gx1];
      final double b01 = bgGrid[gy1 * gridCols + gx0];
      final double b11 = bgGrid[gy1 * gridCols + gx1];
      final double bg = (b00 + tx * (b10 - b00)) +
          ty * ((b01 + tx * (b11 - b01)) - (b00 + tx * (b10 - b00)));

      final int curLuma = luma[rowOff + x];
      final double ratio = curLuma / (bg > 12.0 ? bg : 12.0);

      double targetLuma;
      if (ratio >= whiteCut) {
        targetLuma = 255.0;
      } else if (ratio <= blackCut) {
        targetLuma = (ratio / blackCut) * 10.0;
      } else {
        final double t = (ratio - blackCut) / (whiteCut - blackCut);
        final double curve = t * t * (3.0 - 2.0 * t);
        targetLuma = 10.0 + curve * (248.0 - 10.0);
      }

      if (isColor) {
        final img.Pixel p = src.getPixel(x, y);
        final double delta =
            (targetLuma - curLuma).clamp(-maxDelta, maxDelta);
        double r = (p.r + delta).clamp(0.0, 255.0);
        double g = (p.g + delta).clamp(0.0, 255.0);
        double b = (p.b + delta).clamp(0.0, 255.0);

        if (boostSaturation) {
          final double finalLuma = 0.299 * r + 0.587 * g + 0.114 * b;
          r = finalLuma + (r - finalLuma) * satFactor;
          g = finalLuma + (g - finalLuma) * satFactor;
          b = finalLuma + (b - finalLuma) * satFactor;
        }

        dst.setPixelRgb(
          x,
          y,
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
        );
      } else {
        final int v = targetLuma.round().clamp(0, 255);
        dst.setPixelRgb(x, y, v, v, v);
      }
    }
  }

  return dst;
}

/// Slightly darken ink / dark text without crushing photo shadows.
img.Image _deepenInk(
  img.Image src, {
  required int lumaCut,
  required double amount,
}) {
  final int w = src.width;
  final int h = src.height;
  final img.Image dst = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final img.Pixel p = src.getPixel(x, y);
      final int r = p.r.toInt();
      final int g = p.g.toInt();
      final int b = p.b.toInt();
      final int luma = (299 * r + 587 * g + 114 * b) ~/ 1000;
      if (luma <= lumaCut) {
        final double t = (1.0 - luma / lumaCut) * amount;
        dst.setPixelRgb(
          x,
          y,
          (r * (1.0 - t)).round().clamp(0, 255),
          (g * (1.0 - t)).round().clamp(0, 255),
          (b * (1.0 - t)).round().clamp(0, 255),
        );
      } else {
        dst.setPixelRgb(x, y, r, g, b);
      }
    }
  }
  return dst;
}

/// Zero-halo edge enhancement for crisp text without tearing patterns.
img.Image _unsharpMaskDart(
  img.Image src, {
  required double amount,
  double clampDelta = 16,
}) {
  final int w = src.width;
  final int h = src.height;
  final img.Image dst = img.Image(width: w, height: h);

  for (int y = 0; y < h; y++) {
    final int ym1 = y > 0 ? y - 1 : y;
    final int yp1 = y < h - 1 ? y + 1 : y;

    for (int x = 0; x < w; x++) {
      final int xm1 = x > 0 ? x - 1 : x;
      final int xp1 = x < w - 1 ? x + 1 : x;

      final img.Pixel c = src.getPixel(x, y);
      final img.Pixel top = src.getPixel(x, ym1);
      final img.Pixel bot = src.getPixel(x, yp1);
      final img.Pixel lft = src.getPixel(xm1, y);
      final img.Pixel rgt = src.getPixel(xp1, y);

      final double avgR = (c.r + top.r + bot.r + lft.r + rgt.r) / 5.0;
      final double avgG = (c.g + top.g + bot.g + lft.g + rgt.g) / 5.0;
      final double avgB = (c.b + top.b + bot.b + lft.b + rgt.b) / 5.0;

      final double diffR = (c.r - avgR).clamp(-clampDelta, clampDelta);
      final double diffG = (c.g - avgG).clamp(-clampDelta, clampDelta);
      final double diffB = (c.b - avgB).clamp(-clampDelta, clampDelta);

      final int nr = (c.r + amount * diffR).round().clamp(0, 255);
      final int ng = (c.g + amount * diffG).round().clamp(0, 255);
      final int nb = (c.b + amount * diffB).round().clamp(0, 255);

      dst.setPixelRgb(x, y, nr, ng, nb);
    }
  }
  return dst;
}

Uint8List _computeLuminance(img.Image src, int w, int h) {
  final Uint8List luma = Uint8List(w * h);
  int i = 0;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final img.Pixel p = src.getPixel(x, y);
      luma[i++] = ((299 * p.r.toInt() + 587 * p.g.toInt() + 114 * p.b.toInt()) ~/ 1000).clamp(0, 255);
    }
  }
  return luma;
}

Float32List _estimateBackgroundGrid(Uint8List luma, int w, int h, int gridCols, int gridRows) {
  final int cellW = (w / gridCols).ceil();
  final int cellH = (h / gridRows).ceil();
  final Float32List bgGrid = Float32List(gridCols * gridRows);

  int globalMaxL = 0;
  for (int i = 0; i < luma.length; i += 8) {
    if (luma[i] > globalMaxL) globalMaxL = luma[i];
  }
  final double floorBg = math.max(globalMaxL * 0.70, 140.0);

  for (int gy = 0; gy < gridRows; gy++) {
    final int startY = gy * cellH;
    final int endY = (startY + cellH).clamp(0, h);
    for (int gx = 0; gx < gridCols; gx++) {
      final int startX = gx * cellW;
      final int endX = (startX + cellW).clamp(0, w);

      int maxL = 0;
      for (int y = startY; y < endY; y += 2) {
        final int rowOff = y * w;
        for (int x = startX; x < endX; x += 2) {
          final int val = luma[rowOff + x];
          if (val > maxL) maxL = val;
        }
      }

      int sumHigh = 0;
      int countHigh = 0;
      final int thresh = (maxL - 22).clamp(0, 255);
      for (int y = startY; y < endY; y += 2) {
        final int rowOff = y * w;
        for (int x = startX; x < endX; x += 2) {
          final int val = luma[rowOff + x];
          if (val >= thresh) {
            sumHigh += val;
            countHigh++;
          }
        }
      }

      final double cellBg = countHigh > 0 ? (sumHigh / countHigh) : (maxL > 0 ? maxL.toDouble() : 180.0);
      bgGrid[gy * gridCols + gx] = math.max(cellBg, floorBg).clamp(floorBg, 255.0);
    }
  }

  return bgGrid;
}
