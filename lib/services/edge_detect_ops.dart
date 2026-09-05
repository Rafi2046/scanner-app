import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';

typedef DetectCornersResult = ({int width, int height, List<double> flat});
typedef WarpArgs = ({String path, List<double> flat, String outputPath});

/// Sync OpenCV paper edge detection — run only inside [Isolate.run].
/// Uses multi-scale downsampling and paper-specific segmentation (Otsu & Canny)
/// to accurately find paper sheets and open books on various desk surfaces.
DetectCornersResult detectCornersSync(String path) {
  final cv.Mat src = cv.imread(path);
  if (src.isEmpty) {
    throw StateError('OpenCV could not read image: $path');
  }

  cv.Mat? small;
  cv.Mat? gray;
  cv.Mat? blur;
  try {
    final int origW = src.cols;
    final int origH = src.rows;

    // Rescale to ~800px max dimension for fast, noise-free paper boundary detection
    final double maxDim = math.max(origW, origH).toDouble();
    final double scale = maxDim > 800 ? 800.0 / maxDim : 1.0;

    final cv.Mat workImg;
    if (scale < 1.0) {
      final int targetW = (origW * scale).round();
      final int targetH = (origH * scale).round();
      small = cv.resize(src, (targetW, targetH));
      workImg = small;
    } else {
      workImg = src;
    }

    final int width = workImg.cols;
    final int height = workImg.rows;
    final double imageArea = (width * height).toDouble();

    gray = cv.cvtColor(workImg, cv.COLOR_BGR2GRAY);
    blur = cv.gaussianBlur(gray, (9, 9), 1.5);

    final List<cv.Mat> edgeMaps = <cv.Mat>[
      _otsuPaperEdges(blur),
      _cannyEdges(blur),
      _adaptivePaperEdges(blur),
    ];

    final List<double>? bestSmallFlat = _bestQuadFlat(
      edgeMaps,
      imageArea: imageArea,
      width: width,
      height: height,
    );

    if (bestSmallFlat != null) {
      final double invScale = origW / width.toDouble();
      final ScanQuad smallQuad = ScanQuad.fromFlat(bestSmallFlat);
      final ScanQuad scaledQuad = ScanQuad(
        topLeft: Offset(smallQuad.topLeft.dx * invScale, smallQuad.topLeft.dy * invScale),
        topRight: Offset(smallQuad.topRight.dx * invScale, smallQuad.topRight.dy * invScale),
        bottomRight: Offset(smallQuad.bottomRight.dx * invScale, smallQuad.bottomRight.dy * invScale),
        bottomLeft: Offset(smallQuad.bottomLeft.dx * invScale, smallQuad.bottomLeft.dy * invScale),
      );
      return (width: origW, height: origH, flat: scaledQuad.toFlat());
    }

    // High-margin fallback: only 2% inset when paper covers full frame (never chops text)
    final ScanQuad fallback = ScanQuad.insetRect(
      width: origW,
      height: origH,
      insetFraction: 0.02,
    );
    return (width: origW, height: origH, flat: fallback.toFlat());
  } finally {
    blur?.dispose();
    gray?.dispose();
    small?.dispose();
    src.dispose();
  }
}

/// Otsu thresholding fills book text and highlights the white/cream paper sheet against backgrounds.
cv.Mat _otsuPaperEdges(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
  final cv.Mat kernelClose = cv.getStructuringElement(cv.MORPH_RECT, (17, 17));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernelClose);
  final cv.Mat kernelOpen = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(closed, cv.MORPH_OPEN, kernelOpen);

  thresh.dispose();
  kernelClose.dispose();
  closed.dispose();
  kernelOpen.dispose();
  return opened;
}

/// Canny edge detection with closing to bridge paper edge discontinuities.
cv.Mat _cannyEdges(cv.Mat blur) {
  final cv.Mat edges = cv.canny(blur, 25, 80);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (9, 9));
  final cv.Mat closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
  edges.dispose();
  kernel.dispose();
  return closed;
}

/// Adaptive thresholding for shadow-heavy scenes or textured desks.
cv.Mat _adaptivePaperEdges(cv.Mat blur) {
  final cv.Mat thresh = cv.adaptiveThreshold(
    blur,
    255,
    cv.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv.THRESH_BINARY_INV,
    25,
    4,
  );
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (13, 13));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
  thresh.dispose();
  kernel.dispose();
  return closed;
}

