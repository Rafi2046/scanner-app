import 'dart:io';
import 'dart:ui';

import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/pdf_image_fit.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Offline PDF generation: ID-card A4 layout and multi-page image documents.
class PdfService {
  const PdfService();

  static const double _idCardGapPoints = 28;

  /// Places front (top) and back (bottom) ID images on a single A4 page.
  Future<String> createIdCardA4({
    required String frontImagePath,
    required String backImagePath,
    required String outputPath,
  }) async {
    PdfDocument? document;
    try {
      final PdfBitmap front = await _loadBitmap(frontImagePath);
      final PdfBitmap back = await _loadBitmap(backImagePath);

      document = PdfDocument();
      document.pageSettings.size = PdfImageFit.a4;
      document.pageSettings.margins.all = 0;

      final PdfPage page = document.pages.add();
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
  }) async {
    PdfDocument? document;
    try {
      final PdfBitmap bitmap = await _loadBitmap(imagePath);

      document = PdfDocument();
      document.pageSettings.size = PdfImageFit.a4;
      document.pageSettings.margins.all = 0;

      final PdfPage page = document.pages.add();
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
