import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';

typedef DetectCornersResult = ({int width, int height, List<double> flat, bool isDetected});
typedef WarpArgs = ({String path, List<double> flat, String outputPath});

/// Sync OpenCV paper edge detection — run only inside [Isolate.run].
/// Uses text-erasure morphological closing, multi-channel segmentation (Gaussian adaptive threshold,
/// Otsu, Canny, inverted adaptive, inverted Otsu), and smart document scoring.
DetectCornersResult detectCornersSync(String path) {
  final cv.Mat src = cv.imread(path);
  if (src.isEmpty) {
    throw StateError('OpenCV could not read image: $path');
  }

  cv.Mat? small;
  cv.Mat? gray;
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

    // 1. Gentle Gaussian blur preserves fine card perimeters without bridging nearby desk text
    blurred = cv.gaussianBlur(gray, (5, 5), 1.2);

    // 2. Multi-strategy edge maps for challenging environments (room lights, bright phone screens, shadows)
    final List<cv.Mat> edgeMaps = <cv.Mat>[
      _buildAdaptivePaperMask(blurred),
      _buildOtsuPaperMask(blurred),
      _buildCannyPaperEdges(blurred),
      _buildInvertedAdaptivePaperMask(blurred),
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
      return (width: origW, height: origH, flat: scaledQuad.toFlat(), isDetected: true);
    }

    // High-accuracy centered document/card framing fallback
    final ScanQuad fallback = origW < origH
        ? ScanQuad.centeredGuideRect(
            width: origW,
            height: origH,
            widthFraction: 0.80,
            aspectRatio: 1.586,
          )
        : ScanQuad.centeredGuideRect(
            width: origW,
            height: origH,
            widthFraction: 0.75,
            aspectRatio: 1.414,
          );
    return (width: origW, height: origH, flat: fallback.toFlat(), isDetected: false);
  } finally {
    blurred?.dispose();
    gray?.dispose();
    small?.dispose();
    src.dispose();
  }
}

/// Gaussian adaptive thresholding isolates document paper regardless of localized
/// lighting variations, shadows, or bright phone screens nearby.
cv.Mat _buildAdaptivePaperMask(cv.Mat blur) {
  final cv.Mat thresh = cv.adaptiveThreshold(
    blur,
    255,
    cv.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv.THRESH_BINARY,
    31,
    8.0,
  );
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(thresh, cv.MORPH_OPEN, kernel);
  thresh.dispose();
  kernel.dispose();
  return opened;
}

/// Inverted adaptive thresholding catches dark notebook covers or passports on bright tables.
cv.Mat _buildInvertedAdaptivePaperMask(cv.Mat blur) {
  final cv.Mat thresh = cv.adaptiveThreshold(
    blur,
    255,
    cv.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv.THRESH_BINARY_INV,
    31,
    8.0,
  );
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(thresh, cv.MORPH_OPEN, kernel);
  thresh.dispose();
  kernel.dispose();
  return opened;
}

/// Otsu thresholding segments bright paper on dark/medium backgrounds.
cv.Mat _buildOtsuPaperMask(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(thresh, cv.MORPH_OPEN, kernel);
  thresh.dispose();
  kernel.dispose();
  return opened;
}

/// Inverted Otsu segments dark documents or covers on bright desks.
cv.Mat _buildInvertedOtsuPaperMask(cv.Mat blur) {
  final (double _, cv.Mat thresh) = cv.threshold(blur, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU);
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat opened = cv.morphologyEx(thresh, cv.MORPH_OPEN, kernel);
  thresh.dispose();
  kernel.dispose();
  return opened;
}

