import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// "Recent Files" section title row.
class RecentFilesHeader extends StatelessWidget {
  const RecentFilesHeader({
    super.key,
    this.count,
    this.onSeeAll,
  });

  final int? count;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Recent Files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (count != null && count! > 0)
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
