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

    // High-margin fallback: 4% inset when paper covers full frame or cannot be segmented
    final ScanQuad fallback = ScanQuad.insetRect(
      width: origW,
      height: origH,
      insetFraction: 0.04,
    );
    return (width: origW, height: origH, flat: fallback.toFlat(), isDetected: false);
  } finally {
    blurred?.dispose();
    textErased?.dispose();
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
    35,
    7.0,
  );
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
  thresh.dispose();
  kernel.dispose();
  return closed;
}

/// Inverted adaptive thresholding catches dark notebook covers or passports on bright tables.
cv.Mat _buildInvertedAdaptivePaperMask(cv.Mat blur) {
  final cv.Mat thresh = cv.adaptiveThreshold(
    blur,
    255,
    cv.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv.THRESH_BINARY_INV,
    35,
    7.0,
  );
  final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
  final cv.Mat closed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
  thresh.dispose();
  kernel.dispose();
  return closed;
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
  final cv.Mat kernel5 = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
  final cv.Mat kernel3 = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
  final cv.Mat closed = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel5);
  final cv.Mat dilated = cv.dilate(closed, kernel3);
  edges.dispose();
  closed.dispose();
  kernel5.dispose();
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
        for (final double eps in <double>[0.015, 0.02, 0.03, 0.04, 0.05, 0.075, 0.10]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          List<Offset>? candidatePts;

          if (approx.length == 4 && cv.isContourConvex(approx)) {
            candidatePts = <Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ];
          } else if (approx.length >= 4) {
            candidatePts = _extractFourCornersFromPoly(approx, width: width, height: height);
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
            if (rect >= 0.18) {
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

  // 2. Rectangularity: Corners should be reasonably close to 90 degrees (allows perspective skew)
  final double rectangularity = _evaluateRectangularity(ord);
  if (rectangularity < 0.18) return -1.0;

  // 3. Aspect Ratio: Standard books, documents, receipts, cards (0.20 to 4.5)
  final double topW = dist(ord[0], ord[1]);
  final double botW = dist(ord[3], ord[2]);
  final double leftH = dist(ord[0], ord[3]);
  final double rightH = dist(ord[1], ord[2]);
  final double avgW = (topW + botW) / 2.0;
  final double avgH = (leftH + rightH) / 2.0;
  if (avgW <= 12 || avgH <= 12) return -1.0;

  final double aspect = avgW / avgH;
  if (aspect < 0.20 || aspect > 4.5) return -1.0;

  double aspectScore = 1.0;
  if (aspect >= 0.45 && aspect <= 0.90) {
    aspectScore = 2.5; // Standard single portrait page (A4, book, document)
  } else if (aspect > 0.90 && aspect <= 1.30) {
    aspectScore = 1.8; // Square document
  } else if (aspect > 1.30 && aspect <= 2.2) {
    aspectScore = 2.0; // Open two-page spread or landscape document
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

/// Extracts 4 extreme corners from a polygon approximation along diagonal axes relative to centroid.
List<Offset>? _extractFourCornersFromPoly(
  cv.VecPoint pts, {
  required int width,
  required int height,
}) {
  final int count = pts.length;
  if (count < 4) return null;

  final List<Offset> points = <Offset>[
    for (int i = 0; i < count; i++)
      Offset(pts[i].x.toDouble(), pts[i].y.toDouble()),
  ];

  // Centroid
  double cx = 0;
  double cy = 0;
  for (final Offset p in points) {
    cx += p.dx;
    cy += p.dy;
  }
  cx /= count;
  cy /= count;

  // Find 4 points maximizing projection into the 4 quadrants:
  // NW (top-left): -dx - dy
  // NE (top-right): +dx - dy
  // SE (bottom-right): +dx + dy
  // SW (bottom-left): -dx + dy
  Offset? bestTL;
  double scoreTL = -double.infinity;
  Offset? bestTR;
  double scoreTR = -double.infinity;
  Offset? bestBR;
  double scoreBR = -double.infinity;
  Offset? bestBL;
  double scoreBL = -double.infinity;

  for (final Offset p in points) {
    final double dx = p.dx - cx;
    final double dy = p.dy - cy;

    final double sTL = -dx - dy;
    if (sTL > scoreTL) {
      scoreTL = sTL;
      bestTL = p;
    }

    final double sTR = dx - dy;
    if (sTR > scoreTR) {
      scoreTR = sTR;
      bestTR = p;
    }

    final double sBR = dx + dy;
    if (sBR > scoreBR) {
      scoreBR = sBR;
      bestBR = p;
    }

    final double sBL = -dx + dy;
    if (sBL > scoreBL) {
      scoreBL = sBL;
      bestBL = p;
    }
  }

  if (bestTL == null || bestTR == null || bestBR == null || bestBL == null) {
    return null;
  }

  // Ensure 4 distinct corners
  if (dist(bestTL, bestTR) < 12 ||
      dist(bestTR, bestBR) < 12 ||
      dist(bestBR, bestBL) < 12 ||
      dist(bestBL, bestTL) < 12) {
    return null;
  }

  return orderQuadPoints(<Offset>[bestTL, bestTR, bestBR, bestBL]);
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
        // CAMSCANNER "MAGIC ENHANCE" (6-STAGE TRUE-COLOR PIPELINE):
        // 1. Bilateral Denoising: Preserves text edges while eliminating CMOS sensor noise
        final cv.Mat denoised = cv.bilateralFilter(src, 7, 50, 50);

        // 2. LAB Color Space: Separates Luminance (L) from Chrominance (A: green-red, B: blue-yellow)
        final cv.Mat lab = cv.cvtColor(denoised, cv.COLOR_BGR2Lab);
        final cv.VecMat labChannels = cv.split(lab);

        // 3. CLAHE on L channel only: Equalizes local illumination gradients without shifting colors,
        // preventing yellow burn halos on seals/emblems and preserving natural skin tones.
        final cv.CLAHE clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
        final cv.Mat lEnhanced = clahe.apply(labChannels[0]);
        final cv.VecMat mergedLab = cv.VecMat.fromList(<cv.Mat>[
          lEnhanced,
          labChannels[1],
          labChannels[2],
        ]);
        final cv.Mat colorLab = cv.cvtColor(cv.merge(mergedLab), cv.COLOR_Lab2BGR);

        // 4. Subtle Ink Contrast (alpha: 1.06, beta: 0 - zero destructive channel clipping)
        temp1 = cv.convertScaleAbs(colorLab, alpha: 1.06, beta: 0);

        // 5. Unsharp Mask: Enhances high-frequency edge gradients for razor-sharp Bengali/English legibility
        blurMask = cv.gaussianBlur(temp1, (0, 0), 2.0);
        result = cv.addWeighted(temp1, 1.35, blurMask, -0.35, 0);

        denoised.dispose();
        lab.dispose();
        labChannels.dispose();
        clahe.dispose();
        lEnhanced.dispose();
        mergedLab.dispose();
        colorLab.dispose();
        break;

      case 'bw':
      case 'bwPrint':
        // CAMSCANNER "BW PRINT" (ADAPTIVE THRESHOLD PHOTOCOPY):
        final cv.Mat denoisedBw = cv.bilateralFilter(src, 7, 50, 50);
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
        // CAMSCANNER "GRAYSCALE" (SMOOTH MONOCHROME WITH PHOTOS/SEALS):
        final cv.Mat denoisedGray = cv.bilateralFilter(src, 7, 50, 50);
        temp1 = cv.cvtColor(denoisedGray, cv.COLOR_BGR2GRAY);
        final cv.CLAHE claheGray = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
        temp2 = claheGray.apply(temp1);
        blurMask = cv.gaussianBlur(temp2, (0, 0), 2.0);
        result = cv.addWeighted(temp2, 1.30, blurMask, -0.30, 0);
        denoisedGray.dispose();
        claheGray.dispose();
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
