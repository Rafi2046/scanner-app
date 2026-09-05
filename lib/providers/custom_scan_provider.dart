import 'dart:ui' show Offset;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/custom_scan_step.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/file_name_utils.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'custom_scan_provider.g.dart';

@riverpod
class CustomScanNotifier extends _$CustomScanNotifier {
  @override
  CustomScanState build() => const CustomScanState();

  void startSession(CustomScanMode mode) {
    state = CustomScanState(mode: mode, idSide: IdScanSide.front);
  }

  void resetSession() => state = const CustomScanState();

  Future<void> selectFilter(ScanFilter filter) async {
    final String? raw = state.rawWarpedPath ?? state.warpedPath;
    if (raw == null) {
      state = state.copyWith(selectedFilter: filter, clearError: true);
      return;
    }
    state = state.copyWith(
      selectedFilter: filter,
      clearError: true,
    );
    try {
      final String processed = await ref.read(scanEnhanceServiceProvider).applyFilter(
            imagePath: raw,
            filter: filter,
          );
      state = state.copyWith(
        warpedPath: processed,
        selectedFilter: filter,
      );
    } catch (error) {
      state = state.copyWith(error: error);
    }
  }

  void updateQuad(ScanQuad quad) {
    state = state.copyWith(pendingQuad: quad, clearError: true);
  }

  /// Show overlay immediately when shutter/gallery starts (before downscale).
  void beginCapture() {
    state = state.copyWith(
      busy: true,
      clearError: true,
    );
  }

  void cancelBusy() {
    state = state.copyWith(busy: false, clearBusyMessage: true);
  }

  /// Snap crop handles to the full image (entire frame).
  void selectFullPage({required double width, required double height}) {
    if (width <= 0 || height <= 0) {
      return;
    }
    state = state.copyWith(
      pendingQuad: ScanQuad(
        topLeft: Offset.zero,
        topRight: Offset(width, 0),
        bottomRight: Offset(width, height),
        bottomLeft: Offset(0, height),
      ),
      clearError: true,
    );
  }

  /// Re-run OpenCV paper detection on the captured still.
  Future<void> redetectEdges() async {
    final String? path = state.pendingPath;
    if (path == null) {
      return;
    }
    state = state.copyWith(
      busy: true,
      clearError: true,
    );
    try {
      final ScanQuad quad =
          await ref.read(edgeDetectServiceProvider).detectCorners(path);
      state = state.copyWith(
        pendingQuad: quad,
        busy: false,
        clearBusyMessage: true,
      );
    } catch (error) {
      state = state.copyWith(busy: false, clearBusyMessage: true, error: error);
    }
  }

  void goToCrop() {
    state = state.copyWith(step: CustomScanStep.crop, clearWarped: true, clearError: true);
  }

  Future<void> rotateLeft() async {
    final String? raw = state.rawWarpedPath;
    if (raw == null) return;
    try {
      final String rotatedRaw = await ref.read(scanEnhanceServiceProvider).rotateImage(
            imagePath: raw,
            angle: -90,
          );
      final String rotatedFiltered = await ref.read(scanEnhanceServiceProvider).applyFilter(
            imagePath: rotatedRaw,
            filter: state.selectedFilter,
          );
      state = state.copyWith(
        rawWarpedPath: rotatedRaw,
        warpedPath: rotatedFiltered,
      );
    } catch (error) {
      state = state.copyWith(error: error);
    }
  }

  void goToCapture() {
    state = state.copyWith(
      step: CustomScanStep.capture,
      clearPending: true,
      clearWarped: true,
      clearError: true,
    );
  }

