import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/home/widgets/tool_circle_item.dart';

class ScanFeatureItem {
  const ScanFeatureItem(this.icon, this.label, this.action);
  final IconData icon;
  final String label;
  final VoidCallback action;
}

/// Modal bottom sheet showing all app features when grid icon is tapped.
class ScanFeaturesBottomSheet extends StatelessWidget {
  const ScanFeaturesBottomSheet({super.key, required this.items});

  final List<ScanFeatureItem> items;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDocumentScan,
    required VoidCallback onIdCard,
    required VoidCallback onOcr,
    required VoidCallback onSign,
    required VoidCallback onMerge,
    required VoidCallback onWatermark,
    required VoidCallback onProtect,
    required VoidCallback onCompress,
    required VoidCallback onPdfToImage,
  }) {
    final List<ScanFeatureItem> list = <ScanFeatureItem>[
      ScanFeatureItem(LucideIcons.scanLine, 'Document', onDocumentScan),
      ScanFeatureItem(LucideIcons.creditCard, 'ID Card', onIdCard),
      ScanFeatureItem(LucideIcons.type, 'OCR Text', onOcr),
      ScanFeatureItem(LucideIcons.pencil, 'Signature', onSign),
      ScanFeatureItem(LucideIcons.combine, 'Merge PDF', onMerge),
      ScanFeatureItem(LucideIcons.stamp, 'Watermark', onWatermark),
      ScanFeatureItem(LucideIcons.lock, 'Protect', onProtect),
      ScanFeatureItem(LucideIcons.minimize2, 'Compress', onCompress),
      ScanFeatureItem(LucideIcons.image, 'To Image', onPdfToImage),
    ];

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ScanFeaturesBottomSheet(items: list),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          AppConstants.spaceMd,
          AppConstants.pagePadding,
          AppConstants.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            const Text(
              'All Features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: items.map((ScanFeatureItem item) {
                return SizedBox(
                  width: 72,
                  child: ToolCircleItem(
                    icon: item.icon,
                    label: item.label,
                    onTap: () {
                      Navigator.pop(context);
                      item.action();
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
