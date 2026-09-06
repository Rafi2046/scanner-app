import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/custom_scan_step.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/models/scan_quad.dart';

/// Immutable UI state for the custom scan session.
class CustomScanState {
  const CustomScanState({
    this.mode = CustomScanMode.document,
    this.step = CustomScanStep.capture,
    this.pages = const <ScanPageDraft>[],
    this.currentPageIndex = 0,
    this.documentTitle,
    this.pendingPath,
    this.pendingQuad,
    this.warpedPath,
    this.rawWarpedPath,
    this.selectedFilter = ScanFilter.color,
    this.rotationTurns = 0,
    this.idSide = IdScanSide.front,
    this.idCategory = IdCardCategory.general,
    this.skipIdTypePicker = false,
    this.busy = false,
    this.busyMessage,
    this.error,
    this.saved = false,
  });

  final CustomScanMode mode;
  final CustomScanStep step;
  final List<ScanPageDraft> pages;
  final int currentPageIndex;
  final String? documentTitle;
  final String? pendingPath;
  final ScanQuad? pendingQuad;
  final String? warpedPath;
  final String? rawWarpedPath;
  final ScanFilter selectedFilter;
  final int rotationTurns;
  final IdScanSide idSide;
  final IdCardCategory idCategory;

  /// When true, ID capture skips the type picker and opens the camera.
  final bool skipIdTypePicker;
  final bool busy;
  final String? busyMessage;
  final Object? error;
  final bool saved;

  bool get canSaveDocument =>
      mode == CustomScanMode.document && (pages.isNotEmpty || warpedPath != null);

  bool get canSaveIdCard {
    if (mode != CustomScanMode.idCard) {
      return false;
    }
    final bool hasFront =
        pages.any((ScanPageDraft p) => p.idSide == IdScanSide.front);
    if (idCategory.isSingleSide) {
      return hasFront;
    }
    final bool hasBack =
        pages.any((ScanPageDraft p) => p.idSide == IdScanSide.back);
    return hasFront && hasBack;
  }

  bool get canSave => canSaveDocument || canSaveIdCard;

  CustomScanState copyWith({
    CustomScanMode? mode,
    CustomScanStep? step,
    List<ScanPageDraft>? pages,
    int? currentPageIndex,
    String? documentTitle,
    String? pendingPath,
    ScanQuad? pendingQuad,
    String? warpedPath,
    String? rawWarpedPath,
    ScanFilter? selectedFilter,
    int? rotationTurns,
    IdScanSide? idSide,
    IdCardCategory? idCategory,
    bool? skipIdTypePicker,
    bool? busy,
    String? busyMessage,
    Object? error,
    bool? saved,
    bool clearPending = false,
    bool clearWarped = false,
    bool clearError = false,
    bool clearBusyMessage = false,
    bool clearRotation = false,
  }) {
    return CustomScanState(
      mode: mode ?? this.mode,
      step: step ?? this.step,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      documentTitle: documentTitle ?? this.documentTitle,
      pendingPath: clearPending ? null : (pendingPath ?? this.pendingPath),
      pendingQuad: clearPending ? null : (pendingQuad ?? this.pendingQuad),
      warpedPath: clearWarped ? null : (warpedPath ?? this.warpedPath),
      rawWarpedPath: clearWarped ? null : (rawWarpedPath ?? this.rawWarpedPath),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      rotationTurns: clearRotation ? 0 : (rotationTurns ?? this.rotationTurns),
      idSide: idSide ?? this.idSide,
      idCategory: idCategory ?? this.idCategory,
      skipIdTypePicker: skipIdTypePicker ?? this.skipIdTypePicker,
      busy: busy ?? this.busy,
      busyMessage:
          clearBusyMessage ? null : (busyMessage ?? this.busyMessage),
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}
