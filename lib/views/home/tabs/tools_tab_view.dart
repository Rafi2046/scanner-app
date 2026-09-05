import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';
import 'package:scanner_app/views/home/widgets/tools_section_card.dart';

/// Tab 2: Tools hub with monochrome Lucide shortcuts.
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
              icon: LucideIcons.scanLine,
              label: 'Smart Scan',
              onTap: onSmartScan,
            ),
            ToolCircleItem(
              icon: LucideIcons.creditCard,
              label: 'ID Card',
              onTap: onIdCard,
            ),
            ToolCircleItem(
              icon: LucideIcons.type,
              label: 'OCR',
              onTap: onOcr,
            ),
            ToolCircleItem(
              icon: LucideIcons.upload,
              label: 'Import',
              onTap: onImport,
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
              onTap: onMergePdf,
            ),
            ToolCircleItem(
              icon: LucideIcons.stamp,
              label: 'Watermark',
              onTap: onWatermark,
            ),
            ToolCircleItem(
              icon: LucideIcons.pencil,
              label: 'Sign',
              onTap: onSign,
            ),
            ToolCircleItem(
              icon: LucideIcons.lock,
              label: 'Protect',
              onTap: onPasswordLock,
            ),
            ToolCircleItem(
              icon: LucideIcons.minimize2,
              label: 'Compress',
              onTap: onCompress,
            ),
            ToolCircleItem(
              icon: LucideIcons.image,
              label: 'To Image',
              onTap: onPdfToImage,
            ),
          ],
        ),
      ],
    );
  }
}
