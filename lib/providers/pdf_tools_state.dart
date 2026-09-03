/// UI state for merge / watermark / sign / import operations.
class PdfToolsUiState {
  const PdfToolsUiState({
    this.isBusy = false,
    this.successMessage,
    this.error,
  });

  final bool isBusy;
  final String? successMessage;
  final Object? error;

  PdfToolsUiState copyWith({
    bool? isBusy,
    String? successMessage,
    Object? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PdfToolsUiState(
      isBusy: isBusy ?? this.isBusy,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
