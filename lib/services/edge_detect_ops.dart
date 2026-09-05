import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';

typedef DetectCornersResult = ({int width, int height, List<double> flat});
typedef WarpArgs = ({String path, List<double> flat, String outputPath});

/// Sync OpenCV detect — run only inside [Isolate.run].
DetectCornersResult detectCornersSync(String path) {
  final cv.Mat src = cv.imread(path);
  if (src.isEmpty) {
    throw StateError('OpenCV could not read image: $path');
  }

  cv.Mat? gray;
  cv.Mat? blur;
  cv.Mat? edges;
  cv.Contours? contours;
  cv.VecVec4i? hierarchy;
  cv.VecPoint? best;

  try {
    final int width = src.cols;
    final int height = src.rows;
    gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
    blur = cv.gaussianBlur(gray, (5, 5), 0);
    edges = cv.canny(blur, 50, 150);
    final (cv.Contours found, cv.VecVec4i hier) = cv.findContours(
      edges,
      cv.RETR_LIST,
      cv.CHAIN_APPROX_SIMPLE,
    );
    contours = found;
    hierarchy = hier;

    double bestArea = 0;
    final double minArea = width * height * 0.12;

    for (int i = 0; i < contours.length; i++) {
      final cv.VecPoint contour = contours[i];
      final double peri = cv.arcLength(contour, true);
      final cv.VecPoint approx = cv.approxPolyDP(contour, 0.02 * peri, true);
      if (approx.length == 4 && cv.isContourConvex(approx)) {
        final double area = cv.contourArea(approx);
        if (area > bestArea && area >= minArea) {
          best?.dispose();
          best = approx;
          bestArea = area;
        } else {
          approx.dispose();
        }
      } else {
        approx.dispose();
      }
    }

    if (best == null) {
      final ScanQuad fallback =
          ScanQuad.insetRect(width: width, height: height);
      return (width: width, height: height, flat: fallback.toFlat());
    }

    final List<Offset> ordered = orderQuadPoints(<Offset>[
      Offset(best[0].x.toDouble(), best[0].y.toDouble()),
      Offset(best[1].x.toDouble(), best[1].y.toDouble()),
      Offset(best[2].x.toDouble(), best[2].y.toDouble()),
      Offset(best[3].x.toDouble(), best[3].y.toDouble()),
    ]);

    final ScanQuad quad = ScanQuad(
      topLeft: ordered[0],
      topRight: ordered[1],
      bottomRight: ordered[2],
      bottomLeft: ordered[3],
    );
    return (width: width, height: height, flat: quad.toFlat());
  } finally {
    best?.dispose();
    hierarchy?.dispose();
    contours?.dispose();
    edges?.dispose();
    blur?.dispose();
    gray?.dispose();
    src.dispose();
  }
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
