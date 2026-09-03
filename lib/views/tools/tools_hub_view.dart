import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tool_hub_tile.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

class ToolsHubView extends ConsumerWidget {
  const ToolsHubView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenPdfToolsResult(ref, context);
    final bool busy = ref.watch(pdfToolsNotifierProvider).isBusy;

    return LoadingOverlay(
      visible: busy,
      message: 'Working…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tools'),
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: <Widget>[
            ToolHubTile(
              icon: Icons.text_fields_outlined,
              label: 'OCR',
              onTap: () => _open(context, const OcrResultView()),
            ),
            ToolHubTile(
              icon: Icons.file_upload_outlined,
              label: 'Import',
              onTap: () =>
                  ref.read(pdfToolsNotifierProvider.notifier).importFiles(),
            ),
            ToolHubTile(
              icon: Icons.merge_outlined,
              label: 'Merge PDFs',
              onTap: () => _open(context, const MergePdfView()),
            ),
            ToolHubTile(
              icon: Icons.branding_watermark_outlined,
              label: 'Watermark',
              onTap: () => _open(context, const WatermarkView()),
            ),
            ToolHubTile(
              icon: Icons.draw_outlined,
              label: 'Sign',
              onTap: () => _open(context, const SignatureView()),
            ),
            ToolHubTile(
              icon: Icons.lock_outline,
              label: 'Password Lock',
              onTap: () => _open(context, const PasswordLockView()),
            ),
            ToolHubTile(
              icon: Icons.compress,
              label: 'Compress',
              onTap: () => _open(context, const CompressView()),
            ),
            ToolHubTile(
              icon: Icons.image_outlined,
              label: 'PDF to Image',
              onTap: () => _open(context, const PdfToImageView()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
