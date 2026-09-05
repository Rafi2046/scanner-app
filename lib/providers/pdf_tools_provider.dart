import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_state.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'pdf_tools_provider.g.dart';

@riverpod
class PdfToolsNotifier extends _$PdfToolsNotifier {
  @override
  PdfToolsUiState build() => const PdfToolsUiState();

  Future<void> importFiles() async {
    await _run('Files imported.', () async {
      final List<ScannedDocument> imported =
          await ref.read(pdfToolsServiceProvider).importFiles();
      if (imported.isEmpty) {
        return false;
      }
      await _refreshLibrary();
      return true;
    });
  }

  Future<ScannedDocument?> mergePdfs(
    List<String> pdfPaths, {
    String? customTitle,
  }) async {
    ScannedDocument? created;
    await _run('PDFs merged.', () async {
      final String outputPath = await _tempPdf('merged');
      await ref.read(pdfToolsServiceProvider).mergePdfs(pdfPaths, outputPath);
      created = await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.toolOutput,
            title: (customTitle != null && customTitle.trim().isNotEmpty)
                ? customTitle.trim()
                : FileNameUtils.stamped('Merged'),
            sourcePdfPath: outputPath,
          );
      await _refreshLibrary();
      return true;
    });
    return created;
  }

  Future<void> addWatermark({
    required String pdfPath,
    required String text,
  }) async {
    await _run('Watermark added.', () async {
      final String outputPath = await _tempPdf('watermark');
      await ref.read(pdfToolsServiceProvider).addTextWatermark(
            pdfPath,
            text,
            outputPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.toolOutput,
            title: FileNameUtils.stamped('Watermarked'),
            sourcePdfPath: outputPath,
          );
      await _refreshLibrary();
      return true;
    });
  }

  Future<void> addSignature({
    required String pdfPath,
    required Uint8List signaturePng,
    required int pageNumber,
  }) async {
    await _run('Signature added.', () async {
      final String outputPath = await _tempPdf('signed');
      await ref.read(pdfToolsServiceProvider).addSignatureStamp(
            pdfPath,
            signaturePng,
            pageNumber,
            outputPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.toolOutput,
            title: FileNameUtils.stamped('Signed'),
            sourcePdfPath: outputPath,
          );
      await _refreshLibrary();
      return true;
    });
  }

  Future<void> lockPdf({
    required String pdfPath,
    required String password,
  }) async {
    await _run('PDF password lock applied.', () async {
      final String outputPath = await _tempPdf('locked');
      await ref.read(pdfToolsServiceProvider).lockPdf(
            pdfPath,
            password,
            outputPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.toolOutput,
            title: FileNameUtils.stamped('Locked'),
            sourcePdfPath: outputPath,
          );
      await _refreshLibrary();
      return true;
    });
  }

  Future<void> compressPdf({required String pdfPath}) async {
    await _run('PDF compressed.', () async {
      final String outputPath = await _tempPdf('compressed');
      await ref.read(pdfToolsServiceProvider).compressPdf(
            pdfPath,
            outputPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.toolOutput,
            title: FileNameUtils.stamped('Compressed'),
            sourcePdfPath: outputPath,
          );
      await _refreshLibrary();
      return true;
    });
  }

  Future<void> pdfToImages({required String pdfPath}) async {
    await _run('PDF pages exported as images.', () async {
      final String outputDir = p.join(
        (await getTemporaryDirectory()).path,
        FileNameUtils.stamped('pdf_images'),
      );
      final List<String> imagePaths =
          await ref.read(pdfToolsServiceProvider).pdfToImages(
                pdfPath,
                outputDir,
              );
      await ref.read(storageServiceProvider).persistScan(
            kind: DocumentKind.toolOutput,
            title: FileNameUtils.stamped('PDF Images'),
            tempImagePaths: imagePaths,
          );
      await _refreshLibrary();
      return true;
    });
  }

  Future<void> _run(
    String successMessage,
    Future<bool> Function() action,
  ) async {
    state = const PdfToolsUiState(isBusy: true);
    try {
      final bool didWork = await action();
      if (!didWork) {
        state = const PdfToolsUiState();
        return;
      }
      state = PdfToolsUiState(successMessage: successMessage);
    } catch (error) {
      state = PdfToolsUiState(error: error);
    }
  }

  Future<void> _refreshLibrary() {
    return ref.read(libraryNotifierProvider.notifier).loadLibrary();
  }

  Future<String> _tempPdf(String prefix) async {
    final String dir = (await getTemporaryDirectory()).path;
    return p.join(
      dir,
      FileNameUtils.withExtension(FileNameUtils.stamped(prefix), 'pdf'),
    );
  }
}
