import 'package:scanner_app/core/errors/app_exception.dart';

/// User-facing message for SnackBars and banners.
String appErrorMessage(Object error) {
  if (error is AppException) {
    return error.message;
  }
  return error.toString();
}
