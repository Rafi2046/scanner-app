import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// White card wrapping a wrap of tool circles.
class ToolsSectionCard extends StatelessWidget {
  const ToolsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Wrap(
            spacing: AppConstants.spaceMd,
            runSpacing: AppConstants.spaceLg,
            children: children
                .map(
                  (Widget child) => SizedBox(
                    width: 72,
                    child: child,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
