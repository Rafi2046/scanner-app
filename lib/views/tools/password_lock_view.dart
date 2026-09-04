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

    return ToolScreenScaffold(
      title: 'Protect PDF',
      subtitle: 'Encrypt the file with a password (min 4 characters).',
      busy: busy,
      busyMessage: 'Encrypting…',
      actionLabel: 'Protect',
      actionEnabled:
          _selectedId != null && _passwordController.text.trim().length >= 4,
      onAction: () {
        final ScannedDocument doc =
            pdfs.firstWhere((ScannedDocument d) => d.id == _selectedId);
        ref.read(pdfToolsNotifierProvider.notifier).lockPdf(
              pdfPath: doc.pdfPath!,
              password: _passwordController.text,
            );
      },
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
            ),
            child: AppTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                ),
              ),
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
