import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';
import 'package:scanner_app/views/home/widgets/tools_section_card.dart';

/// Tab 2: Tools hub with pastel shortcuts.
class ToolsTabView extends StatelessWidget {
  const ToolsTabView({
    super.key,
    required this.onSmartScan,
    required this.onIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onWatermark,
    required this.onSign,
    required this.onPasswordLock,
    required this.onCompress,
    required this.onPdfToImage,
    required this.onImport,
  });

  final VoidCallback onSmartScan;
  final VoidCallback onIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onWatermark;
  final VoidCallback onSign;
  final VoidCallback onPasswordLock;
  final VoidCallback onCompress;
  final VoidCallback onPdfToImage;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        AppConstants.spaceLg,
        AppConstants.pagePadding,
        AppConstants.bottomNavClearance,
      ),
      children: <Widget>[
        const Text(
          'All Tools',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        ToolsSectionCard(
          title: 'Scan & Capture',
          children: <Widget>[
            ToolCircleItem(
              icon: Icons.document_scanner_rounded,
              label: 'Smart Scan',
              color: AppTheme.accentOrange,
              onTap: onSmartScan,
            ),
            ToolCircleItem(
              icon: Icons.badge_outlined,
              label: 'ID Card',
              color: AppTheme.accentBrown,
              onTap: onIdCard,
            ),
            ToolCircleItem(
              icon: Icons.text_fields_rounded,
              label: 'OCR',
              color: AppTheme.accentGold,
              onTap: onOcr,
            ),
            ToolCircleItem(
              icon: Icons.file_upload_outlined,
              label: 'Import',
              color: AppTheme.accentBlue,
              onTap: onImport,
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
              onTap: onMergePdf,
            ),
            ToolCircleItem(
              icon: Icons.branding_watermark_outlined,
              label: 'Watermark',
              color: AppTheme.accentPurple,
              onTap: onWatermark,
            ),
            ToolCircleItem(
              icon: Icons.draw_outlined,
              label: 'Sign',
              color: AppTheme.accentRed,
              onTap: onSign,
            ),
            ToolCircleItem(
              icon: Icons.lock_outline_rounded,
              label: 'Protect',
              color: AppTheme.accentTeal,
              onTap: onPasswordLock,
            ),
            ToolCircleItem(
              icon: Icons.compress_rounded,
              label: 'Compress',
              color: AppTheme.accentGold,
              onTap: onCompress,
            ),
            ToolCircleItem(
              icon: Icons.image_outlined,
              label: 'To Image',
              color: AppTheme.accentBlue,
              onTap: onPdfToImage,
            ),
          ],
        ),
      ],
    );
  }
}
