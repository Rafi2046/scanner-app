import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Quick action strip shown directly beneath the most recent document.
class RecentDocActionStrip extends StatelessWidget {
  const RecentDocActionStrip({
    super.key,
    required this.onShare,
    required this.onOcr,
    required this.onView,
  });

  final VoidCallback onShare;
  final VoidCallback onOcr;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ActionPill(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: onShare,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.auto_awesome,
              label: 'OCR Text',
              isAccent: true,
              onTap: onOcr,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.visibility_outlined,
              label: 'View',
              onTap: onView,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final Color fgColor =
        isAccent ? AppTheme.primaryMint : AppTheme.textPrimary;
    final Color bgColor = isAccent
        ? AppTheme.primaryMint.withValues(alpha: 0.14)
        : AppTheme.cardColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
