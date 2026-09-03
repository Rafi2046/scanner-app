import 'dart:typed_data';
import 'dart:ui';

import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/pdf_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Stamps a PNG signature onto a specific PDF page (1-based page index).
abstract final class PdfSignatureStampOps {
  static const double _stampWidth = 140;
  static const double _margin = 36;

  static Future<void> stamp({
    required String pdfPath,
    required Uint8List signaturePng,
    required int pageNumber,
    required String outputPath,
  }) async {
    if (signaturePng.isEmpty) {
      throw const PdfException('Signature image is empty.');
    }

    final PdfDocument document = await PdfIo.loadFromPath(pdfPath);
    try {
      if (document.pages.count == 0) {
        throw const PdfException('The PDF has no pages.');
      }

      final int lastPage = document.pages.count;
      final int safePage = pageNumber < 1
          ? 1
          : (pageNumber > lastPage ? lastPage : pageNumber);
      final PdfPage page = document.pages[safePage - 1];
      final Size pageSize = page.getClientSize();
      final PdfBitmap bitmap = PdfBitmap(signaturePng);

      final double aspect = bitmap.height <= 0
          ? 0.4
          : bitmap.height / bitmap.width;
      final double stampHeight = _stampWidth * aspect;

      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(
          pageSize.width - _stampWidth - _margin,
          pageSize.height - stampHeight - _margin,
          _stampWidth,
          stampHeight,
        ),
      );

      await PdfIo.writeToPath(document, outputPath);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to stamp signature.', cause: error);
    } finally {
      document.dispose();
    }
  }
}
