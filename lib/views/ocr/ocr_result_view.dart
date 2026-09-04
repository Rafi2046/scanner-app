import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/ocr_provider.dart';
import 'package:scanner_app/views/ocr/widgets/ocr_text_panel.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

class OcrResultView extends ConsumerWidget {
  const OcrResultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenAsyncError(ref, ocrNotifierProvider, context);
    final AsyncValue<String?> ocr = ref.watch(ocrNotifierProvider);
    final List<ScannedDocument> withImages = ref
            .watch(libraryNotifierProvider)
            .valueOrNull
            ?.where((ScannedDocument d) => d.imagePaths.isNotEmpty)
            .toList() ??
        const <ScannedDocument>[];

    return LoadingOverlay(
      visible: ocr.isLoading,
      message: 'Extracting text…',
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          title: const Text(
            'OCR',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                AppConstants.spaceSm,
                AppConstants.pagePadding,
                AppConstants.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Extract text from a photo or a scanned page.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  PrimaryButton(
                    label: 'Pick image from files',
                    onPressed: ocr.isLoading
                        ? null
                        : () => ref
                            .read(ocrNotifierProvider.notifier)
                            .pickImageAndExtract(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.pagePadding,
              ),
              child: Text(
                'Or choose a scanned page',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Expanded(
              child: withImages.isEmpty
                  ? const Center(
                      child: Text(
                        'No scanned images in the library.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pagePadding,
                      ),
                      itemCount: withImages.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppConstants.spaceSm),
                      itemBuilder: (BuildContext context, int index) {
                        final ScannedDocument doc = withImages[index];
                        return Material(
                          color: AppTheme.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusLg),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusLg),
                            onTap: ocr.isLoading
                                ? null
                                : () => ref
                                    .read(ocrNotifierProvider.notifier)
                                    .extractTextFromImage(
                                      doc.imagePaths.first,
                                    ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppConstants.spaceMd,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusLg,
                                ),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.image_outlined,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: AppConstants.spaceMd),
                                  Expanded(
                                    child: Text(
                                      doc.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            OcrTextPanel(
              text: ocr.valueOrNull,
              onCopy: ocr.valueOrNull == null
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: ocr.valueOrNull!),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
