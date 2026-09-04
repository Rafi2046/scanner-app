import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tool_screen_scaffold.dart';

class MergePdfView extends ConsumerStatefulWidget {
  const MergePdfView({super.key});

  @override
  ConsumerState<MergePdfView> createState() => _MergePdfViewState();
}

class _MergePdfViewState extends ConsumerState<MergePdfView> {
  final Set<String> _selectedIds = <String>{};

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
      title: 'Merge PDF',
      subtitle: '${_selectedIds.length} selected · pick at least two files',
      busy: busy,
      busyMessage: 'Merging…',
      actionLabel: 'Merge',
      actionEnabled: _selectedIds.length >= 2,
      onAction: () {
        final List<String> paths = pdfs
            .where((ScannedDocument d) => _selectedIds.contains(d.id))
            .map((ScannedDocument d) => d.pdfPath!)
            .toList();
        ref.read(pdfToolsNotifierProvider.notifier).mergePdfs(paths);
      },
      body: PdfDocumentSelector(
        documents: pdfs,
        selectedIds: _selectedIds,
        onToggle: (ScannedDocument doc) {
          setState(() {
            if (_selectedIds.contains(doc.id)) {
              _selectedIds.remove(doc.id);
            } else {
              _selectedIds.add(doc.id);
            }
          });
        },
      ),
    );
  }
}