  Future<void> onRawCaptured(String path, {ScanQuad? liveQuad}) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final ScanQuad quad = await ref
          .read(edgeDetectServiceProvider)
          .detectCorners(path, liveQuad: liveQuad);
      state = state.copyWith(
        step: CustomScanStep.crop,
        pendingPath: path,
        pendingQuad: quad,
        busy: false,
        clearBusyMessage: true,
        clearWarped: true,
      );
    } catch (error) {
      state = state.copyWith(busy: false, clearBusyMessage: true, error: error);
    }
  }

  Future<void> confirmCrop() async {
    final String? path = state.pendingPath;
    final ScanQuad? quad = state.pendingQuad;
    if (path == null || quad == null) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final String rawWarped = await ref.read(edgeDetectServiceProvider).warp(
            imagePath: path,
            quad: quad,
          );
      final String enhanced = await ref.read(scanEnhanceServiceProvider).applyFilter(
            imagePath: rawWarped,
            filter: ScanFilter.color,
          );
      state = state.copyWith(
        step: CustomScanStep.enhance,
        rawWarpedPath: rawWarped,
        warpedPath: enhanced,
        selectedFilter: ScanFilter.color,
        busy: false,
        clearBusyMessage: true,
      );
    } catch (error) {
      state = state.copyWith(busy: false, clearBusyMessage: true, error: error);
    }
  }

  Future<void> confirmEnhance() async {
    final String? imagePath = state.warpedPath;
    if (imagePath == null) return;

    final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages);
    if (state.mode == CustomScanMode.idCard) {
      next.removeWhere((ScanPageDraft p) => p.idSide == state.idSide);
      next.add(ScanPageDraft(imagePath: imagePath, filter: state.selectedFilter, idSide: state.idSide));
    } else {
      next.add(ScanPageDraft(imagePath: imagePath, filter: state.selectedFilter));
    }

    IdScanSide nextSide = state.idSide;
    if (state.mode == CustomScanMode.idCard && state.idSide == IdScanSide.front) {
      nextSide = IdScanSide.back;
    }

    state = state.copyWith(
      step: CustomScanStep.pages,
      pages: next,
      idSide: nextSide,
      busy: false,
      clearBusyMessage: true,
      clearPending: true,
      clearWarped: true,
    );
  }

  void removePage(int index) {
    if (index < 0 || index >= state.pages.length) return;
    final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages)..removeAt(index);
    state = state.copyWith(pages: next, clearError: true);
  }

  Future<void> save() async {
    if (!state.canSave) {
      state = state.copyWith(error: const ScannerException('Add at least one page before saving.'));
      return;
    }

    state = state.copyWith(busy: true, busyMessage: 'Saving PDF…', clearError: true);
    try {
      if (state.mode == CustomScanMode.idCard) {
        await _saveIdCard();
      } else {
        await _saveDocument();
      }
      await ref.read(libraryNotifierProvider.notifier).loadLibrary();
      state = state.copyWith(busy: false, clearBusyMessage: true, saved: true);
    } on ScannerCancelledException {
      state = state.copyWith(busy: false, clearBusyMessage: true);
    } catch (error) {
      state = state.copyWith(busy: false, clearBusyMessage: true, error: error);
    }
  }

  Future<void> _saveDocument() async {
    final List<String> paths = state.pages.map((ScanPageDraft p) => p.imagePath).toList();
    final String pdfPath = p.join(
      (await getTemporaryDirectory()).path,
      FileNameUtils.withExtension(FileNameUtils.stamped('Document'), 'pdf'),
    );
    await ref.read(pdfServiceProvider).createDocumentPdfFromImages(imagePaths: paths, outputPath: pdfPath);
    await ref.read(storageServiceProvider).persistScan(
          kind: DocumentKind.scan,
          title: FileNameUtils.stamped('Document'),
          tempImagePaths: paths,
          tempPdfPath: pdfPath,
        );
  }

  Future<void> _saveIdCard() async {
    final String front = state.pages.firstWhere((ScanPageDraft p) => p.idSide == IdScanSide.front).imagePath;
    final String back = state.pages.firstWhere((ScanPageDraft p) => p.idSide == IdScanSide.back).imagePath;
    final String pdfPath = p.join(
      (await getTemporaryDirectory()).path,
      FileNameUtils.withExtension(FileNameUtils.stamped('id_card'), 'pdf'),
    );
    await ref.read(pdfServiceProvider).createIdCardA4(frontImagePath: front, backImagePath: back, outputPath: pdfPath);
    await ref.read(storageServiceProvider).persistGeneratedPdf(
          kind: DocumentKind.idCard,
          title: FileNameUtils.stamped('ID Card'),
          sourcePdfPath: pdfPath,
          sourceImagePaths: <String>[front, back],
        );
  }
}
