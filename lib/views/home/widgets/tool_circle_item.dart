import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Pastel circular tool shortcut.
class ToolCircleItem extends StatelessWidget {
  const ToolCircleItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.tag,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppConstants.toolCircleSize,
            height: AppConstants.toolCircleSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppConstants.toolIconSize,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
