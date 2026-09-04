import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tool_screen_scaffold.dart';

class CompressView extends ConsumerStatefulWidget {
  const CompressView({super.key});

  @override
  ConsumerState<CompressView> createState() => _CompressViewState();
}

class _CompressViewState extends ConsumerState<CompressView> {
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
      title: 'Compress PDF',
      subtitle: 'Reduce file size by recompressing page images.',
      busy: busy,
      busyMessage: 'Compressing…',
      actionLabel: 'Compress',
      actionEnabled: _selectedId != null,
      onAction: () {
        final ScannedDocument doc =
            pdfs.firstWhere((ScannedDocument d) => d.id == _selectedId);
        ref.read(pdfToolsNotifierProvider.notifier).compressPdf(
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
