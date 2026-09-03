import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/scan_result.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'document_scan_provider.g.dart';

@riverpod
class DocumentScanNotifier extends _$DocumentScanNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> startDocumentScan() async {
    state = const AsyncLoading();
    try {
      final ScanResult result =
          await ref.read(documentScannerServiceProvider).scanDocument();

      await ref.read(storageServiceProvider).persistScan(
            kind: DocumentKind.scan,
            title: FileNameUtils.stamped('Document'),
            tempImagePaths: result.imagePaths,
            tempPdfPath: result.pdfPath,
          );

      await ref.read(libraryNotifierProvider.notifier).loadLibrary();
      state = const AsyncData<void>(null);
    } on ScannerCancelledException {
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
    }
  }
}
