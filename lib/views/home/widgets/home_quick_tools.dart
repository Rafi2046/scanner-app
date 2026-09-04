import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Quick tool launcher icons row on the Home tab.
class HomeQuickTools extends StatelessWidget {
  const HomeQuickTools({
    super.key,
    required this.onSmartScan,
    required this.onIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onAllTools,
  });

  final VoidCallback onSmartScan;
  final VoidCallback onIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onAllTools;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _ToolCircleButton(
            icon: Icons.document_scanner_rounded,
            label: 'Smart Scan',
            color: AppTheme.primaryMint,
            onTap: onSmartScan,
          ),
          _ToolCircleButton(
            icon: Icons.badge_outlined,
            label: 'ID Card',
            color: const Color(0xFF38BDF8),
            onTap: onIdCard,
          ),
          _ToolCircleButton(
            icon: Icons.text_fields_rounded,
            label: 'Text OCR',
            color: const Color(0xFF34D399),
            onTap: onOcr,
          ),
          _ToolCircleButton(
            icon: Icons.call_merge_rounded,
            label: 'Merge PDF',
            color: const Color(0xFFFBBF24),
            onTap: onMergePdf,
          ),
          _ToolCircleButton(
            icon: Icons.grid_view_rounded,
            label: 'All Tools',
            color: const Color(0xFFA78BFA),
            onTap: onAllTools,
          ),
        ],
      ),
    );
  }
}

class _ToolCircleButton extends StatelessWidget {
  const _ToolCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
