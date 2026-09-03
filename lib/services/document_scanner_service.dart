import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/platform_utils.dart';
import 'package:scanner_app/models/scan_result.dart';

/// Wraps Google ML Kit Document Scanner. Android-only.
class DocumentScannerService {
  const DocumentScannerService();

  static const Set<DocumentFormat> _jpegAndPdf = <DocumentFormat>{
    DocumentFormat.jpeg,
    DocumentFormat.pdf,
  };

  /// Multi-page document scan with crop, filters, and optional gallery import.
  Future<ScanResult> scanDocument({
    int pageLimit = AppConstants.documentPageLimit,
    bool isGalleryImportAllowed = true,
  }) {
    return _scan(
      pageLimit: pageLimit,
      isGalleryImportAllowed: isGalleryImportAllowed,
    );
  }

  /// Single-page capture used for one ID card side (front or back).
  Future<ScanResult> scanIdCardSide({
    bool isGalleryImportAllowed = true,
  }) {
    return _scan(
      pageLimit: AppConstants.idCardPageLimit,
      isGalleryImportAllowed: isGalleryImportAllowed,
    );
  }

  Future<ScanResult> _scan({
    required int pageLimit,
    required bool isGalleryImportAllowed,
  }) async {
    if (!PlatformUtils.supportsDocumentScanner) {
      throw const UnsupportedPlatformException();
    }

    DocumentScanner? scanner;
    try {
      scanner = DocumentScanner(
        options: DocumentScannerOptions(
          pageLimit: pageLimit,
          documentFormats: _jpegAndPdf,
          mode: ScannerMode.full,
          isGalleryImport: isGalleryImportAllowed,
        ),
      );

      final DocumentScanningResult nativeResult = await scanner.scanDocument();
      final ScanResult mapped = _mapResult(nativeResult);

      if (mapped.isEmpty) {
        throw const ScannerCancelledException();
      }

      return mapped;
    } on AppException {
      rethrow;
    } on PlatformException catch (error) {
      if (_isUserCancel(error)) {
        throw const ScannerCancelledException();
      }
      throw ScannerException(
        'Document scan failed.',
        cause: error,
      );
    } catch (error) {
      throw ScannerException(
        'Document scan failed.',
        cause: error,
      );
    } finally {
      await _closeQuietly(scanner);
    }
  }

  ScanResult _mapResult(DocumentScanningResult result) {
    final List<String> images = (result.images ?? const <String>[])
        .map(_normalizePath)
        .where((String path) => path.isNotEmpty)
        .toList();

    final String? pdfUri = result.pdf?.uri;
    final String? pdfPath =
        pdfUri == null || pdfUri.isEmpty ? null : _normalizePath(pdfUri);

    return ScanResult(
      imagePaths: images,
      pdfPath: pdfPath,
    );
  }

  String _normalizePath(String raw) {
    if (raw.startsWith('file://')) {
      return Uri.parse(raw).toFilePath();
    }
    return raw;
  }

  bool _isUserCancel(PlatformException error) {
    final String code = error.code.toLowerCase();
    final String message = (error.message ?? '').toLowerCase();
    return code.contains('cancel') ||
        code.contains('cancelled') ||
        message.contains('cancel');
  }

  Future<void> _closeQuietly(DocumentScanner? scanner) async {
    if (scanner == null) {
      return;
    }
    try {
      await scanner.close();
    } catch (_) {
      // Native close must not mask the original scan result or error.
    }
  }
}
