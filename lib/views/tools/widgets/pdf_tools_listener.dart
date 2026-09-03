import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/providers/pdf_tools_state.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

void listenPdfToolsResult(
  WidgetRef ref,
  BuildContext context, {
  bool popOnSuccess = false,
}) {
  ref.listen<PdfToolsUiState>(pdfToolsNotifierProvider, (
    PdfToolsUiState? previous,
    PdfToolsUiState next,
  ) {
    if (next.error != null && next.error != previous?.error) {
      showErrorSnackBar(context, next.error!);
    }

    if (next.successMessage != null &&
        next.successMessage != previous?.successMessage &&
        context.mounted) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      if (popOnSuccess) {
        Navigator.of(context).pop();
      }
      messenger.showSnackBar(
        SnackBar(content: Text(next.successMessage!)),
      );
    }
  });
}
