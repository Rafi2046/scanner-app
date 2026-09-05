import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_button.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

class PagesStepView extends ConsumerWidget {
  const PagesStepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(customScanNotifierProvider);
    final bool isId = scan.mode == CustomScanMode.idCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.spaceMd,
            AppConstants.pagePadding,
            AppConstants.spaceSm,
          ),
          child: Text(
            isId ? 'ID Card pages' : 'Scanned pages (${scan.pages.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: scan.pages.isEmpty
              ? const Center(
                  child: Text(
                    'No pages yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  itemCount: scan.pages.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppConstants.spaceMd),
                  itemBuilder: (BuildContext context, int index) {
                    final ScanPageDraft page = scan.pages[index];
                    final String label = page.idSide == null
                        ? 'Page ${index + 1}'
                        : (page.idSide == IdScanSide.front ? 'Front' : 'Back');
                    return _PageTile(
                      label: label,
                      path: page.imagePath,
                      onDelete: () => ref
                          .read(customScanNotifierProvider.notifier)
                          .removePage(index),
                    );
                  },
                ),
        ),
        ScanBottomBar(
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scan.busy
                      ? null
                      : () => ref
                          .read(customScanNotifierProvider.notifier)
                          .goToCapture(),
                  icon: const Icon(LucideIcons.plus),
                  label: Text(isId ? 'Capture side' : 'Add page'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusPill),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: PrimaryButton(
                  label: 'Save PDF',
                  onPressed: (!scan.canSave || scan.busy)
                      ? null
                      : () => ref
                          .read(customScanNotifierProvider.notifier)
                          .save(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.label,
    required this.path,
    required this.onDelete,
  });

  final String label;
  final String path;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: const Color(0xFF2A2F3A)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spaceMd),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          child: Image.file(
            File(path),
            width: AppConstants.thumbWidth,
            height: AppConstants.thumbHeight,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
        ),
      ),
    );
  }
}
