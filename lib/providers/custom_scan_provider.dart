import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/custom_scan_step.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
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
  final Map<String, String> _filterCache = <String, String>{};

  String _generateDefaultTitle({IdCardCategory? cat}) {
    final DateTime now = DateTime.now();
    final String date = '${now.month}-${now.day}-${now.year % 100}';
    final String time =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    if (cat != null) {
      return '${cat.title} $date $time';
    }
    return 'CamScanner $date $time';
  }

  @override
  CustomScanState build() => CustomScanState(documentTitle: _generateDefaultTitle());

  void startSession(CustomScanMode mode, {IdCardCategory? idCategory}) {
    _filterCache.clear();
    final IdCardCategory cat = idCategory ?? state.idCategory;
    state = CustomScanState(
      mode: mode,
      idSide: IdScanSide.front,
      idCategory: cat,
      documentTitle: _generateDefaultTitle(
        cat: mode == CustomScanMode.idCard ? cat : null,
      ),
    );
  }

  void selectIdCategory(IdCardCategory category) {
    state = state.copyWith(
      idCategory: category,
      documentTitle: _generateDefaultTitle(cat: category),
    );
  }

  void prepareScanBackSide() {
    state = state.copyWith(
      step: CustomScanStep.capture,
      idSide: IdScanSide.back,
      clearPending: true,
      clearWarped: true,
      clearRotation: true,
      clearError: true,
    );
  }

  void resetSession() {
    _filterCache.clear();
    state = CustomScanState(documentTitle: _generateDefaultTitle());
  }

  void setDocumentTitle(String title) {
    state = state.copyWith(documentTitle: title);
  }

  void selectPage(int index) {
    if (index < 0 || index >= state.pages.length) return;
    final ScanPageDraft page = state.pages[index];
    state = state.copyWith(
      currentPageIndex: index,
      warpedPath: page.imagePath,
      rawWarpedPath: page.rawPath ?? page.imagePath,
      selectedFilter: page.filter,
      rotationTurns: page.rotationTurns,
      clearError: true,
    );
  }

  Future<void> selectFilter(ScanFilter filter) async {
    final int idx = state.currentPageIndex;
    if (idx < 0 || idx >= state.pages.length) return;

    if (state.mode == CustomScanMode.idCard) {
      state = state.copyWith(selectedFilter: filter, clearError: true);
      try {
        final List<ScanPageDraft> updatedPages = <ScanPageDraft>[];
        for (final ScanPageDraft p in state.pages) {
          final String raw = p.rawPath ?? p.imagePath;
          final String cacheKey = '${raw}_${filter.name}';
          String processed;
          if (_filterCache.containsKey(cacheKey)) {
            processed = _filterCache[cacheKey]!;
          } else {
            processed = await ref.read(scanEnhanceServiceProvider).applyFilter(raw, filter);
            _filterCache[cacheKey] = processed;
          }
          updatedPages.add(p.copyWith(imagePath: processed, filter: filter));
        }
        final String? activeWarped = updatedPages.isNotEmpty
            ? updatedPages[state.currentPageIndex.clamp(0, updatedPages.length - 1)].imagePath
            : null;
        state = state.copyWith(
          pages: updatedPages,
          selectedFilter: filter,
          warpedPath: activeWarped,
          clearError: true,
        );
      } catch (error) {
        state = state.copyWith(error: error);
      }
      return;
    }

    final ScanPageDraft curPage = state.pages[idx];
    final String raw = curPage.rawPath ?? curPage.imagePath;
    final String cacheKey = '${raw}_${filter.name}';

    if (_filterCache.containsKey(cacheKey)) {
      final String cached = _filterCache[cacheKey]!;
      final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages);
      next[idx] = curPage.copyWith(imagePath: cached, filter: filter);
      state = state.copyWith(
        pages: next,
        selectedFilter: filter,
        warpedPath: cached,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      selectedFilter: filter,
      clearError: true,
    );

    try {
      final String processed = await ref.read(scanEnhanceServiceProvider).applyFilter(
            raw,
            filter,
          );
      _filterCache[cacheKey] = processed;

      final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages);
      next[idx] = curPage.copyWith(
        imagePath: processed,
        filter: filter,
      );

      state = state.copyWith(
        pages: next,
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
      state = state.copyWith(
        busy: false,
        clearBusyMessage: true,
        error: error,
      );
    }
  }

  void goToCrop() {
    String? path = state.pendingPath;
    if (path == null && state.pages.isNotEmpty) {
      final int idx = state.currentPageIndex.clamp(0, state.pages.length - 1);
      final ScanPageDraft cur = state.pages[idx];
      path = cur.rawPath ?? cur.imagePath;
    }
    state = state.copyWith(
      step: CustomScanStep.crop,
      pendingPath: path,
      clearWarped: true,
      clearRotation: true,
      clearError: true,
    );
  }

  void rotateLeft() {
    final int idx = state.currentPageIndex;
    if (idx < 0 || idx >= state.pages.length) return;

    final ScanPageDraft curPage = state.pages[idx];
    final int nextTurns = (curPage.rotationTurns + 3) % 4;

    final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages);
    next[idx] = curPage.copyWith(rotationTurns: nextTurns);

    state = state.copyWith(
      pages: next,
      rotationTurns: nextTurns,
    );
    HapticFeedback.lightImpact();
  }

  void goToCapture() {
    state = state.copyWith(
      step: CustomScanStep.capture,
      clearPending: true,
      clearWarped: true,
      clearRotation: true,
      clearError: true,
    );
  }

  void goToEnhance() {
    if (state.pages.isEmpty) return;
    state = state.copyWith(
      step: CustomScanStep.enhance,
      clearPending: true,
      clearWarped: true,
      clearRotation: true,
      clearError: true,
    );
  }

  void addPageViaCamera() {
    goToCapture();
  }

  Future<void> addPageViaGallery() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final String path =
          await ref.read(cameraCaptureServiceProvider).pickFromGallery();
      await onRawCaptured(path);
    } on ScannerCancelledException {
      state = state.copyWith(busy: false);
    } catch (error) {
      state = state.copyWith(busy: false, error: error);
    }
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
            rawWarped,
            ScanFilter.magicEnhance,
          );

      final ScanPageDraft draft = ScanPageDraft(
        imagePath: enhanced,
        rawPath: rawWarped,
        filter: ScanFilter.magicEnhance,
        rotationTurns: 0,
        idSide: state.mode == CustomScanMode.idCard ? state.idSide : null,
      );

      final List<ScanPageDraft> nextPages = List<ScanPageDraft>.from(state.pages);
      if (state.mode == CustomScanMode.idCard) {
        nextPages.removeWhere((ScanPageDraft p) => p.idSide == state.idSide);
        nextPages.add(draft);
      } else {
        nextPages.add(draft);
      }

      final int activeIndex = nextPages.length - 1;

      state = state.copyWith(
        step: CustomScanStep.enhance,
        pages: nextPages,
        currentPageIndex: activeIndex,
        rawWarpedPath: rawWarped,
        warpedPath: enhanced,
        selectedFilter: ScanFilter.magicEnhance,
        clearRotation: true,
        busy: false,
        clearBusyMessage: true,
      );
    } catch (error) {
      state = state.copyWith(busy: false, clearBusyMessage: true, error: error);
    }
  }

  void removePage(int index) {
    if (index < 0 || index >= state.pages.length) return;
    final List<ScanPageDraft> next = List<ScanPageDraft>.from(state.pages)..removeAt(index);
    if (next.isEmpty) {
      state = state.copyWith(pages: const <ScanPageDraft>[]);
      goToCapture();
      return;
    }
    final int nextIndex = index.clamp(0, next.length - 1);
    final ScanPageDraft active = next[nextIndex];
    state = state.copyWith(
      pages: next,
      currentPageIndex: nextIndex,
      warpedPath: active.imagePath,
      rawWarpedPath: active.rawPath ?? active.imagePath,
      selectedFilter: active.filter,
      rotationTurns: active.rotationTurns,
      clearError: true,
    );
  }

  Future<void> save() async {
    if (!state.canSave) {
      state = state.copyWith(
        error: const ScannerException('Add at least one page before saving.'),
      );
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
    final List<String> finalPaths = <String>[];
    for (final ScanPageDraft page in state.pages) {
      String path = page.imagePath;
      if (page.rotationTurns != 0) {
        final int angle = (page.rotationTurns * 90) % 360;
        path = await ref.read(scanEnhanceServiceProvider).rotateImage(
              imagePath: path,
              angle: angle,
            );
      }
      finalPaths.add(path);
    }

    final String title = state.documentTitle?.trim().isNotEmpty == true
        ? state.documentTitle!.trim()
        : _generateDefaultTitle();

    final String pdfPath = p.join(
      (await getTemporaryDirectory()).path,
      FileNameUtils.withExtension(title, 'pdf'),
    );
    await ref.read(pdfServiceProvider).createDocumentPdfFromImages(
          imagePaths: finalPaths,
          outputPath: pdfPath,
        );
    await ref.read(storageServiceProvider).persistScan(
          kind: DocumentKind.scan,
          title: title,
          tempImagePaths: finalPaths,
          tempPdfPath: pdfPath,
        );
  }

  Future<void> _saveIdCard() async {
    final String front = state.pages
        .firstWhere((ScanPageDraft p) => p.idSide == IdScanSide.front)
        .imagePath;

    final String prefix = state.idCategory.filePrefix;
    final String docTitle = state.documentTitle?.trim().isNotEmpty == true
        ? state.documentTitle!.trim()
        : FileNameUtils.stamped(state.idCategory.title);

    final String cacheDir = (await getTemporaryDirectory()).path;
    final String pdfPath = p.join(
      cacheDir,
      FileNameUtils.withExtension(FileNameUtils.stamped(prefix.toLowerCase()), 'pdf'),
    );
    final String compositeImgPath = p.join(
      cacheDir,
      FileNameUtils.withExtension('composite_${FileNameUtils.stamped(prefix.toLowerCase())}', 'jpg'),
    );

    if (state.idCategory.isSingleSide) {
      await ref.read(pdfServiceProvider).createIdCardA4CompositeImage(
            frontImagePath: front,
            outputPath: compositeImgPath,
          );
      await ref.read(pdfServiceProvider).createSingleCardA4(
            imagePath: front,
            outputPath: pdfPath,
            compositeA4ImagePath: compositeImgPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.idCard,
            title: docTitle,
            sourcePdfPath: pdfPath,
            sourceImagePaths: <String>[compositeImgPath],
          );
    } else {
      final String back = state.pages
          .firstWhere((ScanPageDraft p) => p.idSide == IdScanSide.back)
          .imagePath;
      await ref.read(pdfServiceProvider).createIdCardA4CompositeImage(
            frontImagePath: front,
            backImagePath: back,
            outputPath: compositeImgPath,
          );
      await ref.read(pdfServiceProvider).createIdCardA4(
            frontImagePath: front,
            backImagePath: back,
            outputPath: pdfPath,
            compositeA4ImagePath: compositeImgPath,
          );
      await ref.read(storageServiceProvider).persistGeneratedPdf(
            kind: DocumentKind.idCard,
            title: docTitle,
            sourcePdfPath: pdfPath,
            sourceImagePaths: <String>[compositeImgPath],
          );
    }
  }
}
