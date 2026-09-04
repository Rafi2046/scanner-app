import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/document_scan_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/home/widgets/bento_tool_card.dart';
import 'package:scanner_app/views/id_card_scan/id_card_scan_view.dart';
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

/// Bento Grid Tools Hub with 2026 aesthetics.
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF111827),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Tools Hub',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.4,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: <Widget>[
              // Hero Featured Card: Smart Scan
              BentoToolCard(
                title: 'Smart Scanner',
                subtitle: 'High-res document scanning with AI edge crop',
                icon: Icons.document_scanner_rounded,
                tag: 'PRO AI',
                isHero: true,
                accentColor: const Color(0xFF4F46E5),
                heroGradient: const LinearGradient(
                  colors: <Color>[Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  ref
                      .read(documentScanNotifierProvider.notifier)
                      .startDocumentScan();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              // Category Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'PDF & Scan Utilities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              // Bento Grid of tools
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.32,
                children: <Widget>[
                  ToolHubTile(
                    icon: Icons.badge_outlined,
                    label: 'ID Card Scan',
                    description: 'Front & back stitch',
                    tag: '2-IN-1',
                    accentColor: const Color(0xFF2563EB),
                    onTap: () => _open(context, const IdCardScanView()),
                  ),
                  ToolHubTile(
                    icon: Icons.text_fields_rounded,
                    label: 'OCR Text',
                    description: 'Extract raw text',
                    tag: 'AI',
                    accentColor: const Color(0xFF059669),
                    onTap: () => _open(context, const OcrResultView()),
                  ),
                  ToolHubTile(
                    icon: Icons.file_upload_outlined,
                    label: 'Import File',
                    description: 'From device storage',
                    tag: 'FILE',
                    accentColor: const Color(0xFF0284C7),
                    onTap: () => ref
                        .read(pdfToolsNotifierProvider.notifier)
                        .importFiles(),
                  ),
                  ToolHubTile(
                    icon: Icons.call_merge_rounded,
                    label: 'Merge PDFs',
                    description: 'Join multiple files',
                    tag: 'PDF',
                    accentColor: const Color(0xFFD97706),
                    onTap: () => _open(context, const MergePdfView()),
                  ),
                  ToolHubTile(
                    icon: Icons.branding_watermark_outlined,
                    label: 'Watermark',
                    description: 'Add custom stamp',
                    tag: 'SECURITY',
                    accentColor: const Color(0xFF0D9488),
                    onTap: () => _open(context, const WatermarkView()),
                  ),
                  ToolHubTile(
                    icon: Icons.draw_outlined,
                    label: 'Sign PDF',
                    description: 'Draw or insert signature',
                    tag: 'SIGN',
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () => _open(context, const SignatureView()),
                  ),
                  ToolHubTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Password Lock',
                    description: 'Encrypt document',
                    tag: 'SECURE',
                    accentColor: const Color(0xFFE11D48),
                    onTap: () => _open(context, const PasswordLockView()),
                  ),
                  ToolHubTile(
                    icon: Icons.compress_rounded,
                    label: 'Compress',
                    description: 'Reduce file size',
                    tag: 'SIZE',
                    accentColor: const Color(0xFFEA580C),
                    onTap: () => _open(context, const CompressView()),
                  ),
                  ToolHubTile(
                    icon: Icons.image_outlined,
                    label: 'PDF to Image',
                    description: 'Export as JPEG/PNG',
                    tag: 'IMAGE',
                    accentColor: const Color(0xFF4F46E5),
                    onTap: () => _open(context, const PdfToImageView()),
                  ),
                ],
              ),
            ],
          ),
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
