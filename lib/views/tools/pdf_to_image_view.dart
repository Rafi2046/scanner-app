import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

class PdfToImageView extends ConsumerStatefulWidget {
  const PdfToImageView({super.key});

  @override
  ConsumerState<PdfToImageView> createState() => _PdfToImageViewState();
}

class _PdfToImageViewState extends ConsumerState<PdfToImageView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    listenPdfToolsResult(ref, context, popOnSuccess: true);
    final bool busy = ref.watch(pdfToolsNotifierProvider).isBusy;
    final List<ScannedDocument> pdfs = ref
            .watch(libraryNotifierProvider)
            .valueOrNull
            ?.where((ScannedDocument d) => d.hasPdf)
            .toList() ??
        const <ScannedDocument>[];

    return LoadingOverlay(
      visible: busy,
      message: 'Exporting images…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PDF to Image'),
        ),
        body: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Each page is saved as a JPEG and added to your library.',
              ),
            ),
            Expanded(
              child: PdfDocumentSelector(
                documents: pdfs,
                selectedIds:
                    _selectedId == null ? const <String>{} : <String>{_selectedId!},
                multiSelect: false,
                onToggle: (ScannedDocument doc) {
                  setState(() => _selectedId = doc.id);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Export Images',
                onPressed: (_selectedId == null || busy)
                    ? null
                    : () {
                        final ScannedDocument doc = pdfs.firstWhere(
                          (ScannedDocument d) => d.id == _selectedId,
                        );
                        ref.read(pdfToolsNotifierProvider.notifier).pdfToImages(
                              pdfPath: doc.pdfPath!,
                            );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
