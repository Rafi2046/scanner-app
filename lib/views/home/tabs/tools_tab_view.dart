import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';
import 'package:scanner_app/views/home/widgets/tools_ai_banner.dart';

/// Tab 2: Categorized Tools Hub view.
class ToolsTabView extends StatelessWidget {
  const ToolsTabView({
    super.key,
    required this.onSmartScan,
    required this.onIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onWatermark,
    required this.onSign,
    required this.onPasswordLock,
    required this.onCompress,
    required this.onPdfToImage,
    required this.onImport,
  });

  final VoidCallback onSmartScan;
  final VoidCallback onIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onWatermark;
  final VoidCallback onSign;
  final VoidCallback onPasswordLock;
  final VoidCallback onCompress;
  final VoidCallback onPdfToImage;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: <Widget>[
        const Text(
          'Tools Hub',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        ToolsAiBanner(onTap: onSmartScan),
        const SizedBox(height: 20),
        _buildSectionHeader('Scan & Capture'),
        const SizedBox(height: 12),
        _buildGrid(<Widget>[
          ToolCircleItem(
            icon: Icons.document_scanner_rounded,
            label: 'Smart Scan',
            color: AppTheme.primaryMint,
            tag: 'HD',
            onTap: onSmartScan,
          ),
          ToolCircleItem(
            icon: Icons.badge_outlined,
            label: 'ID Cards',
            color: const Color(0xFF38BDF8),
            tag: '2-IN-1',
            onTap: onIdCard,
          ),
          ToolCircleItem(
            icon: Icons.text_fields_rounded,
            label: 'Extract Text',
            color: const Color(0xFF34D399),
            tag: 'AI',
            onTap: onOcr,
          ),
          ToolCircleItem(
            icon: Icons.branding_watermark_outlined,
            label: 'Watermark',
            color: const Color(0xFF2DD4BF),
            onTap: onWatermark,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('PDF & Utilities'),
        const SizedBox(height: 12),
        _buildGrid(<Widget>[
          ToolCircleItem(
            icon: Icons.call_merge_rounded,
            label: 'Merge PDF',
            color: const Color(0xFFFBBF24),
            onTap: onMergePdf,
          ),
          ToolCircleItem(
            icon: Icons.compress_rounded,
            label: 'Compress',
            color: const Color(0xFFFB923C),
            onTap: onCompress,
          ),
          ToolCircleItem(
            icon: Icons.draw_outlined,
            label: 'Sign PDF',
            color: const Color(0xFFA78BFA),
            onTap: onSign,
          ),
          ToolCircleItem(
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            color: const Color(0xFFF43F5E),
            onTap: onPasswordLock,
          ),
          ToolCircleItem(
            icon: Icons.image_outlined,
            label: 'To Image',
            color: const Color(0xFF818CF8),
            onTap: onPdfToImage,
          ),
          ToolCircleItem(
            icon: Icons.file_upload_outlined,
            label: 'Import',
            color: const Color(0xFF60A5FA),
            onTap: onImport,
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 12,
        runSpacing: 14,
        children: children
            .map((Widget w) => SizedBox(width: 74, child: w))
            .toList(),
      ),
    );
  }
}
