import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_filter_chip_row.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_button.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

class EnhanceStepView extends ConsumerWidget {
  const EnhanceStepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        ScanFilterChipRow(
          selected: scan.selectedFilter,
          onSelected: (filter) =>
              ref.read(customScanNotifierProvider.notifier).selectFilter(filter),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        ScanBottomBar(
          child: PrimaryButton(
            label: 'Next',
            onPressed: scan.busy
                ? null
                : () => ref
                    .read(customScanNotifierProvider.notifier)
                    .confirmEnhance(),
          ),
        ),
      ],
    );
  }
}
