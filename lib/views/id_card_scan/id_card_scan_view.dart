import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/providers/id_card_scan_provider.dart';
import 'package:scanner_app/providers/id_card_scan_state.dart';
import 'package:scanner_app/views/id_card_scan/widgets/id_card_side_preview.dart';
import 'package:scanner_app/views/id_card_scan/widgets/id_card_step_indicator.dart';
import 'package:scanner_app/views/widgets/dark_scan_scaffold.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// ID card front/back capture flow (dark scan shell).
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

    final notifier = ref.read(idCardScanNotifierProvider.notifier);

    return LoadingOverlay(
      visible: scanState.isProcessing,
      message: 'Generating PDF…',
      child: DarkScanScaffold(
        title: 'Scan ID Card',
        bottomBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrimaryButton(
              label: scanState.sides.hasFront
                  ? 'Rescan Front'
                  : 'Scan Front Side',
              onPressed: scanState.isProcessing ? null : notifier.scanFront,
            ),
            const SizedBox(height: AppConstants.spaceSm),
            PrimaryButton(
              label:
                  scanState.sides.hasBack ? 'Rescan Back' : 'Scan Back Side',
              onPressed: (!scanState.canScanBack || scanState.isProcessing)
                  ? null
                  : notifier.scanBack,
            ),
            if (scanState.canGenerate) ...<Widget>[
              const SizedBox(height: AppConstants.spaceMd),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: notifier.generateIdCardPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusPill),
                    ),
                  ),
                  child: const Text(
                    'Generate PDF',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Scan the front side first, then the back. Both images will '
                  'be placed on a single A4 PDF.',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceLg),
                IdCardStepIndicator(step: scanState.step),
                const SizedBox(height: AppConstants.spaceXl),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      IdCardSidePreview(
                        label: 'Front',
                        imagePath: scanState.sides.frontPath,
                      ),
                      const SizedBox(height: AppConstants.spaceLg),
                      IdCardSidePreview(
                        label: 'Back',
                        imagePath: scanState.sides.backPath,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
