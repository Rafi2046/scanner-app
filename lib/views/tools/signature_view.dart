import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/app_text_field.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/signature_pad.dart';
import 'package:scanner_app/views/tools/widgets/tool_screen_scaffold.dart';
import 'package:signature/signature.dart';

class SignatureView extends ConsumerStatefulWidget {
  const SignatureView({super.key});

  @override
  ConsumerState<SignatureView> createState() => _SignatureViewState();
}

class _SignatureViewState extends ConsumerState<SignatureView> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppTheme.textPrimary,
    exportBackgroundColor: Colors.transparent,
  );
  final TextEditingController _pageController = TextEditingController(text: '1');
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
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
      title: 'eSign PDF',
      subtitle: 'Draw a signature, choose a PDF, then stamp it.',
      busy: busy,
      busyMessage: 'Stamping signature…',
      actionLabel: 'Stamp Signature',
      actionEnabled: _selectedId != null,
      onAction: () => _stamp(pdfs),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
            ),
            child: SignaturePad(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppConstants.spaceSm,
              AppConstants.pagePadding,
              AppConstants.spaceMd,
            ),
            child: AppTextField(
              controller: _pageController,
              label: 'Page number',
              keyboardType: TextInputType.number,
            ),
          ),
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

  Future<void> _stamp(List<ScannedDocument> pdfs) async {
    final Uint8List? png = await _controller.toPngBytes();
    if (png == null || png.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw a signature first.')),
      );
      return;
    }

    final ScannedDocument doc =
        pdfs.firstWhere((ScannedDocument d) => d.id == _selectedId);
    final int page = int.tryParse(_pageController.text.trim()) ?? 1;
    await ref.read(pdfToolsNotifierProvider.notifier).addSignature(
          pdfPath: doc.pdfPath!,
          signaturePng: png,
          pageNumber: page,
        );
  }
}
