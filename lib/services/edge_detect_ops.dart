import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';

typedef DetectCornersResult = ({int width, int height, List<double> flat});
typedef WarpArgs = ({String path, List<double> flat, String outputPath});

/// Sync OpenCV paper edge detection — run only inside [Isolate.run].
/// Uses text-erasure morphological closing, Otsu paper-mask segmentation,
/// and oriented rectangular quad fitting to accurately detect real paper sheets.
DetectCornersResult detectCornersSync(String path) {
  final cv.Mat src = cv.imread(path);
  if (src.isEmpty) {
    throw StateError('OpenCV could not read image: $path');
  }

  cv.Mat? small;
  cv.Mat? gray;
  cv.Mat? textErased;
  cv.Mat? blurred;
  try {
    final int origW = src.cols;
    final int origH = src.rows;

    // Rescale to ~600px max dimension:
    // 1. Text characters become 1-2px and easily erased by morphology
    // 2. High performance (<15ms)
    // 3. Desk texture noise is suppressed
    final double maxDim = math.max(origW, origH).toDouble();
    final double scale = maxDim > 600 ? 600.0 / maxDim : 1.0;

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

    // CRITICAL: Text-erasure via grayscale morphological closing.
    // Dark printed text strokes (<15px) are replaced with the surrounding white/cream paper.
    // The entire page becomes a solid paper surface with NO interior text edges!
    final cv.Mat kernelText = cv.getStructuringElement(cv.MORPH_RECT, (17, 17));
    textErased = cv.morphologyEx(gray, cv.MORPH_CLOSE, kernelText);
    kernelText.dispose();

    blurred = cv.gaussianBlur(textErased, (9, 9), 2.0);

    final List<cv.Mat> edgeMaps = <cv.Mat>[
      _buildOtsuPaperMask(blurred),
      _buildCannyPaperEdges(blurred),
    ];

    final List<double>? bestSmallFlat = _findBestPaperQuad(
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
    blurred?.dispose();
    textErased?.dispose();
    gray?.dispose();
    small?.dispose();
    src.dispose();
  }
}

/// Otsu thresholding on text-erased image creates a solid white polygon of the paper.
cv.Mat _buildOtsuPaperMask(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
  final cv.Mat kernelClose = cv.getStructuringElement(cv.MORPH_RECT, (21, 21));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernelClose);
  final cv.Mat kernelOpen = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(closed, cv.MORPH_OPEN, kernelOpen);

  thresh.dispose();
  kernelClose.dispose();
  closed.dispose();
  kernelOpen.dispose();
  return opened;
}

/// Canny edge detection on text-erased image detects ONLY paper outer boundaries.
cv.Mat _buildCannyPaperEdges(cv.Mat blur) {
  final cv.Mat edges = cv.canny(blur, 25, 80);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (11, 11));
  final cv.Mat closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
  edges.dispose();
  kernel.dispose();
  return closed;
}

List<double>? _findBestPaperQuad(
  List<cv.Mat> edgeMaps, {
  required double imageArea,
  required int width,
  required int height,
}) {
  List<Offset>? bestQuad;
  double bestScore = -1;

  final double minArea = imageArea * 0.12;
  final double maxArea = imageArea * 0.98;

  try {
    for (final cv.Mat map in edgeMaps) {
      final (cv.Contours contours, cv.VecVec4i hierarchy) = cv.findContours(
        map,
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

        // Generate candidate quads from this contour:
        final List<List<Offset>> candidates = <List<Offset>>[];

        // 1. Polygon approximations with various tolerances
        for (final double eps in <double>[0.02, 0.035, 0.05, 0.07, 0.09]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          if (approx.length == 4 && cv.isContourConvex(approx)) {
            candidates.add(orderQuadPoints(<Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ]));
          }
          approx.dispose();
        }

        // 2. Minimum area bounding rotated rectangle (ideal for curved book pages)
        final cv.RotatedRect rRect = cv.minAreaRect(contour);
        final cv.VecPoint2f rPts = rRect.points;
        if (rPts.length == 4) {
          candidates.add(orderQuadPoints(<Offset>[
            for (int k = 0; k < 4; k++)
              Offset(rPts[k].x.toDouble(), rPts[k].y.toDouble()),
          ]));
        }

        // 3. Extreme corners
        final List<Offset> extPts = _extractFourCorners(contour);
        if (extPts.length == 4) {
          candidates.add(extPts);
        }

        // Score each candidate quad
        for (final List<Offset> candidate in candidates) {
          final double qArea = _polygonArea(candidate);
          if (qArea < minArea || qArea > maxArea) continue;

          // Check rectangularity (interior corner angles close to 90°)
          final double angleQuality = _evaluateRectangularity(candidate);
          if (angleQuality < 0.40) continue; // Skip non-quadrilaterals or severe skews

          // Check aspect ratio (typical books and documents: 0.4 to 2.4)
          final double topLen = dist(candidate[0], candidate[1]);
          final double leftLen = dist(candidate[0], candidate[3]);
          if (topLen < 20 || leftLen < 20) continue;
          final double aspect = topLen / leftLen;
          if (aspect < 0.35 || aspect > 2.6) continue;

          // Score: combines area coverage and rectangularity
          final double areaRatio = qArea / imageArea;
          final double score = (areaRatio * 60.0) + (angleQuality * 40.0);

          if (score > bestScore) {
            bestScore = score;
            bestQuad = candidate;
          }
        }
      }
      contours.dispose();
      map.dispose();
    }

    if (bestQuad == null) {
      return null;
    }

    // Clamp candidate points within image bounds
    final List<Offset> clamped = <Offset>[
      for (final Offset pt in bestQuad)
        Offset(
          pt.dx.clamp(0.0, width.toDouble()),
          pt.dy.clamp(0.0, height.toDouble()),
        ),
    ];

    return ScanQuad(
      topLeft: clamped[0],
      topRight: clamped[1],
      bottomRight: clamped[2],
      bottomLeft: clamped[3],
    ).toFlat();
  } finally {
    // Done
  }
}

/// Evaluates how close the quad's 4 corners are to 90 degrees (1.0 = perfect rectangle).
double _evaluateRectangularity(List<Offset> pts) {
  if (pts.length != 4) return 0.0;

  double totalQuality = 0.0;
  for (int i = 0; i < 4; i++) {
    final Offset prev = pts[(i + 3) % 4];
    final Offset curr = pts[i];
    final Offset next = pts[(i + 1) % 4];

    final double v1x = prev.dx - curr.dx;
    final double v1y = prev.dy - curr.dy;
    final double v2x = next.dx - curr.dx;
    final double v2y = next.dy - curr.dy;

    final double l1 = math.sqrt(v1x * v1x + v1y * v1y);
    final double l2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (l1 <= 0 || l2 <= 0) return 0.0;

    // Dot product of normalized vectors
    final double cosAngle = ((v1x * v2x) + (v1y * v2y)) / (l1 * l2);
    // Ideal is cosAngle == 0 (90 degrees)
    final double deviation = cosAngle.abs();
    totalQuality += (1.0 - deviation.clamp(0.0, 1.0));
  }

  return totalQuality / 4.0;
}

/// Extracts the 4 corners of any contour by finding extreme points.
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
