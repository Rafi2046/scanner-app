import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/services/auth_service.dart';
import 'package:scanner_app/services/camera_capture_service.dart';
import 'package:scanner_app/services/document_scanner_service.dart';
import 'package:scanner_app/services/edge_detect_service.dart';
import 'package:scanner_app/services/ocr_service.dart';
import 'package:scanner_app/services/pdf_service.dart';
import 'package:scanner_app/services/pdf_tools_service.dart';
import 'package:scanner_app/services/scan_enhance_service.dart';
import 'package:scanner_app/services/storage_service.dart';
import 'package:scanner_app/services/timestamp_stamp_service.dart';

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

@Riverpod(keepAlive: true)
CameraCaptureService cameraCaptureService(CameraCaptureServiceRef ref) {
  final CameraCaptureService service = CameraCaptureService();
  ref.onDispose(() {
    // Fire-and-forget; camera release must not block provider teardown.
    service.dispose();
  });
  return service;
}

@Riverpod(keepAlive: true)
EdgeDetectService edgeDetectService(EdgeDetectServiceRef ref) =>
    const EdgeDetectService();

@Riverpod(keepAlive: true)
ScanEnhanceService scanEnhanceService(ScanEnhanceServiceRef ref) =>
    const ScanEnhanceService();

final timestampStampServiceProvider =
    Provider<TimestampStampService>((ref) => const TimestampStampService());
