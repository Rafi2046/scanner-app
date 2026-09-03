import 'dart:ui';

import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/pdf_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Combines multiple PDFs into a single document.
abstract final class PdfMergeOps {
  static Future<void> merge({
    required List<String> pdfPaths,
    required String outputPath,
  }) async {
    if (pdfPaths.length < 2) {
      throw const PdfException('Select at least two PDFs to merge.');
    }

    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;
    PdfSection? section;

    try {
      for (final String path in pdfPaths) {
        final PdfDocument loaded = await PdfIo.loadFromPath(path);
        try {
          for (int index = 0; index < loaded.pages.count; index++) {
            final PdfTemplate template = loaded.pages[index].createTemplate();
            final Size templateSize = template.size;

            if (section == null || section.pageSettings.size != templateSize) {
              section = output.sections!.add();
              section.pageSettings.size = templateSize;
              section.pageSettings.margins.all = 0;
            }

            section.pages.add().graphics.drawPdfTemplate(
              template,
              Offset.zero,
            );
          }
        } finally {
          loaded.dispose();
        }
      }

      await PdfIo.writeToPath(output, outputPath);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to merge PDFs.', cause: error);
    } finally {
      output.dispose();
    }
  }
}
