import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/services/pdf_service.dart';
import 'package:scanner_app/services/pdf_tools/pdf_compress_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_import_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_lock_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_merge_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_signature_stamp_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_to_image_ops.dart';
import 'package:scanner_app/services/pdf_tools/pdf_watermark_ops.dart';
import 'package:scanner_app/services/storage_service.dart';

/// Offline PDF tools: import, merge, watermark, sign, lock, compress, PDF→image.
class PdfToolsService {
  const PdfToolsService({
    required this.storage,
    required this.pdfService,
  });

  final StorageService storage;
  final PdfService pdfService;

  Future<List<ScannedDocument>> importFiles() {
    return PdfImportOps.importFiles(
      storage: storage,
      pdfService: pdfService,
      tempOutputPath: _tempFile,
    );
  }

  Future<String> mergePdfs(List<String> pdfPaths, String outputPath) async {
    await PdfMergeOps.merge(pdfPaths: pdfPaths, outputPath: outputPath);
    return outputPath;
  }

  Future<String> addTextWatermark(
    String pdfPath,
    String text,
    String outputPath,
  ) async {
    await PdfWatermarkOps.addText(
      pdfPath: pdfPath,
      text: text,
      outputPath: outputPath,
    );
    return outputPath;
  }

  Future<String> addSignatureStamp(
    String pdfPath,
    Uint8List signaturePng,
    int pageNumber,
    String outputPath,
  ) async {
    await PdfSignatureStampOps.stamp(
      pdfPath: pdfPath,
      signaturePng: signaturePng,
      pageNumber: pageNumber,
      outputPath: outputPath,
    );
    return outputPath;
  }

  Future<String> lockPdf(
    String pdfPath,
    String password,
    String outputPath,
  ) async {
    await PdfLockOps.lock(
      pdfPath: pdfPath,
      password: password,
      outputPath: outputPath,
    );
    return outputPath;
  }

  Future<String> compressPdf(String pdfPath, String outputPath) async {
    await PdfCompressOps.compress(
      pdfPath: pdfPath,
      outputPath: outputPath,
    );
    return outputPath;
  }

  Future<List<String>> pdfToImages(String pdfPath, String outputDirPath) {
    return PdfToImageOps.export(
      pdfPath: pdfPath,
      outputDirPath: outputDirPath,
    );
  }

  Future<String> _tempFile(String fileName) async {
    final String dir = (await getTemporaryDirectory()).path;
    return p.join(dir, fileName);
  }
}
