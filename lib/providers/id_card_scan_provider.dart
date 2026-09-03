import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/enums/id_card_scan_step.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/id_card_sides.dart';
import 'package:scanner_app/models/scan_result.dart';
import 'package:scanner_app/providers/id_card_scan_state.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'id_card_scan_provider.g.dart';

@riverpod
class IdCardScanNotifier extends _$IdCardScanNotifier {
  @override
  IdCardScanState build() => const IdCardScanState();

  Future<void> scanFront() async {
    await _scanSide(isFront: true);
  }

  Future<void> scanBack() async {
    if (!state.sides.hasFront) {
      state = state.copyWith(
        error: const ScannerException('Scan the front side first.'),
      );
      return;
    }
    await _scanSide(isFront: false);
  }

  Future<void> generateIdCardPdf() async {
    final IdCardSides sides = state.sides;
    if (!sides.isComplete) {
      state = state.copyWith(
        error: const PdfException('Front and back images are required.'),
      );
      return;
    }

    state = state.copyWith(
      step: IdCardScanStep.processing,
      clearError: true,
    );

    try {
      final String outputPath = p.join(
        (await getTemporaryDirectory()).path,
        FileNameUtils.withExtension(FileNameUtils.stamped('id_card'), 'pdf'),
      );

      await ref.read(pdfServiceProvider).createIdCardA4(
            frontImagePath: sides.frontPath!,
            backImagePath: sides.backPath!,
            outputPath: outputPath,
          );

      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.idCard,
            title: FileNameUtils.stamped('ID Card'),
            sourcePdfPath: outputPath,
            sourceImagePaths: <String>[sides.frontPath!, sides.backPath!],
          );

      await ref.read(libraryNotifierProvider.notifier).loadLibrary();
      state = const IdCardScanState();
    } on ScannerCancelledException {
      state = state.copyWith(step: _stepFor(sides), clearError: true);
    } catch (error) {
      state = state.copyWith(
        step: _stepFor(sides),
        error: error,
      );
    }
  }

  Future<void> _scanSide({required bool isFront}) async {
    state = state.copyWith(clearError: true);
    try {
      final ScanResult result =
          await ref.read(documentScannerServiceProvider).scanIdCardSide();
      if (result.imagePaths.isEmpty) {
        throw const ScannerException('No image was returned from the scanner.');
      }

      final String path = result.imagePaths.first;
      final IdCardSides sides = isFront
          ? state.sides.copyWith(frontPath: path)
          : state.sides.copyWith(backPath: path);

      state = state.copyWith(
        sides: sides,
        step: _stepFor(sides),
        clearError: true,
      );
    } on ScannerCancelledException {
      state = state.copyWith(clearError: true);
    } catch (error) {
      state = state.copyWith(error: error);
    }
  }

  IdCardScanStep _stepFor(IdCardSides sides) {
    if (sides.isComplete) {
      return IdCardScanStep.backScanned;
    }
    if (sides.hasFront) {
      return IdCardScanStep.frontScanned;
    }
    return IdCardScanStep.idle;
  }
}
