import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Clean modern empty state matching the dark productivity theme.
class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    this.onScan,
    this.title = 'No documents yet',
    this.subtitle = 'Tap below or the camera shutter to scan your first file.',
  });

  final VoidCallback? onScan;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryMint.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primaryMint.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.document_scanner_rounded,
                  size: 44,
                  color: AppTheme.primaryMint,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onScan != null) ...<Widget>[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
                label: const Text(
                  'Scan First Document',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryMint,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
