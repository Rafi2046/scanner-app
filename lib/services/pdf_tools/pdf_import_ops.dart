import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/services/pdf_service.dart';
import 'package:scanner_app/services/storage_service.dart';

/// Picks PDFs/images from the device and copies them into permanent storage.
abstract final class PdfImportOps {
  static const List<String> allowedExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  static Future<List<ScannedDocument>> importFiles({
    required StorageService storage,
    required PdfService pdfService,
    required Future<String> Function(String fileName) tempOutputPath,
  }) async {
    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (picked == null || picked.files.isEmpty) {
        return const <ScannedDocument>[];
      }

      final List<String> imagePaths = <String>[];
      final List<String> pdfPaths = <String>[];

      for (final PlatformFile file in picked.files) {
        final String? path = file.path;
        if (path == null || path.isEmpty) {
          throw const StorageException(
            'Could not read a selected file path.',
          );
        }
        final String ext = p.extension(path).toLowerCase();
        if (ext == '.pdf') {
          pdfPaths.add(path);
        } else {
          imagePaths.add(path);
        }
      }

      final List<ScannedDocument> saved = <ScannedDocument>[];

      if (imagePaths.isNotEmpty) {
        final String tempPdf = await tempOutputPath(
          FileNameUtils.withExtension(
            FileNameUtils.stamped('import_images'),
            'pdf',
          ),
        );
        await pdfService.createDocumentPdfFromImages(
          imagePaths: imagePaths,
          outputPath: tempPdf,
        );
        saved.add(
          await storage.persistGeneratedPdf(
            kind: DocumentKind.imported,
            title: FileNameUtils.stamped('Imported Images'),
            sourcePdfPath: tempPdf,
            sourceImagePaths: imagePaths,
          ),
        );
      }

      for (final String pdfPath in pdfPaths) {
        saved.add(
          await storage.persistGeneratedPdf(
            kind: DocumentKind.imported,
            title: FileNameUtils.stamped(
              p.basenameWithoutExtension(pdfPath),
            ),
            sourcePdfPath: pdfPath,
          ),
        );
      }

      return saved;
    } on AppException {
      rethrow;
    } catch (error) {
      throw StorageException('Failed to import files.', cause: error);
    }
  }
}
