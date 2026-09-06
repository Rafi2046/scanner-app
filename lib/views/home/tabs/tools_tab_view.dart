import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/views/tools/widgets/tools_hub_bento_grid.dart';

/// Tab 2: locked quality-only tools in a premium bento grid.
class ToolsTabView extends StatelessWidget {
  const ToolsTabView({
    super.key,
    required this.onSmartScan,
    required this.onIdCategory,
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
  final ValueChanged<IdCardCategory> onIdCategory;
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
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        AppConstants.spaceLg,
        AppConstants.pagePadding,
        AppConstants.bottomNavClearance,
      ),
      children: <Widget>[
        const Text(
          'Tools',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Offline tools that just work',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        ToolsHubBentoGrid(
          onSmartScan: onSmartScan,
          onOcr: onOcr,
          onImport: onImport,
          onIdCategory: onIdCategory,
          onMerge: onMergePdf,
          onWatermark: onWatermark,
          onSign: onSign,
          onLock: onPasswordLock,
          onCompress: onCompress,
          onPdfToImages: onPdfToImage,
        ),
      ],
    );
  }
}
