import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/custom_scan_step.dart';
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
    this.pendingPath,
    this.pendingQuad,
    this.warpedPath,
    this.selectedFilter = ScanFilter.original,
    this.idSide = IdScanSide.front,
    this.busy = false,
    this.busyMessage,
    this.error,
    this.saved = false,
  });

  final CustomScanMode mode;
  final CustomScanStep step;
  final List<ScanPageDraft> pages;
  final String? pendingPath;
  final ScanQuad? pendingQuad;
  final String? warpedPath;
  final ScanFilter selectedFilter;
  final IdScanSide idSide;
  final bool busy;
  final String? busyMessage;
  final Object? error;
  final bool saved;

  bool get canSaveDocument =>
      mode == CustomScanMode.document && pages.isNotEmpty;

  bool get canSaveIdCard {
    if (mode != CustomScanMode.idCard) {
      return false;
    }
    final bool hasFront =
        pages.any((ScanPageDraft p) => p.idSide == IdScanSide.front);
    final bool hasBack =
        pages.any((ScanPageDraft p) => p.idSide == IdScanSide.back);
    return hasFront && hasBack;
  }

  bool get canSave => canSaveDocument || canSaveIdCard;

  CustomScanState copyWith({
    CustomScanMode? mode,
    CustomScanStep? step,
    List<ScanPageDraft>? pages,
    String? pendingPath,
    ScanQuad? pendingQuad,
    String? warpedPath,
    ScanFilter? selectedFilter,
    IdScanSide? idSide,
    bool? busy,
    String? busyMessage,
    Object? error,
    bool? saved,
    bool clearPending = false,
    bool clearWarped = false,
    bool clearError = false,
    bool clearBusyMessage = false,
  }) {
    return CustomScanState(
      mode: mode ?? this.mode,
      step: step ?? this.step,
      pages: pages ?? this.pages,
      pendingPath: clearPending ? null : (pendingPath ?? this.pendingPath),
      pendingQuad: clearPending ? null : (pendingQuad ?? this.pendingQuad),
      warpedPath: clearWarped ? null : (warpedPath ?? this.warpedPath),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      idSide: idSide ?? this.idSide,
      busy: busy ?? this.busy,
      busyMessage:
          clearBusyMessage ? null : (busyMessage ?? this.busyMessage),
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}
