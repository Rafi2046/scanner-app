import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/pdf_image_fit.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Offline PDF generation: ID-card A4 layout and multi-page image documents.
class PdfService {
  const PdfService();

  static const double _idCardGapPoints = 28;

  /// Composes front (top) and optional back (bottom) ID images onto A4 (clean photocopy layout).
  Future<String> createIdCardA4CompositeImage({
    required String frontImagePath,
    String? backImagePath,
    required String outputPath,
  }) async {
    return await Isolate.run(() {
      const int a4Width = 1414;
      const int a4Height = 2000;
      // ISO ID-1 card at ~55% A4 width (premium photocopy margins).
      const int targetCardW = 778;
      const int targetCardH = 490;
      const int cornerRadius = 29;
      final int dstX = ((a4Width - targetCardW) / 2).round();

      final img.Image canvas = img.Image(width: a4Width, height: a4Height);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      img.Image? prepare(String path) {
        final img.Image? raw = img.decodeImage(File(path).readAsBytesSync());
        if (raw == null) {
          return null;
        }
        final img.Image clean = _cleanAndTrimCard(raw);
        return _resizeCardIntoBox(clean, targetCardW, targetCardH);
      }

      final img.Image? frontCard = prepare(frontImagePath);
      final bool hasBack = backImagePath != null &&
          backImagePath.isNotEmpty &&
          File(backImagePath).existsSync();
      final img.Image? backCard = hasBack ? prepare(backImagePath) : null;

      if (frontCard != null) {
        final int frontY = backCard != null
            ? 250
            : ((a4Height - frontCard.height) / 2).round();
        _drawRoundedCard(
          dst: canvas,
          src: frontCard,
          dstX: dstX + ((targetCardW - frontCard.width) / 2).round(),
          dstY: frontY,
          radius: cornerRadius,
        );
      }
      if (backCard != null) {
        _drawRoundedCard(
          dst: canvas,
          src: backCard,
          dstX: dstX + ((targetCardW - backCard.width) / 2).round(),
          dstY: 1070,
          radius: cornerRadius,
        );
      }

      final Uint8List jpg =
          Uint8List.fromList(img.encodeJpg(canvas, quality: 96));
      File(outputPath).writeAsBytesSync(jpg, flush: true);
      return outputPath;
    });
  }

  /// Fit card into max box without distorting aspect ratio.
  static img.Image _resizeCardIntoBox(img.Image src, int maxW, int maxH) {
    final double scale = math.min(maxW / src.width, maxH / src.height);
    final int w = math.max(1, (src.width * scale).round());
    final int h = math.max(1, (src.height * scale).round());
    return img.copyResize(
      src,
      width: w,
      height: h,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Mild edge trim — enough to drop desk fringe, not enough to lose text.
  static img.Image _cleanAndTrimCard(img.Image raw) {
    final int insetX = math.max(2, (raw.width * 0.012).round());
    final int insetY = math.max(2, (raw.height * 0.012).round());
    final int cropW = raw.width - (2 * insetX);
    final int cropH = raw.height - (2 * insetY);
    if (cropW <= 20 || cropH <= 20) {
      return raw;
    }
    return img.copyCrop(
      raw,
      x: insetX,
      y: insetY,
      width: cropW,
      height: cropH,
    );
  }

  static void _drawRoundedCard({
    required img.Image dst,
    required img.Image src,
    required int dstX,
    required int dstY,
    required int radius,
  }) {
    final int w = src.width;
    final int h = src.height;
    final double r = radius.toDouble();

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double dist = 0.0;
        bool inCorner = false;

        if (x < radius && y < radius) {
          inCorner = true;
          final double dx = r - x;
          final double dy = r - y;
          dist = math.sqrt(dx * dx + dy * dy);
        } else if (x >= w - radius && y < radius) {
          inCorner = true;
          final double dx = x - (w - 1 - r);
          final double dy = r - y;
          dist = math.sqrt(dx * dx + dy * dy);
        } else if (x < radius && y >= h - radius) {
          inCorner = true;
          final double dx = r - x;
          final double dy = y - (h - 1 - r);
          dist = math.sqrt(dx * dx + dy * dy);
        } else if (x >= w - radius && y >= h - radius) {
          inCorner = true;
          final double dx = x - (w - 1 - r);
          final double dy = y - (h - 1 - r);
          dist = math.sqrt(dx * dx + dy * dy);
        }

        if (inCorner) {
          if (dist > r) continue;
          final double alpha = (r - dist).clamp(0.0, 1.0);
          final img.Pixel sp = src.getPixel(x, y);
          final int rVal = (sp.r * alpha + 255 * (1.0 - alpha)).round().clamp(0, 255);
          final int gVal = (sp.g * alpha + 255 * (1.0 - alpha)).round().clamp(0, 255);
          final int bVal = (sp.b * alpha + 255 * (1.0 - alpha)).round().clamp(0, 255);
          dst.setPixelRgb(dstX + x, dstY + y, rVal, gVal, bVal);
        } else {
          dst.setPixel(dstX + x, dstY + y, src.getPixel(x, y));
        }
      }
    }
  }

