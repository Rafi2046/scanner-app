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
    orElse: () => ScanFilter.color,
  );

  final img.Image out = switch (filter) {
    ScanFilter.original => decoded,
    ScanFilter.color => _magicColorFilter(decoded),
    ScanFilter.bw => _bwScanFilter(decoded),
    ScanFilter.enhance => _enhanceFilter(decoded),
  };

  return Uint8List.fromList(
    img.encodeJpg(out, quality: args.quality),
  );
}

/// CamScanner "Magic Color": Local background equalization + shadow removal + white-paper boost.
img.Image _magicColorFilter(img.Image src) {
  final int w = src.width;
  final int h = src.height;

  final Uint8List luma = _computeLuminance(src, w, h);
  const int gridCols = 24;
  const int gridRows = 32;
  final Float32List bgGrid = _estimateBackgroundGrid(luma, w, h, gridCols, gridRows);

  final img.Image dst = img.Image(width: w, height: h);

  const double blackCut = 0.44;
  const double whiteCut = 0.88;

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
      final double bgTop = b00 + tx * (b10 - b00);
      final double bgBot = b01 + tx * (b11 - b01);
      final double bg = bgTop + ty * (bgBot - bgTop);

      final int curLuma = luma[rowOff + x];
      final double ratio = curLuma / (bg > 12.0 ? bg : 12.0);

      double targetLuma;
      if (ratio >= whiteCut) {
        targetLuma = 255.0;
      } else if (ratio <= blackCut) {
        targetLuma = (ratio / blackCut) * 28.0;
      } else {
        final double t = (ratio - blackCut) / (whiteCut - blackCut);
        final double curve = t * t * (3.0 - 2.0 * t);
        targetLuma = 28.0 + curve * (255.0 - 28.0);
      }

      final double gain = curLuma > 0 ? (targetLuma / curLuma) : 1.0;
      final img.Pixel p = src.getPixel(x, y);
      final int r = (p.r * gain).round().clamp(0, 255);
      final int g = (p.g * gain).round().clamp(0, 255);
      final int b = (p.b * gain).round().clamp(0, 255);

      dst.setPixelRgb(x, y, r, g, b);
    }
  }

  return dst;
}

/// Pure black & white photocopier / high-contrast flatbed scan.
img.Image _bwScanFilter(img.Image src) {
  final int w = src.width;
  final int h = src.height;

  final Uint8List luma = _computeLuminance(src, w, h);
  const int gridCols = 24;
  const int gridRows = 32;
  final Float32List bgGrid = _estimateBackgroundGrid(luma, w, h, gridCols, gridRows);

  final img.Image dst = img.Image(width: w, height: h);

  const double blackCut = 0.62;
  const double whiteCut = 0.82;

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
      final double bgTop = b00 + tx * (b10 - b00);
      final double bgBot = b01 + tx * (b11 - b01);
      final double bg = bgTop + ty * (bgBot - bgTop);

      final int curLuma = luma[rowOff + x];
      final double ratio = curLuma / (bg > 12.0 ? bg : 12.0);

      int val;
      if (ratio >= whiteCut) {
        val = 255;
      } else if (ratio <= blackCut) {
        val = 0;
      } else {
        final double t = (ratio - blackCut) / (whiteCut - blackCut);
        val = (t * 255.0).round().clamp(0, 255);
      }

      dst.setPixelRgb(x, y, val, val, val);
    }
  }

  return dst;
}

/// Enhance filter: Magic Color + 3x3 unsharp mask for extreme text crispness.
img.Image _enhanceFilter(img.Image src) {
  final img.Image magic = _magicColorFilter(src);
  return img.convolution(
    magic,
    filter: <num>[
      0, -0.6, 0,
      -0.6, 3.4, -0.6,
      0, -0.6, 0,
    ],
  );
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
      bgGrid[gy * gridCols + gx] = cellBg.clamp(30.0, 255.0);
    }
  }

  return bgGrid;
}
