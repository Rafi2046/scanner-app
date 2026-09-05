import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/document_scan_beam.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_filter_chip_row.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_button.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// Document enhancement step with animated laser scanner beam effect.
class EnhanceStepView extends ConsumerStatefulWidget {
  const EnhanceStepView({super.key});

  @override
  ConsumerState<EnhanceStepView> createState() => _EnhanceStepViewState();
}

class _EnhanceStepViewState extends ConsumerState<EnhanceStepView> {
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(customScanNotifierProvider);
    final String? path = scan.warpedPath;

    if (path == null) {
      return const Center(
        child: Text(
          'No cropped image',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    const Color mint = Color(0xFF00D2A0);

    return Column(
      children: <Widget>[
        // Status indicator pill
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _isScanning
                  ? mint.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              border: Border.all(
                color: _isScanning
                    ? mint.withValues(alpha: 0.6)
                    : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  _isScanning ? Icons.document_scanner : Icons.check_circle,
                  color: _isScanning ? mint : mint,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isScanning ? 'Scanning document…' : 'Document ready',
                  style: TextStyle(
                    color: _isScanning ? mint : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: DocumentScanBeam(
                autoStart: true,
                trigger: scan.selectedFilter,
                onCompleted: () {
                  if (mounted) setState(() => _isScanning = false);
                },
                child: Image.file(File(path), key: ValueKey<String>(path), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spaceSm),
        ScanFilterChipRow(
          selected: scan.selectedFilter,
          onSelected: (filter) {
            if (!mounted) return;
            setState(() => _isScanning = true);
            ref.read(customScanNotifierProvider.notifier).selectFilter(filter);
          },
        ),
        const SizedBox(height: AppConstants.spaceMd),
        ScanBottomBar(
          child: PrimaryButton(
            label: 'Next',
            onPressed: scan.busy
                ? null
                : () {
                    if (!mounted) return;
                    ref
                        .read(customScanNotifierProvider.notifier)
                        .confirmEnhance();
                  },
          ),
        ),
      ],
    );
  }
}
