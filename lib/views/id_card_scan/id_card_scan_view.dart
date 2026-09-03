import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/id_card_scan_provider.dart';
import 'package:scanner_app/providers/id_card_scan_state.dart';
import 'package:scanner_app/views/id_card_scan/widgets/id_card_side_preview.dart';
import 'package:scanner_app/views/id_card_scan/widgets/id_card_step_indicator.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// ID card front/back capture flow.
class IdCardScanView extends ConsumerWidget {
  const IdCardScanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IdCardScanState scanState = ref.watch(idCardScanNotifierProvider);

    ref.listen<IdCardScanState>(idCardScanNotifierProvider, (
      IdCardScanState? previous,
      IdCardScanState next,
    ) {
      final Object? error = next.error;
      if (error != null && error != previous?.error) {
        showErrorSnackBar(context, error);
      }

      final bool wasProcessing = previous?.isProcessing ?? false;
      final bool completed =
          wasProcessing && !next.isProcessing && next.error == null;
      if (completed && context.mounted) {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('ID card PDF saved.')),
        );
      }
    });

    return LoadingOverlay(
      visible: scanState.isProcessing,
      message: 'Generating PDF…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan ID Card'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Scan the front side first, then the back. Both images will '
                  'be placed on a single A4 PDF.',
                ),
                const SizedBox(height: 16),
                IdCardStepIndicator(step: scanState.step),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      IdCardSidePreview(
                        label: 'Front',
                        imagePath: scanState.sides.frontPath,
                      ),
                      const SizedBox(height: 16),
                      IdCardSidePreview(
                        label: 'Back',
                        imagePath: scanState.sides.backPath,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: scanState.sides.hasFront
                      ? 'Rescan Front'
                      : 'Scan Front Side',
                  onPressed: scanState.isProcessing
                      ? null
                      : () => ref
                          .read(idCardScanNotifierProvider.notifier)
                          .scanFront(),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: scanState.sides.hasBack
                      ? 'Rescan Back'
                      : 'Scan Back Side',
                  onPressed: (!scanState.canScanBack || scanState.isProcessing)
                      ? null
                      : () => ref
                          .read(idCardScanNotifierProvider.notifier)
                          .scanBack(),
                ),
                if (scanState.canGenerate) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref
                        .read(idCardScanNotifierProvider.notifier)
                        .generateIdCardPdf(),
                    child: const Text('Generate PDF'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
