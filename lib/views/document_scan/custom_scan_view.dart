import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/custom_scan_step.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/service_providers.dart';
import 'package:scanner_app/views/document_scan/capture_step_view.dart';
import 'package:scanner_app/views/document_scan/crop_step_view.dart';
import 'package:scanner_app/views/document_scan/enhance_step_view.dart';
import 'package:scanner_app/views/document_scan/pages_step_view.dart';
import 'package:scanner_app/views/widgets/dark_scan_scaffold.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

/// Full custom premium scan flow (document or ID).
class CustomScanView extends ConsumerStatefulWidget {
  const CustomScanView({
    super.key,
    required this.mode,
  });

  final CustomScanMode mode;

  @override
  ConsumerState<CustomScanView> createState() => _CustomScanViewState();
}

class _CustomScanViewState extends ConsumerState<CustomScanView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customScanNotifierProvider.notifier).startSession(widget.mode);
    });
  }

  @override
  void dispose() {
    // Camera released when provider disposes / next session reinits.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CustomScanState>(customScanNotifierProvider, (
      CustomScanState? prev,
      CustomScanState next,
    ) {
      final Object? error = next.error;
      if (error != null && error != prev?.error && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException ? error.message : error.toString(),
            ),
          ),
        );
      }
      if (next.saved && prev?.saved != true && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved to library.')),
        );
      }
    });

    final CustomScanState scan = ref.watch(customScanNotifierProvider);
    final String title = switch (scan.step) {
      CustomScanStep.capture =>
        scan.mode == CustomScanMode.idCard ? 'Scan ID Card' : 'Scan Document',
      CustomScanStep.crop => 'Crop',
      CustomScanStep.enhance => 'Enhance',
      CustomScanStep.pages => 'Pages',
    };

    return PopScope(
      canPop: !scan.busy,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) {
          await ref.read(cameraCaptureServiceProvider).dispose();
          ref.read(customScanNotifierProvider.notifier).resetSession();
        }
      },
      child: LoadingOverlay(
        visible: scan.busy,
        message: scan.busyMessage,
        child: scan.step == CustomScanStep.capture
            ? const Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(child: CaptureStepView()),
              )
            : DarkScanScaffold(
                title: title,
                body: switch (scan.step) {
                  CustomScanStep.capture => const SizedBox.shrink(),
                  CustomScanStep.crop => const CropStepView(),
                  CustomScanStep.enhance => const EnhanceStepView(),
                  CustomScanStep.pages => const PagesStepView(),
                },
              ),
      ),
    );
  }
}
