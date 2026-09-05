import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';

typedef DetectCornersResult = ({int width, int height, List<double> flat});
typedef WarpArgs = ({String path, List<double> flat, String outputPath});

/// Sync OpenCV paper edge detection — run only inside [Isolate.run].
/// Uses text-erasure morphological closing, multi-channel segmentation (Otsu + Canny),
/// and smart document scoring (centrality, contrast, aspect ratio, border rejection).
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

    // Rescale to ~600px max dimension for fast, noise-free morphology
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

    // 1. Text-erasure via morphological closing (9x9 preserves crisp paper corners)
    final cv.Mat kernelText = cv.getStructuringElement(cv.MORPH_RECT, (9, 9));
    textErased = cv.morphologyEx(gray, cv.MORPH_CLOSE, kernelText);
    kernelText.dispose();

    blurred = cv.gaussianBlur(textErased, (5, 5), 1.5);

    // 2. Multi-strategy edge maps
    final List<cv.Mat> edgeMaps = <cv.Mat>[
      _buildOtsuPaperMask(blurred),
      _buildCannyPaperEdges(blurred),
      _buildInvertedOtsuPaperMask(blurred),
    ];

    final List<double>? bestSmallFlat = _findBestPaperQuad(
      edgeMaps,
      gray: gray,
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

    // High-margin fallback: 3% inset when paper covers full frame
    final ScanQuad fallback = ScanQuad.insetRect(
      width: origW,
      height: origH,
      insetFraction: 0.03,
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

/// Otsu thresholding segments bright paper on dark/medium backgrounds.
cv.Mat _buildOtsuPaperMask(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
  thresh.dispose();
  kernel.dispose();
  return closed;
}

/// Inverted Otsu segments dark documents or covers on bright desks.
cv.Mat _buildInvertedOtsuPaperMask(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
  thresh.dispose();
  kernel.dispose();
  return closed;
}

/// Canny edge detection with dilation bridges perimeter discontinuities.
cv.Mat _buildCannyPaperEdges(cv.Mat blur) {
  final cv.Mat edges = cv.canny(blur, 25, 80);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
  final cv.Mat dilated = cv.dilate(edges, kernel);
  edges.dispose();
  kernel.dispose();
  return dilated;
}

List<double>? _findBestPaperQuad(
  List<cv.Mat> edgeMaps, {
  required cv.Mat gray,
  required double imageArea,
  required int width,
  required int height,
}) {
  List<Offset>? bestQuad;
  double bestScore = -1.0;

  final double minArea = imageArea * 0.08;
  final double maxArea = imageArea * 0.95;

  for (final cv.Mat map in edgeMaps) {
    try {
      final (cv.Contours contours, cv.VecVec4i hierarchy) = cv.findContours(
        map,
        cv.RETR_LIST, // Crucial: RETR_LIST catches document borders inside frame boundaries
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

        // Try multiple approximation tolerances for crisp or slightly curved paper edges
        for (final double eps in <double>[0.015, 0.025, 0.035, 0.05, 0.075, 0.10]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          List<Offset>? candidatePts;

          if (approx.length == 4 && cv.isContourConvex(approx)) {
            candidatePts = <Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ];
          } else if (approx.length >= 5 && approx.length <= 8) {
            candidatePts = _extractFourCornersFromPoly(approx);
          }
          approx.dispose();

          if (candidatePts == null || candidatePts.length != 4) {
            continue;
          }

          final double score = _scoreCandidateQuad(
            candidatePts,
            gray: gray,
            width: width,
            height: height,
            imageArea: imageArea,
          );

          if (score > bestScore) {
            bestScore = score;
            bestQuad = candidatePts;
          }
        }
      }
      contours.dispose();
    } catch (_) {
      // Continue to next map
    } finally {
      map.dispose();
    }
  }

  if (bestQuad == null) {
    return null;
  }

  // Ensure clockwise ordered points clamped to bounds
  final List<Offset> ordered = orderQuadPoints(bestQuad);
  final List<Offset> clamped = <Offset>[
    for (final Offset pt in ordered)
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
}

/// Evaluates candidate quad: rewards documents centered on desks, penalizes camera border touches.
double _scoreCandidateQuad(
  List<Offset> pts, {
  required cv.Mat gray,
  required int width,
  required int height,
  required double imageArea,
}) {
  final List<Offset> ord = orderQuadPoints(pts);

  final double qArea = _polygonArea(ord);
  final double areaRatio = qArea / imageArea;
  if (areaRatio < 0.08 || areaRatio > 0.95) return -1.0;

  // 1. Strict Border Check: Real paper on a desk does NOT touch 3 or 4 camera frame edges!
  int borderTouches = 0;
  const double margin = 8.0;
  for (final Offset pt in ord) {
    if (pt.dx <= margin || pt.dx >= width - margin || pt.dy <= margin || pt.dy >= height - margin) {
      borderTouches++;
    }
  }
  if (borderTouches >= 3) {
    return -1.0; // This is the camera frame, not the document
  }
  final double borderPenalty = (1.0 - borderTouches * 0.25).clamp(0.2, 1.0);

  // 2. Rectangularity: Corners should be close to 90 degrees
  final double rectangularity = _evaluateRectangularity(ord);
  if (rectangularity < 0.45) return -1.0;

  // 3. Aspect Ratio: Standard books and documents (0.40 to 2.5)
  final double topW = dist(ord[0], ord[1]);
  final double botW = dist(ord[3], ord[2]);
  final double leftH = dist(ord[0], ord[3]);
  final double rightH = dist(ord[1], ord[2]);
  final double avgW = (topW + botW) / 2.0;
  final double avgH = (leftH + rightH) / 2.0;
  if (avgW <= 12 || avgH <= 12) return -1.0;

  final double aspect = avgW / avgH;
  if (aspect < 0.35 || aspect > 2.8) return -1.0;

  double aspectScore = 1.0;
  if (aspect >= 0.48 && aspect <= 0.85) {
    aspectScore = 2.2; // Standard single portrait page (A4, book, document)
  } else if (aspect > 0.85 && aspect <= 1.25) {
    aspectScore = 1.6; // Square document
  } else if (aspect > 1.25 && aspect <= 1.85) {
    aspectScore = 1.8; // Landscape spread
  }

  // 4. Centrality: Documents are positioned near the center of the camera
  final double cx = (ord[0].dx + ord[1].dx + ord[2].dx + ord[3].dx) / (4.0 * width);
  final double cy = (ord[0].dy + ord[1].dy + ord[2].dy + ord[3].dy) / (4.0 * height);
  final double distCenter = math.sqrt((cx - 0.5) * (cx - 0.5) + (cy - 0.5) * (cy - 0.5));
  final double centrality = (1.0 - distCenter * 1.6).clamp(0.2, 1.0);

  // 5. Area Fitness: Prefers documents occupying 25% to 75% of the frame (like books on desks)
  final double areaFitness = 1.0 - (areaRatio - 0.50).abs() * 0.7;

  // 6. Contrast Boost: Sample center luminance vs overall average
  double contrastBoost = 1.0;
  final int midX = (cx * width).round().clamp(0, width - 1);
  final int midY = (cy * height).round().clamp(0, height - 1);
  try {
    final int centerVal = gray.at<num>(midY, midX).toInt();
    if (centerVal > 140) {
      contrastBoost = 1.25; // Confirmed bright paper
    }
  } catch (_) {}

  final double totalScore = ((rectangularity * 35.0) +
          (aspectScore * 25.0) +
          (centrality * 20.0) +
          (areaFitness * 20.0)) *
      borderPenalty *
      contrastBoost;

  return totalScore;
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

    final double cosAngle = ((v1x * v2x) + (v1y * v2y)) / (l1 * l2);
    final double deviation = cosAngle.abs();
    totalQuality += (1.0 - deviation.clamp(0.0, 1.0));
  }

  return totalQuality / 4.0;
}

/// Extracts 4 extreme corners from a small polygon approximation (5 to 8 points).
List<Offset> _extractFourCornersFromPoly(cv.VecPoint pts) {
  final int count = pts.length;
  if (count < 4) return <Offset>[];

  double minSum = double.infinity;
  double maxSum = -double.infinity;
  double minDiff = double.infinity;
  double maxDiff = -double.infinity;

  Offset tl = Offset.zero;
  Offset br = Offset.zero;
  Offset tr = Offset.zero;
  Offset bl = Offset.zero;

  for (int i = 0; i < count; i++) {
    final double x = pts[i].x.toDouble();
    final double y = pts[i].y.toDouble();
    final double sum = x + y;
    final double diff = y - x;

    if (sum < minSum) {
      minSum = sum;
      tl = Offset(x, y);
    }
    if (sum > maxSum) {
      maxSum = sum;
      br = Offset(x, y);
    }
    if (diff < minDiff) {
      minDiff = diff;
      tr = Offset(x, y);
    }
    if (diff > maxDiff) {
      maxDiff = diff;
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

/// Fast native OpenCV image rotation — run inside [Isolate.run].
String rotateImageFastSync(({String inputPath, String outputPath, int angle}) args) {
  final cv.Mat src = cv.imread(args.inputPath);
  if (src.isEmpty) {
    throw StateError('Could not read image for rotation: ${args.inputPath}');
  }
  cv.Mat? rotated;
  try {
    final int normAngle = (args.angle % 360 + 360) % 360;
    if (normAngle == 90) {
      rotated = cv.rotate(src, cv.ROTATE_90_CLOCKWISE);
    } else if (normAngle == 180) {
      rotated = cv.rotate(src, cv.ROTATE_180);
    } else if (normAngle == 270) {
      rotated = cv.rotate(src, cv.ROTATE_90_COUNTERCLOCKWISE);
    } else {
      rotated = src.clone();
    }
    final bool ok = cv.imwrite(args.outputPath, rotated);
    if (!ok) {
      throw StateError('Failed to write rotated image: ${args.outputPath}');
    }
    return args.outputPath;
  } finally {
    rotated?.dispose();
    src.dispose();
  }
}

/// Extracts a multi-scale paper illumination sheet from [src] to eliminate shadows.
cv.Mat _extractBackgroundIllumination(cv.Mat src) {
  final int origW = src.width;
  final int origH = src.height;

  // 1. Downscale to 360px for fast, robust morphological shadow & lighting extraction
  const int targetW = 360;
  final int targetH = ((origH * targetW) / origW).round().clamp(1, 10000);
  final cv.Mat small = cv.resize(src, (targetW, targetH));

  // 2. Morphological CLOSE wipes text away, isolating the paper illumination and shadows
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (13, 13));
  final cv.Mat closed = cv.morphologyEx(small, cv.MORPH_CLOSE, kernel);

  // 3. Gaussian blur to create smooth illumination transitions
  final cv.Mat blurred = cv.gaussianBlur(closed, (31, 31), 0);

  // 4. Upscale back to original full resolution
  final cv.Mat fullBg = cv.resize(blurred, (origW, origH));

  kernel.dispose();
  closed.dispose();
  blurred.dispose();
  small.dispose();

  return fullBg;
}

/// Fast native OpenCV document filter processing — executed inside [Isolate.run].
String applyScanFilterFastSync(({
  String inputPath,
  String outputPath,
  String filterName,
}) args) {
  final cv.Mat src = cv.imread(args.inputPath);
  if (src.isEmpty) {
    throw StateError('Could not read image for filter: ${args.inputPath}');
  }

  cv.Mat? result;
  cv.Mat? bg;
  cv.Mat? divided;
  cv.Mat? temp1;
  cv.Mat? temp2;

  try {
    switch (args.filterName) {
      case 'original':
        result = src.clone();
        break;

      case 'magicEnhance':
      case 'color':
        // FLATBED SCANNER MACHINE LOOK:
        // 1. Optical background division normalizes paper to pure uniform white and eliminates all shadows
        bg = _extractBackgroundIllumination(src);
        divided = cv.divide(src, bg, scale: 255);

        // 2. Heavy contrast & text deep-inking boost
        temp1 = cv.convertScaleAbs(divided, alpha: 1.25, beta: 6);

        // 3. Unsharp mask sharpening to make printed text razor-sharp like a 300 DPI flatbed scan
        temp2 = cv.gaussianBlur(temp1, (3, 3), 0);
        result = cv.addWeighted(temp1, 1.35, temp2, -0.35, 0);
        break;

      case 'lighten':
        // LIGHTEN: Noticeably brightens paper, clears shadows, gives soft studio light box look
        bg = _extractBackgroundIllumination(src);
        divided = cv.divide(src, bg, scale: 255);
        result = cv.convertScaleAbs(divided, alpha: 1.08, beta: 16);
        break;

      case 'bw':
        // PURE B&W (Photocopier / Xerox flatbed style):
        // 1. Convert to grayscale
        temp1 = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
        // 2. Optical background division on grayscale to completely erase shadows
        bg = _extractBackgroundIllumination(temp1);
        divided = cv.divide(temp1, bg, scale: 255);
        // 3. Adaptive Gaussian thresholding on clean shadow-free paper
        temp2 = cv.gaussianBlur(divided, (3, 3), 0);
        result = cv.adaptiveThreshold(
          temp2,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          21,
          10.0,
        );
        break;

      case 'grayscale':
        // GRAYSCALE FLATBED SCAN:
        temp1 = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
        bg = _extractBackgroundIllumination(temp1);
        divided = cv.divide(temp1, bg, scale: 255);
        // Contrast bump for deep black text on crisp gray/white paper
        result = cv.convertScaleAbs(divided, alpha: 1.28, beta: -4);
        break;

      case 'noShadow':
        // NO SHADOW: Soft background leveling preserving delicate pencil & stamps
        bg = _extractBackgroundIllumination(src);
        divided = cv.divide(src, bg, scale: 255);
        result = cv.convertScaleAbs(divided, alpha: 1.12, beta: 4);
        break;

      case 'invert':
        temp1 = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
        bg = _extractBackgroundIllumination(temp1);
        divided = cv.divide(temp1, bg, scale: 255);
        result = cv.adaptiveThreshold(
          divided,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY_INV,
          21,
          10.0,
        );
        break;

      default:
        result = src.clone();
    }

    final bool ok = cv.imwrite(args.outputPath, result);
    if (!ok) {
      throw StateError('Failed to write enhanced image: ${args.outputPath}');
    }
    return args.outputPath;
  } finally {
    temp1?.dispose();
    temp2?.dispose();
    divided?.dispose();
    bg?.dispose();
    result?.dispose();
    src.dispose();
  }
}
