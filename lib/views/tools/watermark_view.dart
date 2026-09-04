import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/app_text_field.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tool_screen_scaffold.dart';

class WatermarkView extends ConsumerStatefulWidget {
  const WatermarkView({super.key});

  @override
  ConsumerState<WatermarkView> createState() => _WatermarkViewState();
}

class _WatermarkViewState extends ConsumerState<WatermarkView> {
  final TextEditingController _textController = TextEditingController(
    text: 'CONFIDENTIAL',
  );
  String? _selectedId;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
      title: 'Add Watermark',
      subtitle: 'Text is stamped diagonally across every page.',
      busy: busy,
      busyMessage: 'Adding watermark…',
      actionLabel: 'Apply Watermark',
      actionEnabled: _selectedId != null && _textController.text.trim().isNotEmpty,
      onAction: () {
        final ScannedDocument doc =
            pdfs.firstWhere((ScannedDocument d) => d.id == _selectedId);
        ref.read(pdfToolsNotifierProvider.notifier).addWatermark(
              pdfPath: doc.pdfPath!,
              text: _textController.text,
            );
      },
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
            ),
            child: AppTextField(
              controller: _textController,
              label: 'Your text',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Expanded(
            child: PdfDocumentSelector(
              documents: pdfs,
              selectedIds: _selectedId == null
                  ? const <String>{}
                  : <String>{_selectedId!},
              multiSelect: false,
              onToggle: (ScannedDocument doc) {
                setState(() => _selectedId = doc.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