  /// Places front (top) and back (bottom) ID images on a single A4 page.
  Future<String> createIdCardA4({
    required String frontImagePath,
    required String backImagePath,
    required String outputPath,
    String? compositeA4ImagePath,
  }) async {
    PdfDocument? document;
    try {
      document = PdfDocument();
      document.pageSettings.size = PdfImageFit.a4;
      document.pageSettings.margins.all = 0;

      final PdfPage page = document.pages.add();

      if (compositeA4ImagePath != null && File(compositeA4ImagePath).existsSync()) {
        final PdfBitmap composite = await _loadBitmap(compositeA4ImagePath);
        page.graphics.drawImage(
          composite,
          Rect.fromLTWH(0, 0, PdfImageFit.a4.width, PdfImageFit.a4.height),
        );
      } else {
        final PdfBitmap front = await _loadBitmap(frontImagePath);
        final PdfBitmap back = await _loadBitmap(backImagePath);
        final ({Rect frontSlot, Rect backSlot}) slots = PdfImageFit.idCardSlots(
          pageSize: PdfImageFit.a4,
          margin: AppConstants.pdfMarginPoints,
          gap: _idCardGapPoints,
        );

        page.graphics.drawImage(
          front,
          PdfImageFit.containCentered(
            imageSize: Size(front.width.toDouble(), front.height.toDouble()),
            slot: slots.frontSlot,
          ),
        );
        page.graphics.drawImage(
          back,
          PdfImageFit.containCentered(
            imageSize: Size(back.width.toDouble(), back.height.toDouble()),
            slot: slots.backSlot,
          ),
        );
      }

      await _writeDocument(document, outputPath);
      return outputPath;
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException(
        'Failed to create ID card A4 PDF.',
        cause: error,
      );
    } finally {
      document?.dispose();
    }
  }

  /// Places a single ID / passport / certificate image centered on an A4 page.
  Future<String> createSingleCardA4({
    required String imagePath,
    required String outputPath,
    String? compositeA4ImagePath,
  }) async {
    PdfDocument? document;
    try {
      document = PdfDocument();
      document.pageSettings.size = PdfImageFit.a4;
      document.pageSettings.margins.all = 0;

      final PdfPage page = document.pages.add();

      if (compositeA4ImagePath != null && File(compositeA4ImagePath).existsSync()) {
        final PdfBitmap composite = await _loadBitmap(compositeA4ImagePath);
        page.graphics.drawImage(
          composite,
          Rect.fromLTWH(0, 0, PdfImageFit.a4.width, PdfImageFit.a4.height),
        );
      } else {
        final PdfBitmap bitmap = await _loadBitmap(imagePath);
        final Rect slot = PdfImageFit.singleCardSlot(
          pageSize: PdfImageFit.a4,
          margin: AppConstants.pdfMarginPoints,
        );

        page.graphics.drawImage(
          bitmap,
          PdfImageFit.containCentered(
            imageSize: Size(bitmap.width.toDouble(), bitmap.height.toDouble()),
            slot: slot,
          ),
        );
      }

      await _writeDocument(document, outputPath);
      return outputPath;
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException(
        'Failed to create single card A4 PDF.',
        cause: error,
      );
    } finally {
      document?.dispose();
    }
  }

  /// Builds a multi-page A4 PDF, one scanned image per page, aspect ratio preserved.
  Future<String> createDocumentPdfFromImages({
    required List<String> imagePaths,
    required String outputPath,
  }) async {
    if (imagePaths.isEmpty) {
      throw const PdfException('Cannot create a PDF from an empty image list.');
    }

    PdfDocument? document;
    try {
      document = PdfDocument();
      document.pageSettings.size = PdfImageFit.a4;
      document.pageSettings.margins.all = 0;

      const double margin = AppConstants.pdfMarginPoints;
      final Rect pageSlot = Rect.fromLTWH(
        margin,
        margin,
        PdfImageFit.a4.width - (margin * 2),
        PdfImageFit.a4.height - (margin * 2),
      );

      for (final String imagePath in imagePaths) {
        final PdfBitmap bitmap = await _loadBitmap(imagePath);
        final PdfPage page = document.pages.add();
        page.graphics.drawImage(
          bitmap,
          PdfImageFit.containCentered(
            imageSize: Size(
              bitmap.width.toDouble(),
              bitmap.height.toDouble(),
            ),
            slot: pageSlot,
          ),
        );
      }

      await _writeDocument(document, outputPath);
      return outputPath;
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException(
        'Failed to create document PDF from images.',
        cause: error,
      );
    } finally {
      document?.dispose();
    }
  }

  Future<PdfBitmap> _loadBitmap(String path) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        throw PdfException('Image file does not exist: $path');
      }
      final List<int> bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw PdfException('Image file is empty: $path');
      }
      return PdfBitmap(bytes);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException(
        'Failed to load image: $path',
        cause: error,
      );
    }
  }

  Future<void> _writeDocument(PdfDocument document, String outputPath) async {
    try {
      final List<int> bytes = await document.save();
      final File outFile = File(outputPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes, flush: true);
    } catch (error) {
      throw PdfException(
        'Failed to write PDF to $outputPath.',
        cause: error,
      );
    }
  }
}
