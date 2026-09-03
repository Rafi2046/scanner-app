import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/tools/widgets/pdf_document_selector.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

class PasswordLockView extends ConsumerStatefulWidget {
  const PasswordLockView({super.key});

  @override
  ConsumerState<PasswordLockView> createState() => _PasswordLockViewState();
}

class _PasswordLockViewState extends ConsumerState<PasswordLockView> {
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedId;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
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
      message: 'Encrypting…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Password Lock'),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password (min 4 characters)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose a PDF'),
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
                label: 'Lock PDF',
                onPressed: (_selectedId == null || busy)
                    ? null
                    : () {
                        final ScannedDocument doc = pdfs.firstWhere(
                          (ScannedDocument d) => d.id == _selectedId,
                        );
                        ref.read(pdfToolsNotifierProvider.notifier).lockPdf(
                              pdfPath: doc.pdfPath!,
                              password: _passwordController.text,
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
