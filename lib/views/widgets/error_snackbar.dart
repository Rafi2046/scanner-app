import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/core/utils/error_message.dart';

/// Shows a SnackBar when an [AsyncValue] transitions into a non-cancel error.
void listenAsyncError(
  WidgetRef ref,
  ProviderListenable<AsyncValue<dynamic>> provider,
  BuildContext context,
) {
  ref.listen<AsyncValue<dynamic>>(provider, (
    AsyncValue<dynamic>? previous,
    AsyncValue<dynamic> next,
  ) {
    if (!next.hasError || next.isLoading) {
      return;
    }
    final Object error = next.error!;
    if (error is ScannerCancelledException ||
        error is PickerCancelledException) {
      return;
    }
    if (previous?.error == error) {
      return;
    }
    showErrorSnackBar(context, error);
  });
}

void showErrorSnackBar(BuildContext context, Object error) {
  if (error is ScannerCancelledException ||
      error is PickerCancelledException) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(appErrorMessage(error))),
    );
}
