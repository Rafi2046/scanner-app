import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';

/// 2×4 monochrome Lucide quick-tools grid on Home.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ToolsRow(
          children: <Widget>[
            ToolCircleItem(
              icon: LucideIcons.scanLine,
              label: 'Scan',
              onTap: onSmartScan,
            ),
            ToolCircleItem(
              icon: LucideIcons.creditCard,
              label: 'ID Card',
              onTap: onIdCard,
            ),
            ToolCircleItem(
              icon: LucideIcons.pencil,
              label: 'eSign',
              onTap: onSign,
            ),
            ToolCircleItem(
              icon: LucideIcons.stamp,
              label: 'Watermark',
              onTap: onWatermark,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceMd),
        _ToolsRow(
          children: <Widget>[
            ToolCircleItem(
              icon: LucideIcons.combine,
              label: 'Merge',
              onTap: onMergePdf,
            ),
            ToolCircleItem(
              icon: LucideIcons.lock,
              label: 'Protect',
              onTap: onProtect,
            ),
            ToolCircleItem(
              icon: LucideIcons.type,
              label: 'OCR',
              onTap: onOcr,
            ),
            ToolCircleItem(
              icon: LucideIcons.layoutGrid,
              label: 'All Tools',
              onTap: onAllTools,
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final Widget child in children) Expanded(child: child),
      ],
    );
  }
}