List<double>? _bestQuadFlat(
  List<cv.Mat> edgeMaps, {
  required double imageArea,
  required int width,
  required int height,
}) {
  List<Offset>? bestQuad;
  double bestScore = -1;

  // Broad area acceptance: from small receipts (12%) to full-bleed paper (98%)
  final double minArea = imageArea * 0.12;
  final double maxArea = imageArea * 0.98;

  try {
    for (final cv.Mat edges in edgeMaps) {
      final (cv.Contours contours, cv.VecVec4i hierarchy) = cv.findContours(
        edges,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );
      hierarchy.dispose();

      for (int i = 0; i < contours.length; i++) {
        final cv.VecPoint contour = contours[i];
        final double rawArea = cv.contourArea(contour).abs();
        if (rawArea < minArea || rawArea > maxArea) {
          continue;
        }

        final double peri = cv.arcLength(contour, true);
        if (peri < 60) continue;

        for (final double eps in <double>[0.015, 0.025, 0.035, 0.05, 0.07, 0.09, 0.12]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          List<Offset>? candidatePts;

          if (approx.length == 4 && cv.isContourConvex(approx)) {
            candidatePts = orderQuadPoints(<Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ]);
          } else if (approx.length >= 4 && approx.length <= 10) {
            // Extract 4 extreme corners for curved or rounded paper boundaries
            candidatePts = _extractFourCorners(approx);
          }
          approx.dispose();

          if (candidatePts == null || candidatePts.length != 4) {
            continue;
          }

          final double qW = dist(candidatePts[0], candidatePts[1]);
          final double qH = dist(candidatePts[0], candidatePts[3]);
          if (qW <= 20 || qH <= 20) continue;

          final double aspect = qW / qH;
          if (aspect < 0.35 || aspect > 2.8) continue;

          final double area = _polygonArea(candidatePts);
          if (area < minArea || area > maxArea) continue;

          // Score: reward larger paper areas that maintain rectangularity
          final double areaRatio = area / imageArea;
          final double score = areaRatio * 100.0;

          if (score > bestScore) {
            bestScore = score;
            bestQuad = candidatePts;
          }
        }
      }
      contours.dispose();
      edges.dispose();
    }

    if (bestQuad == null) {
      return null;
    }

    return ScanQuad(
      topLeft: bestQuad[0],
      topRight: bestQuad[1],
      bottomRight: bestQuad[2],
      bottomLeft: bestQuad[3],
    ).toFlat();
  } finally {
    // Done
  }
}

/// Extracts the 4 corners of any approximate contour by finding extreme points.
List<Offset> _extractFourCorners(cv.VecPoint pts) {
  if (pts.length < 4) return <Offset>[];

  double minSum = double.infinity;
  double maxSum = -double.infinity;
  double minDiff = double.infinity;
  double maxDiff = -double.infinity;

  Offset tl = Offset.zero;
  Offset br = Offset.zero;
  Offset tr = Offset.zero;
  Offset bl = Offset.zero;

  for (int i = 0; i < pts.length; i++) {
    final double x = pts[i].x.toDouble();
    final double y = pts[i].y.toDouble();
    final double sum = x + y;
    final double diff = x - y;

    if (sum < minSum) {
      minSum = sum;
      tl = Offset(x, y);
    }
    if (sum > maxSum) {
      maxSum = sum;
      br = Offset(x, y);
    }
    if (diff > maxDiff) {
      maxDiff = diff;
      tr = Offset(x, y);
    }
    if (diff < minDiff) {
      minDiff = diff;
      bl = Offset(x, y);
    }
  }

  return orderQuadPoints(<Offset>[tl, tr, br, bl]);
}

double _polygonArea(List<Offset> pts) {
  if (pts.length < 3) return 0.0;
  double area = 0.0;
  for (int i = 0; i < pts.length; i++) {
    final int j = (i + 1) % pts.length;
    area += pts[i].dx * pts[j].dy;
    area -= pts[j].dx * pts[i].dy;
  }
  return (area / 2.0).abs();
}

/// Sync OpenCV warp — run only inside [Isolate.run].
String warpPerspectiveSync(WarpArgs args) {
  final ScanQuad quad = ScanQuad.fromFlat(args.flat);
  final cv.Mat src = cv.imread(args.path);
  if (src.isEmpty) {
    throw StateError('OpenCV could not read image: ${args.path}');
  }

  cv.VecPoint2f? srcPts;
  cv.VecPoint2f? dstPts;
  cv.Mat? matrix;
  cv.Mat? warped;

  try {
    final double wTop = dist(quad.topLeft, quad.topRight);
    final double wBot = dist(quad.bottomLeft, quad.bottomRight);
    final double hLeft = dist(quad.topLeft, quad.bottomLeft);
    final double hRight = dist(quad.topRight, quad.bottomRight);
    final int outW = math.max(wTop, wBot).round().clamp(1, 4096);
    final int outH = math.max(hLeft, hRight).round().clamp(1, 4096);

    srcPts = cv.VecPoint2f.fromList(<cv.Point2f>[
      cv.Point2f(quad.topLeft.dx, quad.topLeft.dy),
      cv.Point2f(quad.topRight.dx, quad.topRight.dy),
      cv.Point2f(quad.bottomRight.dx, quad.bottomRight.dy),
      cv.Point2f(quad.bottomLeft.dx, quad.bottomLeft.dy),
    ]);
    dstPts = cv.VecPoint2f.fromList(<cv.Point2f>[
      cv.Point2f(0, 0),
      cv.Point2f(outW.toDouble(), 0),
      cv.Point2f(outW.toDouble(), outH.toDouble()),
      cv.Point2f(0, outH.toDouble()),
    ]);

    matrix = cv.getPerspectiveTransform2f(srcPts, dstPts);
    warped = cv.warpPerspective(src, matrix, (outW, outH));

    final bool ok = cv.imwrite(args.outputPath, warped);
    if (!ok) {
      throw StateError('Failed to write warped scan image.');
    }
    return args.outputPath;
  } finally {
    warped?.dispose();
    matrix?.dispose();
    dstPts?.dispose();
    srcPts?.dispose();
    src.dispose();
  }
}

double dist(Offset a, Offset b) {
  final double dx = a.dx - b.dx;
  final double dy = a.dy - b.dy;
  return math.sqrt(dx * dx + dy * dy);
}

/// Order corners to TL, TR, BR, BL.
List<Offset> orderQuadPoints(List<Offset> pts) {
  if (pts.length != 4) {
    return pts;
  }
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
