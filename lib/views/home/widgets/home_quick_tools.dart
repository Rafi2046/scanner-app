import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';

/// 2×4 pastel quick-tools grid on Home.
class HomeQuickTools extends StatelessWidget {
  const HomeQuickTools({
    super.key,
    required this.onSmartScan,
    required this.onIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onWatermark,
    required this.onSign,
    required this.onProtect,
    required this.onAllTools,
  });

  final VoidCallback onSmartScan;
  final VoidCallback onIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onWatermark;
  final VoidCallback onSign;
  final VoidCallback onProtect;
  final VoidCallback onAllTools;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: AppConstants.spaceMd,
      crossAxisSpacing: AppConstants.spaceSm,
      childAspectRatio: 0.78,
      children: <Widget>[
        ToolCircleItem(
          icon: Icons.document_scanner_rounded,
          label: 'Scan',
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
          icon: Icons.draw_outlined,
          label: 'eSign',
          color: AppTheme.accentRed,
          onTap: onSign,
        ),
        ToolCircleItem(
          icon: Icons.branding_watermark_outlined,
          label: 'Watermark',
          color: AppTheme.accentPurple,
          onTap: onWatermark,
        ),
        ToolCircleItem(
          icon: Icons.call_merge_rounded,
          label: 'Merge',
          color: AppTheme.accentPink,
          onTap: onMergePdf,
        ),
        ToolCircleItem(
          icon: Icons.lock_outline_rounded,
          label: 'Protect',
          color: AppTheme.accentTeal,
          onTap: onProtect,
        ),
        ToolCircleItem(
          icon: Icons.text_fields_rounded,
          label: 'OCR',
          color: AppTheme.accentGold,
          onTap: onOcr,
        ),
        ToolCircleItem(
          icon: Icons.grid_view_rounded,
          label: 'All Tools',
          color: AppTheme.accentBlue,
          onTap: onAllTools,
        ),
      ],
    );
  }
}
