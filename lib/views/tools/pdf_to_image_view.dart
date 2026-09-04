import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tool_screen_scaffold.dart';

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

    return ToolScreenScaffold(
      title: 'PDF to Image',
      subtitle: 'Each page is exported as JPEG into your library.',
      busy: busy,
      busyMessage: 'Exporting images…',
      actionLabel: 'Export Images',
      actionEnabled: _selectedId != null,
      onAction: () {
        final ScannedDocument doc =
            pdfs.firstWhere((ScannedDocument d) => d.id == _selectedId);
        ref.read(pdfToolsNotifierProvider.notifier).pdfToImages(
              pdfPath: doc.pdfPath!,
            );
      },
      body: PdfDocumentSelector(
        documents: pdfs,
        selectedIds:
            _selectedId == null ? const <String>{} : <String>{_selectedId!},
        multiSelect: false,
        onToggle: (ScannedDocument doc) {
          setState(() => _selectedId = doc.id);
        },
      ),
    );
  }
}
