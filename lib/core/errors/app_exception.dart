/// Typed failure for local I/O, scanning, and PDF operations.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'AppException: $message';
    }
    return 'AppException: $message (cause: $cause)';
  }
}

/// Thrown when the current platform cannot run ML Kit Document Scanner.
class UnsupportedPlatformException extends AppException {
  const UnsupportedPlatformException([
    super.message = 'Document scanning is only supported on Android.',
  ]);
}

/// Thrown when a file or directory operation fails.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Thrown when ML Kit document scanning fails.
class ScannerException extends AppException {
  const ScannerException(super.message, {super.cause});
}

/// Thrown when the user dismisses the scanner UI without completing a scan.
class ScannerCancelledException extends ScannerException {
  const ScannerCancelledException([
    super.message = 'Document scan was cancelled.',
  ]);
}

/// Thrown when PDF generation or writing fails.
class PdfException extends AppException {
  const PdfException(super.message, {super.cause});
}

/// Thrown when on-device OCR fails.
class OcrException extends AppException {
  const OcrException(super.message, {super.cause});
}

/// Thrown when the user dismisses a file picker without selecting files.
class PickerCancelledException extends AppException {
  const PickerCancelledException([
    super.message = 'File selection was cancelled.',
  ]);
}

/// Thrown when biometric authentication fails or is unavailable.
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}
