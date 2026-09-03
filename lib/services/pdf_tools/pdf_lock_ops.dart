import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/pdf_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Encrypts a PDF with a user password (AES-256).
abstract final class PdfLockOps {
  static Future<void> lock({
    required String pdfPath,
    required String password,
    required String outputPath,
  }) async {
    final String trimmed = password.trim();
    if (trimmed.length < 4) {
      throw const PdfException('Password must be at least 4 characters.');
    }

    final PdfDocument document = await PdfIo.loadFromPath(pdfPath);
    try {
      document.security
        ..userPassword = trimmed
        ..ownerPassword = trimmed
        ..algorithm = PdfEncryptionAlgorithm.aesx256Bit;
      await PdfIo.writeToPath(document, outputPath);
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException('Failed to password-lock PDF.', cause: error);
    } finally {
      document.dispose();
    }
  }
}
