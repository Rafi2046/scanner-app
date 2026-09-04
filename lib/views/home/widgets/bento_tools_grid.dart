import 'package:flutter/material.dart';
import 'package:scanner_app/views/home/widgets/bento_tool_card.dart';

/// Bento Grid displaying quick productivity tools.
class BentoToolsGrid extends StatelessWidget {
  const BentoToolsGrid({
    super.key,
    required this.onScanDocument,
    required this.onScanIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onMoreTools,
  });

  final VoidCallback onScanDocument;
  final VoidCallback onScanIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onMoreTools;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Hero Featured Bento Card: Smart Scan
        BentoToolCard(
          title: 'Smart Scan',
          subtitle: 'Auto edge detection & multi-page scan',
          icon: Icons.document_scanner_rounded,
          tag: 'HD AI',
          accentColor: const Color(0xFF4F46E5),
          heroGradient: const LinearGradient(
            colors: <Color>[Color(0xFF4F46E5), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isHero: true,
          onTap: onScanDocument,
        ),
        const SizedBox(height: 12),
        // 2x2 Bento Subgrid
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 116,
                child: BentoToolCard(
                  title: 'ID Card',
                  subtitle: 'Front & back stitch',
                  icon: Icons.badge_outlined,
                  tag: '2-IN-1',
                  accentColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  onTap: onScanIdCard,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 116,
                child: BentoToolCard(
                  title: 'Text OCR',
                  subtitle: 'Extract text live',
                  icon: Icons.text_fields_rounded,
                  tag: 'AI',
                  accentColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFECFDF5),
                  onTap: onOcr,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 116,
                child: BentoToolCard(
                  title: 'Merge PDF',
                  subtitle: 'Combine documents',
                  icon: Icons.call_merge_rounded,
                  tag: 'PDF',
                  accentColor: const Color(0xFFD97706),
                  iconBgColor: const Color(0xFFFFFBEB),
                  onTap: onMergePdf,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 116,
                child: BentoToolCard(
                  title: 'All Tools',
                  subtitle: 'Compress, sign & more',
                  icon: Icons.grid_view_rounded,
                  tag: '8+',
                  accentColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  onTap: onMoreTools,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
