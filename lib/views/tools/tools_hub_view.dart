import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/document_scan/custom_scan_view.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';
import 'package:scanner_app/views/tools/widgets/pdf_tools_listener.dart';
import 'package:scanner_app/views/tools/widgets/tools_hub_bento_grid.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

/// Standalone Tools Hub — locked quality-only offline tools (bento grid).
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
            'Tools',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.spaceSm,
            AppConstants.pagePadding,
            AppConstants.spaceXxl,
          ),
          children: <Widget>[
            ToolsHubBentoGrid(
              onSmartScan: () => _open(
                context,
                const CustomScanView(mode: CustomScanMode.document),
              ),
              onOcr: () => _open(context, const OcrResultView()),
              onImport: () =>
                  ref.read(pdfToolsNotifierProvider.notifier).importFiles(),
              onIdCategory: (IdCardCategory cat) => _openIdScan(context, cat),
              onMerge: () => _open(context, const MergePdfView()),
              onWatermark: () => _open(context, const WatermarkView()),
              onSign: () => _open(context, const SignatureView()),
              onLock: () => _open(context, const PasswordLockView()),
              onCompress: () => _open(context, const CompressView()),
              onPdfToImages: () => _open(context, const PdfToImageView()),
            ),
          ],
        ),
      ),
    );
  }

  void _openIdScan(BuildContext context, IdCardCategory category) {
    _open(
      context,
      CustomScanView(
        mode: CustomScanMode.idCard,
        idCategory: category,
        enterIdCamera: true,
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
