import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        appBar: AppBar(
          title: const Text('OCR'),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Pick image from files',
                onPressed: ocr.isLoading
                    ? null
                    : () => ref
                        .read(ocrNotifierProvider.notifier)
                        .pickImageAndExtract(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Or choose a scanned page'),
              ),
            ),
            Expanded(
              child: withImages.isEmpty
                  ? const Center(child: Text('No scanned images in the library.'))
                  : ListView.separated(
                      itemCount: withImages.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final ScannedDocument doc = withImages[index];
                        return ListTile(
                          leading: const Icon(Icons.image_outlined),
                          title: Text(doc.title),
                          onTap: ocr.isLoading
                              ? null
                              : () => ref
                                  .read(ocrNotifierProvider.notifier)
                                  .extractTextFromImage(doc.imagePaths.first),
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
