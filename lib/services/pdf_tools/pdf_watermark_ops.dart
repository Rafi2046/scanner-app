import 'dart:ui';

import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/pdf_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Draws a rotated, semi-transparent text watermark on every page.
abstract final class PdfWatermarkOps {
  static Future<void> addText({
    required String pdfPath,
    required String text,
    required String outputPath,
  }) async {
    final String watermark = text.trim();
    if (watermark.isEmpty) {
      throw const PdfException('Watermark text cannot be empty.');
    }

    final PdfDocument document = await PdfIo.loadFromPath(pdfPath);
    try {
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 48);
      final Size textSize = font.measureString(watermark);

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final Size pageSize = page.getClientSize();
        final PdfGraphics graphics = page.graphics;

        graphics.save();
        graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
        graphics.setTransparency(0.22);
        graphics.rotateTransform(-40);
        graphics.drawString(
          watermark,
          font,
          brush: PdfBrushes.gray,
          bounds: Rect.fromLTWH(
            -textSize.width / 2,
            -textSize.height / 2,
            textSize.width,
            textSize.height,
          ),
        );
        graphics.restore();
      }

      await PdfIo.writeToPath(document, outputPath);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to add watermark.', cause: error);
    } finally {
      document.dispose();
    }
  }
}
