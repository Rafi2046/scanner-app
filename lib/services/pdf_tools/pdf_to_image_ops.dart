import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/services/pdf_tools/pdf_rasterize_ops.dart';
import 'package:scanner_app/services/pdf_tools/rasterized_pdf_page.dart';

/// Exports each PDF page as a JPEG file.
abstract final class PdfToImageOps {
  static Future<List<String>> export({
    required String pdfPath,
    required String outputDirPath,
  }) async {
    try {
      final Directory dir = Directory(outputDirPath);
      await dir.create(recursive: true);

      final List<RasterizedPdfPage> pages = await PdfRasterizeOps.rasterize(
        pdfPath: pdfPath,
        maxEdge: 1600,
        quality: 75,
      );

      final List<String> paths = <String>[];
      for (int i = 0; i < pages.length; i++) {
        final String fileName = FileNameUtils.withExtension(
          'page_${(i + 1).toString().padLeft(3, '0')}',
          'jpg',
        );
        final String dest = p.join(dir.path, fileName);
        await File(dest).writeAsBytes(pages[i].jpegBytes, flush: true);
        paths.add(dest);
      }
      return paths;
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to convert PDF to images.', cause: error);
    }
  }
}
