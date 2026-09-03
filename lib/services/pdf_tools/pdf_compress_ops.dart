import 'dart:ui';

import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/pdf_io.dart';
import 'package:scanner_app/services/pdf_tools/pdf_rasterize_ops.dart';
import 'package:scanner_app/services/pdf_tools/rasterized_pdf_page.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Rasterize → JPEG compress → rebuild PDF.
abstract final class PdfCompressOps {
  static Future<void> compress({
    required String pdfPath,
    required String outputPath,
  }) async {
    final List<RasterizedPdfPage> pages =
        await PdfRasterizeOps.rasterize(pdfPath: pdfPath);

    final PdfDocument output = PdfDocument();
    try {
      for (final RasterizedPdfPage page in pages) {
        final PdfSection section = output.sections!.add();
        section.pageSettings.size = page.pageSize;
        section.pageSettings.margins.all = 0;

        final PdfBitmap bitmap = PdfBitmap(page.jpegBytes);
        section.pages.add().graphics.drawImage(
          bitmap,
          Rect.fromLTWH(0, 0, page.pageSize.width, page.pageSize.height),
        );
      }
      await PdfIo.writeToPath(output, outputPath);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to compress PDF.', cause: error);
    } finally {
      output.dispose();
    }
  }
}
