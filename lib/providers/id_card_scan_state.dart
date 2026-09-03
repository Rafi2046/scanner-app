import 'package:scanner_app/core/enums/id_card_scan_step.dart';
import 'package:scanner_app/models/id_card_sides.dart';

/// Immutable UI state for the ID card scan flow.
class IdCardScanState {
  const IdCardScanState({
    this.step = IdCardScanStep.idle,
    this.sides = const IdCardSides(),
    this.error,
  });

  final IdCardScanStep step;
  final IdCardSides sides;
  final Object? error;

  bool get canScanBack => sides.hasFront && step != IdCardScanStep.processing;

  bool get canGenerate =>
      sides.isComplete && step != IdCardScanStep.processing;

  bool get isProcessing => step == IdCardScanStep.processing;

  IdCardScanState copyWith({
    IdCardScanStep? step,
    IdCardSides? sides,
    Object? error,
    bool clearError = false,
  }) {
    return IdCardScanState(
      step: step ?? this.step,
      sides: sides ?? this.sides,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
