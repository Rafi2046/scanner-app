import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/services/spine_detector_ops.dart';

/// Fast OpenCV live document contour detector running on camera frames.
/// Normalized coordinates (0..1) in the portrait viewfinder space.
class LiveDocumentDetector {
  bool _isProcessing = false;

  Future<ScanQuad?> detectLiveDocument(
    CameraImage image,
    int sensorOrientation,
  ) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    cv.Mat? small;
    cv.Mat? rotated;
    cv.Mat? blurred;
    cv.Mat? edged;
    cv.Mat? dilated;
    cv.Mat? kernel;
    cv.Contours? contours;
    cv.VecVec4i? hierarchy;

    try {
      if (image.planes.isEmpty) return null;

      final int srcW = image.width;
      final int srcH = image.height;
      final plane = image.planes[0];
      final Uint8List bytes = plane.bytes;
      final int stride = plane.bytesPerRow;

      // 4x subsampling for fast real-time processing (<5ms)
      const int step = 4;
      final int outW = srcW ~/ step;
      final int outH = srcH ~/ step;
      final Uint8List smallBytes = Uint8List(outW * outH);

      int dst = 0;
      for (int y = 0; y < outH; y++) {
        final int rowOff = (y * step) * stride;
        for (int x = 0; x < outW; x++) {
          final int idx = rowOff + x * step;
          smallBytes[dst++] = idx < bytes.length ? bytes[idx] : 128;
        }
      }

      small = cv.Mat.fromList(outH, outW, cv.MatType.CV_8UC1, smallBytes);

      cv.Mat target = small;
      if (sensorOrientation == 90) {
        rotated = cv.rotate(small, cv.ROTATE_90_CLOCKWISE);
        target = rotated;
      } else if (sensorOrientation == 270) {
        rotated = cv.rotate(small, cv.ROTATE_90_COUNTERCLOCKWISE);
        target = rotated;
      }

      final int fW = target.cols;
      final int fH = target.rows;

      blurred = cv.gaussianBlur(target, (5, 5), 1.5);
      edged = cv.canny(blurred, 20, 70);

      kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      dilated = cv.dilate(edged, kernel);

      final (cv.Contours found, cv.VecVec4i hier) = cv.findContours(
        dilated, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE,
      );
      contours = found;
      hierarchy = hier;

      double bestScore = 0;
      ScanQuad? bestQuad;
      final double minArea = fW * fH * 0.05;
      final double maxArea = fW * fH * 0.96;

      for (int i = 0; i < contours.length; i++) {
        final cv.VecPoint contour = contours[i];
        final double area = cv.contourArea(contour);
        if (area < minArea || area > maxArea) continue;

        final double peri = cv.arcLength(contour, true);

        for (final double eps in <double>[0.02, 0.035, 0.05, 0.075]) {
          final cv.VecPoint approx = cv.approxPolyDP(contour, eps * peri, true);
          if (approx.length == 4 && cv.isContourConvex(approx)) {
            final List<Offset> pts = <Offset>[
              for (int k = 0; k < 4; k++)
                Offset(approx[k].x.toDouble(), approx[k].y.toDouble()),
            ];
            approx.dispose();

            final List<Offset> ord = SpineDetectorOps.orderPoints(pts);
            final double qW = (ord[1].dx - ord[0].dx).abs();
            final double qH = (ord[2].dy - ord[1].dy).abs();
            final double aspect = qW / (qH > 0 ? qH : 1.0);

            final double cx = (ord[0].dx + ord[2].dx) / (2 * fW);
            final double cy = (ord[0].dy + ord[2].dy) / (2 * fH);
            final double dist = math.sqrt((cx - 0.5) * (cx - 0.5) + (cy - 0.5) * (cy - 0.5));
            final double centrality = (1.0 - dist * 1.6).clamp(0.1, 1.0);

            double aspectScore;
            if (aspect >= 0.50 && aspect <= 0.88) {
              aspectScore = 4.0; // single portrait page
            } else if (aspect > 0.88 && aspect <= 1.15) {
              aspectScore = 2.0; // square document
            } else if (aspect > 1.15 && aspect <= 1.80) {
              aspectScore = 1.0; // wide spread
            } else {
              aspectScore = 0.3;
            }

            final double score = aspectScore * centrality * (area / (fW * fH));
            if (score > bestScore) {
              bestScore = score;
              bestQuad = ScanQuad(
                topLeft: Offset(ord[0].dx / fW, ord[0].dy / fH),
                topRight: Offset(ord[1].dx / fW, ord[1].dy / fH),
                bottomRight: Offset(ord[2].dx / fW, ord[2].dy / fH),
                bottomLeft: Offset(ord[3].dx / fW, ord[3].dy / fH),
              );
            }
            break;
          } else {
            approx.dispose();
          }
        }
      }

      if (bestQuad != null) {
        // If wide open book, isolate dominant single page
        final double qW = (bestQuad.topRight.dx - bestQuad.topLeft.dx).abs();
        final double qH = (bestQuad.bottomRight.dy - bestQuad.topRight.dy).abs();
        if (qW / (qH > 0 ? qH : 1.0) > 0.90) {
          bestQuad = SpineDetectorOps.isolateDominantPage(
            quad: bestQuad,
            bytes: bytes,
            outW: outW,
            outH: outH,
            frameW: fW,
            frameH: fH,
            sensorOrientation: sensorOrientation,
          );
        }
      }

      return bestQuad;
    } catch (e) {
      debugPrint('LiveDetector error: $e');
      return null;
    } finally {
      hierarchy?.dispose();
      contours?.dispose();
      kernel?.dispose();
      dilated?.dispose();
      edged?.dispose();
      blurred?.dispose();
      rotated?.dispose();
      small?.dispose();
      _isProcessing = false;
    }
  }
}
