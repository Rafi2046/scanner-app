import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Empty library placeholder.
class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    this.onScan,
    this.title = 'No documents yet',
    this.subtitle = 'Tap + to scan your first file.',
  });

  final VoidCallback? onScan;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceXxl,
        vertical: AppConstants.spaceXxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (onScan != null) ...<Widget>[
            const SizedBox(height: AppConstants.spaceLg),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Scan document'),
            ),
          ],
        ],
      ),
    );
  }
}
