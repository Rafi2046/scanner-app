import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/providers/document_scan_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';
import 'package:scanner_app/views/home/widgets/tools_section_card.dart';
import 'package:scanner_app/views/id_card_scan/id_card_scan_view.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

/// Standalone tools hub (same pastel language as the Tools tab).
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
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          title: const Text(
            'Tools Hub',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.spaceLg,
            AppConstants.pagePadding,
            AppConstants.spaceXxl,
          ),
          children: <Widget>[
            ToolsSectionCard(
              title: 'Scan & Capture',
              children: <Widget>[
                ToolCircleItem(
                  icon: Icons.document_scanner_rounded,
                  label: 'Smart Scan',
                  color: AppTheme.accentOrange,
                  onTap: () {
                    ref
                        .read(documentScanNotifierProvider.notifier)
                        .startDocumentScan();
                    Navigator.of(context).pop();
                  },
                ),
                ToolCircleItem(
                  icon: Icons.badge_outlined,
                  label: 'ID Card',
                  color: AppTheme.accentBrown,
                  onTap: () => _open(context, const IdCardScanView()),
                ),
                ToolCircleItem(
                  icon: Icons.text_fields_rounded,
                  label: 'OCR',
                  color: AppTheme.accentGold,
                  onTap: () => _open(context, const OcrResultView()),
                ),
                ToolCircleItem(
                  icon: Icons.file_upload_outlined,
                  label: 'Import',
                  color: AppTheme.accentBlue,
                  onTap: () =>
                      ref.read(pdfToolsNotifierProvider.notifier).importFiles(),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceLg),
            ToolsSectionCard(
              title: 'PDF Tools',
              children: <Widget>[
                ToolCircleItem(
                  icon: Icons.call_merge_rounded,
                  label: 'Merge',
                  color: AppTheme.accentPink,
                  onTap: () => _open(context, const MergePdfView()),
                ),
                ToolCircleItem(
                  icon: Icons.branding_watermark_outlined,
                  label: 'Watermark',
                  color: AppTheme.accentPurple,
                  onTap: () => _open(context, const WatermarkView()),
                ),
                ToolCircleItem(
                  icon: Icons.draw_outlined,
                  label: 'Sign',
                  color: AppTheme.accentRed,
                  onTap: () => _open(context, const SignatureView()),
                ),
                ToolCircleItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Protect',
                  color: AppTheme.accentTeal,
                  onTap: () => _open(context, const PasswordLockView()),
                ),
                ToolCircleItem(
                  icon: Icons.compress_rounded,
                  label: 'Compress',
                  color: AppTheme.accentGold,
                  onTap: () => _open(context, const CompressView()),
                ),
                ToolCircleItem(
                  icon: Icons.image_outlined,
                  label: 'To Image',
                  color: AppTheme.accentBlue,
                  onTap: () => _open(context, const PdfToImageView()),
                ),
              ],
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
