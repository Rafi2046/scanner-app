import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/signature_pad.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';
import 'package:signature/signature.dart';

class SignatureView extends ConsumerStatefulWidget {
  const SignatureView({super.key});

  @override
  ConsumerState<SignatureView> createState() => _SignatureViewState();
}

class _SignatureViewState extends ConsumerState<SignatureView> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
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

    return LoadingOverlay(
      visible: busy,
      message: 'Stamping signature…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign PDF'),
        ),
        body: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Draw your signature, then pick a PDF and page.'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SignaturePad(controller: _controller),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Page number',
                  border: OutlineInputBorder(),
                ),
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
                label: 'Stamp Signature',
                onPressed: (_selectedId == null || busy)
                    ? null
                    : () => _stamp(pdfs),
              ),
            ),
          ],
        ),
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

    final ScannedDocument doc = pdfs.firstWhere(
      (ScannedDocument d) => d.id == _selectedId,
    );
    final int page = int.tryParse(_pageController.text.trim()) ?? 1;
    await ref.read(pdfToolsNotifierProvider.notifier).addSignature(
          pdfPath: doc.pdfPath!,
          signaturePng: png,
          pageNumber: page,
        );
  }
}