/// Canny edge detection with subtle line-dilation to prevent breaking at corners.
cv.Mat _buildCannyPaperEdges(cv.Mat blur) {
  final cv.Mat edges = cv.canny(blur, 35, 110);
  final cv.Mat kernel3 = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
  final cv.Mat dilated = cv.dilate(edges, kernel3);
  edges.dispose();
  kernel3.dispose();
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

  // Safeguard: track largest valid convex candidate quad if strict scoring rejects all
  List<Offset>? largestValidQuad;
  double largestValidArea = 0.0;

  final double minArea = imageArea * 0.05;
  final double maxArea = imageArea * 0.98;

  for (final cv.Mat map in edgeMaps) {
    try {
      final (cv.Contours contours, cv.VecVec4i hierarchy) = cv.findContours(
        map,
        cv.RETR_LIST, // Catches document borders inside frame boundaries
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
        if (peri < 50) continue;

        // Try multiple approximation tolerances for crisp or slightly curved paper edges
        for (final double eps in <double>[0.015, 0.02, 0.025, 0.03, 0.04, 0.05, 0.06, 0.08]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          List<Offset>? candidatePts;

          if (approx.length == 4 && cv.isContourConvex(approx)) {
            candidatePts = <Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ];
          }
          approx.dispose();

          if (candidatePts == null || candidatePts.length != 4) {
            continue;
          }

          final List<Offset> ordered = orderQuadPoints(candidatePts);
          final double qArea = _polygonArea(ordered);

          // Track largest valid convex quad as safety fallback
          if (qArea >= minArea && qArea <= maxArea && qArea > largestValidArea) {
            final double rect = _evaluateRectangularity(ordered);
            if (rect >= 0.45) {
              largestValidArea = qArea;
              largestValidQuad = ordered;
            }
          }

          final double score = _scoreCandidateQuad(
            ordered,
            gray: gray,
            width: width,
            height: height,
            imageArea: imageArea,
          );

          if (score > bestScore) {
            bestScore = score;
            bestQuad = ordered;
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

  final List<Offset>? chosen = bestQuad ?? largestValidQuad;
  if (chosen == null) {
    return null;
  }

  // Ensure clockwise ordered points clamped to bounds
  final List<Offset> ordered = orderQuadPoints(chosen);
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
  if (areaRatio < 0.05 || areaRatio > 0.98) return -1.0;

  // 1. Border Check: Penalize frame touches smoothly (only reject if all 4 corners touch)
  int borderTouches = 0;
  const double margin = 6.0;
  for (final Offset pt in ord) {
    if (pt.dx <= margin || pt.dx >= width - margin || pt.dy <= margin || pt.dy >= height - margin) {
      borderTouches++;
    }
  }
  if (borderTouches >= 4) {
    return -1.0; // This is the camera frame, not the document
  }
  final double borderPenalty = (1.0 - borderTouches * 0.20).clamp(0.2, 1.0);

  // 2. Edge lengths and Symmetry Check
  final double topW = dist(ord[0], ord[1]);
  final double botW = dist(ord[3], ord[2]);
  final double leftH = dist(ord[0], ord[3]);
  final double rightH = dist(ord[1], ord[2]);
  if (topW <= 16 || botW <= 16 || leftH <= 16 || rightH <= 16) return -1.0;

  // Opposite sides must have reasonably symmetric lengths under perspective
  final double topBotRatio = math.min(topW, botW) / math.max(topW, botW);
  final double leftRightRatio = math.min(leftH, rightH) / math.max(leftH, rightH);
  if (topBotRatio < 0.65 || leftRightRatio < 0.65) return -1.0;

  // 3. Parallelism Check between opposite sides
  final Offset topVec = Offset(ord[1].dx - ord[0].dx, ord[1].dy - ord[0].dy);
  final Offset botVec = Offset(ord[2].dx - ord[3].dx, ord[2].dy - ord[3].dy);
  final Offset leftVec = Offset(ord[3].dx - ord[0].dx, ord[3].dy - ord[0].dy);
  final Offset rightVec = Offset(ord[2].dx - ord[1].dx, ord[2].dy - ord[1].dy);

  final double cosTB = ((topVec.dx * botVec.dx) + (topVec.dy * botVec.dy)) / (topW * botW);
  final double cosLR = ((leftVec.dx * rightVec.dx) + (leftVec.dy * rightVec.dy)) / (leftH * rightH);
  if (cosTB < 0.78 || cosLR < 0.78) return -1.0;

  // 4. Rectangularity: Corners should be reasonably close to 90 degrees (allows perspective skew)
  final double rectangularity = _evaluateRectangularity(ord);
  if (rectangularity < 0.45) return -1.0;

  // 5. Aspect Ratio: Standard books, documents, receipts, cards (0.20 to 4.5)
  final double avgW = (topW + botW) / 2.0;
  final double avgH = (leftH + rightH) / 2.0;
  final double aspect = avgW / avgH;
  if (aspect < 0.20 || aspect > 4.5) return -1.0;

  double aspectScore = 1.0;
  if (aspect >= 1.25 && aspect <= 1.85) {
    aspectScore = 2.6; // Standard ID Card landscape (1.586) or A4 landscape (1.414)
  } else if (aspect >= 0.55 && aspect <= 0.88) {
    aspectScore = 2.6; // Standard single portrait page (A4 portrait 0.707, book, document)
  } else if (aspect > 0.88 && aspect <= 1.25) {
    aspectScore = 1.4; // Square-ish document
  }

  // 4. Centrality: Documents are positioned near the center of the camera
  final double cx = (ord[0].dx + ord[1].dx + ord[2].dx + ord[3].dx) / (4.0 * width);
  final double cy = (ord[0].dy + ord[1].dy + ord[2].dy + ord[3].dy) / (4.0 * height);
  final double distCenter = math.sqrt((cx - 0.5) * (cx - 0.5) + (cy - 0.5) * (cy - 0.5));
  final double centrality = (1.0 - distCenter * 1.5).clamp(0.2, 1.0);

  // 5. Area Fitness: Prefers documents occupying 20% to 85% of the frame
  final double areaFitness = 1.0 - (areaRatio - 0.50).abs() * 0.6;

  // 6. Contrast Boost: Sample center luminance vs overall average
  double contrastBoost = 1.0;
  final int midX = (cx * width).round().clamp(0, width - 1);
  final int midY = (cy * height).round().clamp(0, height - 1);
  try {
    final int centerVal = gray.at<num>(midY, midX).toInt();
    if (centerVal > 125) {
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

    // Auto-perimeter de-fringing (insets 1.8% to eliminate desk slivers & crop shadows)
    final int ix = (outW * 0.018).round();
    final int iy = (outH * 0.018).round();
    final int cropW = outW - 2 * ix;
    final int cropH = outH - 2 * iy;
    final cv.Mat trimmed;
    if (cropW > 20 && cropH > 20) {
      final cv.Rect roi = cv.Rect(ix, iy, cropW, cropH);
      trimmed = cv.Mat.fromMat(warped, roi: roi);
    } else {
      trimmed = warped.clone();
    }

    final bool ok = cv.imwrite(args.outputPath, trimmed);
    trimmed.dispose();
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

/// Orders 4 corners to guaranteed clockwise [TL, TR, BR, BL] sorted around centroid.
List<Offset> orderQuadPoints(List<Offset> pts) {
  if (pts.length != 4) {
    return pts;
  }

  // 1. Calculate centroid
  final double cx = (pts[0].dx + pts[1].dx + pts[2].dx + pts[3].dx) / 4.0;
  final double cy = (pts[0].dy + pts[1].dy + pts[2].dy + pts[3].dy) / 4.0;

  // 2. Sort by polar angle around centroid
  final List<Offset> angular = List<Offset>.from(pts)
    ..sort((Offset a, Offset b) {
      final double angleA = math.atan2(a.dy - cy, a.dx - cx);
      final double angleB = math.atan2(b.dy - cy, b.dx - cx);
      return angleA.compareTo(angleB);
    });

  // 3. Find top-left-most corner (minimizing x + y)
  int minIdx = 0;
  double minSum = angular[0].dx + angular[0].dy;
  for (int i = 1; i < 4; i++) {
    final double sum = angular[i].dx + angular[i].dy;
    if (sum < minSum) {
      minSum = sum;
      minIdx = i;
    }
  }

  // 4. Rotate array cyclically so top-left is at index 0
  final List<Offset> rotated = <Offset>[
    angular[minIdx],
    angular[(minIdx + 1) % 4],
    angular[(minIdx + 2) % 4],
    angular[(minIdx + 3) % 4],
  ];

  // 5. Check if orientation is clockwise using cross product: (P1 - P0) x (P2 - P1)
  final double v1x = rotated[1].dx - rotated[0].dx;
  final double v1y = rotated[1].dy - rotated[0].dy;
  final double v2x = rotated[2].dx - rotated[1].dx;
  final double v2y = rotated[2].dy - rotated[1].dy;
  final double cross = (v1x * v2y) - (v1y * v2x);

  if (cross < 0) {
    // Counter-clockwise => swap 1 and 3 to enforce clockwise [TL, TR, BR, BL]
    return <Offset>[rotated[0], rotated[3], rotated[2], rotated[1]];
  }

  return rotated;
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

/// Apple-grade Vivid LUT: Punchy contrast, deep blacks, and brilliant clean highlights.
cv.Mat _buildVividLut() {
  final List<int> table = List<int>.generate(256, (int i) {
    if (i < 65) {
      return (i * 0.45).round();
    } else if (i < 145) {
      return (29.25 + (i - 65) * 0.95).round();
    } else if (i < 215) {
      return (105.25 + (i - 145) * 1.30).round();
    } else {
      return math.min(255, (196.25 + (i - 215) * 1.45).round());
    }
  });
  return cv.Mat.fromList(1, 256, cv.MatType.CV_8UC1, table);
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
  cv.Mat? temp1;
  cv.Mat? temp2;
  cv.Mat? blurMask;

  try {
    switch (args.filterName) {
      case 'original':
        result = src.clone();
        break;

      case 'magicEnhance':
      case 'color':
        // Premium color scan for ID cards & docs.
        // No morphology/divide bleach (that washed cards to white).
        // Pipeline: denoise → mild CLAHE → soft contrast → light vibrance → crisp unsharp.
        final cv.Mat denoised = cv.bilateralFilter(src, 5, 40, 40);
        final cv.Mat lab = cv.cvtColor(denoised, cv.COLOR_BGR2Lab);
        final cv.VecMat labChannels = cv.split(lab);

        final cv.CLAHE clahe =
            cv.createCLAHE(clipLimit: 1.35, tileGridSize: (8, 8));
        final cv.Mat lEq = clahe.apply(labChannels[0]);
        final cv.Mat lContrast =
            cv.convertScaleAbs(lEq, alpha: 1.08, beta: 3);

        // Keep card artwork colors; tiny vibrance only
        final cv.Mat aCh =
            cv.convertScaleAbs(labChannels[1], alpha: 1.06, beta: -7.68);
        final cv.Mat bCh =
            cv.convertScaleAbs(labChannels[2], alpha: 1.06, beta: -7.68);

        final cv.VecMat merged = cv.VecMat.fromList(<cv.Mat>[
          lContrast,
          aCh,
          bCh,
        ]);
        final cv.Mat color =
            cv.cvtColor(cv.merge(merged), cv.COLOR_Lab2BGR);

        blurMask = cv.gaussianBlur(color, (0, 0), 0.85);
        result = cv.addWeighted(color, 1.14, blurMask, -0.14, 0);

        denoised.dispose();
        lab.dispose();
        labChannels.dispose();
        clahe.dispose();
        lEq.dispose();
        lContrast.dispose();
        aCh.dispose();
        bCh.dispose();
        merged.dispose();
        color.dispose();
        break;

      case 'vivid':
        // APPLE-GRADE VIVID FILTER:
        final cv.Mat denoisedVivid = cv.bilateralFilter(src, 7, 35, 35);
        final cv.Mat labVivid = cv.cvtColor(denoisedVivid, cv.COLOR_BGR2Lab);
        final cv.VecMat labChs = cv.split(labVivid);
        final cv.Mat lChVivid = labChs[0];

        // Illumination leveling
        final int vKsize = (math.max(src.cols, src.rows) * 0.10).round() | 1;
        final cv.Mat vKernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (vKsize, vKsize));
        final cv.Mat vBg = cv.morphologyEx(lChVivid, cv.MORPH_DILATE, vKernel);
        final cv.Mat vBgBlur = cv.gaussianBlur(vBg, (vKsize, vKsize), 0);
        final cv.Mat vDivided = cv.divide(lChVivid, vBgBlur, scale: 248.0);

        final int vGridW = (src.cols ~/ 28).clamp(10, 20);
        final int vGridH = (src.rows ~/ 28).clamp(10, 20);
        final cv.CLAHE claheVivid = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (vGridW, vGridH));
        final cv.Mat lVividEq = claheVivid.apply(vDivided);

        // Vivid Deep Ink LUT
        final cv.Mat vLut = _buildVividLut();
        final cv.Mat lVividFinal = cv.LUT(lVividEq, vLut);

        // Apple Vibrance (+26% on A & B around neutral 128)
        final cv.Mat aVivid = cv.convertScaleAbs(labChs[1], alpha: 1.26, beta: -33.28);
        final cv.Mat bVivid = cv.convertScaleAbs(labChs[2], alpha: 1.26, beta: -33.28);

        final cv.VecMat mergedVivid = cv.VecMat.fromList(<cv.Mat>[
          lVividFinal,
          aVivid,
          bVivid,
        ]);
        final cv.Mat colorVivid = cv.cvtColor(cv.merge(mergedVivid), cv.COLOR_Lab2BGR);

        // Micro-unsharp mask
        blurMask = cv.gaussianBlur(colorVivid, (0, 0), 0.75);
        result = cv.addWeighted(colorVivid, 1.35, blurMask, -0.35, 0);

        denoisedVivid.dispose();
        labVivid.dispose();
        labChs.dispose();
        vKernel.dispose();
        vBg.dispose();
        vBgBlur.dispose();
        vDivided.dispose();
        claheVivid.dispose();
        lVividEq.dispose();
        vLut.dispose();
        lVividFinal.dispose();
        aVivid.dispose();
        bVivid.dispose();
        mergedVivid.dispose();
        colorVivid.dispose();
        break;

      case 'bw':
      case 'bwPrint':
        // ADAPTIVE THRESHOLD PHOTOCOPY:
        final cv.Mat denoisedBw = cv.bilateralFilter(src, 7, 30, 30);
        final cv.Mat grayBw = cv.cvtColor(denoisedBw, cv.COLOR_BGR2GRAY);
        result = cv.adaptiveThreshold(
          grayBw,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          25,
          15.0,
        );
        denoisedBw.dispose();
        grayBw.dispose();
        break;

      case 'grayscale':
      case 'gray':
        // GRAYSCALE (CLAHE ON DENOISED LUMINANCE WITH ZERO-HALO SMOOTHING):
        final cv.Mat denoisedGray = cv.bilateralFilter(src, 7, 30, 30);
        temp1 = cv.cvtColor(denoisedGray, cv.COLOR_BGR2GRAY);
        final int gGridW = (src.cols ~/ 30).clamp(12, 24);
        final int gGridH = (src.rows ~/ 30).clamp(12, 24);
        final cv.CLAHE claheGray = cv.createCLAHE(clipLimit: 1.25, tileGridSize: (gGridW, gGridH));
        final cv.Mat grayEq = claheGray.apply(temp1);
        result = cv.convertScaleAbs(grayEq, alpha: 1.06, beta: 4);
        denoisedGray.dispose();
        claheGray.dispose();
        grayEq.dispose();
        break;

      case 'lighten':
        // LIGHTEN: Brightens image, clears light shadows, studio light box look
        final cv.Mat denoisedLt = cv.bilateralFilter(src, 5, 35, 35);
        result = cv.convertScaleAbs(denoisedLt, alpha: 1.15, beta: 15);
        denoisedLt.dispose();
        break;

      case 'noShadow':
        // NO SHADOW: Soft background leveling preserving delicate pencil, stamps, and signatures
        final cv.Mat denoisedNs = cv.bilateralFilter(src, 7, 40, 40);
        final cv.Mat labNs = cv.cvtColor(denoisedNs, cv.COLOR_BGR2Lab);
        final cv.VecMat labChannelsNs = cv.split(labNs);
        final cv.CLAHE claheNs = cv.createCLAHE(clipLimit: 1.5, tileGridSize: (8, 8));
        final cv.Mat lEnhancedNs = claheNs.apply(labChannelsNs[0]);
        final cv.VecMat mergedLabNs = cv.VecMat.fromList(<cv.Mat>[
          lEnhancedNs,
          labChannelsNs[1],
          labChannelsNs[2],
        ]);
        result = cv.cvtColor(cv.merge(mergedLabNs), cv.COLOR_Lab2BGR);
        denoisedNs.dispose();
        labNs.dispose();
        labChannelsNs.dispose();
        claheNs.dispose();
        lEnhancedNs.dispose();
        mergedLabNs.dispose();
        break;

      case 'invert':
        // INVERT: White text on dark background
        final cv.Mat denoisedInv = cv.bilateralFilter(src, 7, 50, 50);
        temp1 = cv.cvtColor(denoisedInv, cv.COLOR_BGR2GRAY);
        temp2 = cv.gaussianBlur(temp1, (3, 3), 0);
        result = cv.adaptiveThreshold(
          temp2,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY_INV,
          25,
          11.0,
        );
        denoisedInv.dispose();
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
    blurMask?.dispose();
    temp1?.dispose();
    temp2?.dispose();
    result?.dispose();
    src.dispose();
  }
}

/// Manual adjustment layer — driven by UI brightness/contrast/sharpness adjustments.
class ManualAdjust {
  const ManualAdjust._();

  static cv.Mat apply(
    cv.Mat input, {
    double brightness = 0, // -100 to 100
    double contrast = 1.0, // 0.5 to 2.0
    double sharpness = 0, // 0 to 2.0
  }) {
    cv.Mat result = cv.convertScaleAbs(input, alpha: contrast, beta: brightness);

    if (sharpness > 0) {
      final cv.Mat gaussian = cv.gaussianBlur(result, (0, 0), 1.0);
      final double weight = (sharpness * 0.35).clamp(0.0, 0.70);
      final cv.Mat sharpened = cv.addWeighted(
        result,
        1.0 + weight,
        gaussian,
        -weight,
        0,
      );
      gaussian.dispose();
      result.dispose();
      result = sharpened;
    }
    return result;
  }
}

