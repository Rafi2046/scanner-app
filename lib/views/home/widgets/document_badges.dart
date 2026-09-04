import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/enums/document_kind.dart';

/// Tag badge displaying the origin/kind of document.
class DocumentKindBadge extends StatelessWidget {
  const DocumentKindBadge({super.key, required this.kind});

  final DocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final String label = switch (kind) {
      DocumentKind.idCard => 'ID CARD',
      DocumentKind.scan => 'SCAN',
      DocumentKind.imported => 'IMPORT',
      DocumentKind.toolOutput => 'TOOL',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBorder,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Tag badge indicating PDF format availability.
class PdfFormatBadge extends StatelessWidget {
  const PdfFormatBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryMint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PDF',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryMint,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
