import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/services/auth_service.dart';
import 'package:scanner_app/services/document_scanner_service.dart';
import 'package:scanner_app/services/ocr_service.dart';
import 'package:scanner_app/services/pdf_service.dart';
import 'package:scanner_app/services/pdf_tools_service.dart';
import 'package:scanner_app/services/storage_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) => StorageService();

@Riverpod(keepAlive: true)
DocumentScannerService documentScannerService(
  DocumentScannerServiceRef ref,
) => const DocumentScannerService();

@Riverpod(keepAlive: true)
PdfService pdfService(PdfServiceRef ref) => const PdfService();

@Riverpod(keepAlive: true)
OcrService ocrService(OcrServiceRef ref) => const OcrService();

@Riverpod(keepAlive: true)
PdfToolsService pdfToolsService(PdfToolsServiceRef ref) => PdfToolsService(
      storage: ref.watch(storageServiceProvider),
      pdfService: ref.watch(pdfServiceProvider),
    );

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) => AuthService();
