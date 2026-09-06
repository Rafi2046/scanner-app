import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/views/tools/widgets/tools_hub_bento_tile.dart';
import 'package:scanner_app/views/tools/widgets/tools_id_card_category_grid.dart';

/// Locked quality-only tools in a scrollable bento layout.
class ToolsHubBentoGrid extends StatelessWidget {
  const ToolsHubBentoGrid({
    super.key,
    required this.onSmartScan,
    required this.onOcr,
    required this.onImport,
    required this.onIdCategory,
    required this.onMerge,
    required this.onWatermark,
    required this.onSign,
    required this.onLock,
    required this.onCompress,
    required this.onPdfToImages,
  });

  final VoidCallback onSmartScan;
  final VoidCallback onOcr;
  final VoidCallback onImport;
  final ValueChanged<IdCardCategory> onIdCategory;
  final VoidCallback onMerge;
  final VoidCallback onWatermark;
  final VoidCallback onSign;
  final VoidCallback onLock;
  final VoidCallback onCompress;
  final VoidCallback onPdfToImages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionLabel('Capture & Process'),
        const SizedBox(height: AppConstants.spaceMd),
        ToolsHubBentoTile(
          title: 'Smart Scan',
          subtitle: 'Auto edges, enhance & multi-page PDF',
          icon: LucideIcons.scanLine,
          size: ToolsHubTileSize.hero,
          accent: AppTheme.primary,
          onTap: onSmartScan,
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 118,
                child: ToolsHubBentoTile(
                  title: 'OCR',
                  subtitle: 'Extract text',
                  icon: LucideIcons.type,
                  accent: AppTheme.accentTeal,
                  onTap: onOcr,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: SizedBox(
                height: 118,
                child: ToolsHubBentoTile(
                  title: 'Import Files',
                  subtitle: 'PDFs & images',
                  icon: LucideIcons.upload,
                  accent: AppTheme.accentPurple,
                  onTap: onImport,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceXxl),
        const _SectionLabel('ID Card'),
        const SizedBox(height: AppConstants.spaceMd),
        ToolsIdCardCategoryGrid(onIdCategory: onIdCategory),
        const SizedBox(height: AppConstants.spaceXxl),
        const _SectionLabel('PDF Edit & Protect'),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 112,
                child: ToolsHubBentoTile(
                  title: 'Merge Files',
                  subtitle: 'Combine PDFs',
                  icon: LucideIcons.combine,
                  size: ToolsHubTileSize.compact,
                  accent: AppTheme.accentOrange,
                  onTap: onMerge,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: SizedBox(
                height: 112,
                child: ToolsHubBentoTile(
                  title: 'Watermark',
                  subtitle: 'Stamp text',
                  icon: LucideIcons.stamp,
                  size: ToolsHubTileSize.compact,
                  accent: AppTheme.accentPink,
                  onTap: onWatermark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 112,
                child: ToolsHubBentoTile(
                  title: 'Sign',
                  subtitle: 'Draw & place',
                  icon: LucideIcons.penTool,
                  size: ToolsHubTileSize.compact,
                  accent: AppTheme.accentTeal,
                  onTap: onSign,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: SizedBox(
                height: 112,
                child: ToolsHubBentoTile(
                  title: 'Lock',
                  subtitle: 'Password PDF',
                  icon: LucideIcons.lock,
                  size: ToolsHubTileSize.compact,
                  accent: AppTheme.accentBrown,
                  onTap: onLock,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceXxl),
        const _SectionLabel('Optimize & Export'),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 118,
                child: ToolsHubBentoTile(
                  title: 'Compress PDF',
                  subtitle: 'Smaller file size',
                  icon: LucideIcons.minimize2,
                  accent: AppTheme.accentGold,
                  onTap: onCompress,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: SizedBox(
                height: 118,
                child: ToolsHubBentoTile(
                  title: 'PDF to Images',
                  subtitle: 'Export pages',
                  icon: LucideIcons.image,
                  accent: AppTheme.primary,
                  onTap: onPdfToImages,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }
}
