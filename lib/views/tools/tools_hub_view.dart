import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/document_scan/custom_scan_view.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';
import 'package:scanner_app/views/home/widgets/tools_section_card.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

/// Standalone tools hub (same monochrome Lucide language as the Tools tab).
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
                  icon: LucideIcons.scanLine,
                  label: 'Smart Scan',
                  onTap: () => _open(
                    context,
                    const CustomScanView(mode: CustomScanMode.document),
                  ),
                ),
                ToolCircleItem(
                  icon: LucideIcons.creditCard,
                  label: 'ID Card',
                  onTap: () => _open(
                    context,
                    const CustomScanView(mode: CustomScanMode.idCard),
                  ),
                ),
                ToolCircleItem(
                  icon: LucideIcons.type,
                  label: 'OCR',
                  onTap: () => _open(context, const OcrResultView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.upload,
                  label: 'Import',
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
                  icon: LucideIcons.combine,
                  label: 'Merge',
                  onTap: () => _open(context, const MergePdfView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.stamp,
                  label: 'Watermark',
                  onTap: () => _open(context, const WatermarkView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.pencil,
                  label: 'Sign',
                  onTap: () => _open(context, const SignatureView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.lock,
                  label: 'Protect',
                  onTap: () => _open(context, const PasswordLockView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.minimize2,
                  label: 'Compress',
                  onTap: () => _open(context, const CompressView()),
                ),
                ToolCircleItem(
                  icon: LucideIcons.image,
                  label: 'To Image',
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
