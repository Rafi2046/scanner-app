import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// Soft card list for picking library PDFs.
class PdfDocumentSelector extends StatelessWidget {
  const PdfDocumentSelector({
    super.key,
    required this.documents,
    required this.selectedIds,
    required this.onToggle,
    this.multiSelect = true,
  });

  final List<ScannedDocument> documents;
  final Set<String> selectedIds;
  final ValueChanged<ScannedDocument> onToggle;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.pagePadding),
          child: Text(
            'No PDFs yet. Scan or import a file first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
      itemCount: documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spaceSm),
      itemBuilder: (BuildContext context, int index) {
        final ScannedDocument doc = documents[index];
        final bool selected = selectedIds.contains(doc.id);
        return Material(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: InkWell(
            onTap: () => onToggle(doc),
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spaceMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.cardBorder,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    multiSelect
                        ? (selected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded)
                        : (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off),
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          doc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.pageCount} page${doc.pageCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
