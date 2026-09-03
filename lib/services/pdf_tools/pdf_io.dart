import 'dart:io';

import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Shared load/save helpers for Syncfusion PDF documents.
abstract final class PdfIo {
  static Future<PdfDocument> loadFromPath(String path) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        throw PdfException('PDF file does not exist: $path');
      }
      final List<int> bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw PdfException('PDF file is empty: $path');
      }
      return PdfDocument(inputBytes: bytes);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to open PDF: $path', cause: error);
    }
  }

  static Future<void> writeToPath(PdfDocument document, String outputPath) async {
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
