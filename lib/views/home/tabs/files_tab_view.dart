import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/files_filter_chips.dart';
import 'package:scanner_app/views/home/widgets/files_storage_meter.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';

/// Tab 1: document library.
class FilesTabView extends StatefulWidget {
  const FilesTabView({
    super.key,
    required this.library,
    required this.onImport,
    required this.onIdScan,
    required this.onMerge,
    required this.onDelete,
    this.onTapDocument,
    required this.onRefresh,
  });

  final AsyncValue<List<ScannedDocument>> library;
  final VoidCallback onImport;
  final VoidCallback onIdScan;
  final VoidCallback onMerge;
  final ValueChanged<String> onDelete;
  final ValueChanged<ScannedDocument>? onTapDocument;
  final Future<void> Function() onRefresh;

  @override
  State<FilesTabView> createState() => _FilesTabViewState();
}

class _FilesTabViewState extends State<FilesTabView> {
  String _selectedCategory = 'All';

  List<ScannedDocument> _applyFilter(List<ScannedDocument> docs) {
    if (_selectedCategory == 'All') {
      return docs;
    }
    return docs.where((ScannedDocument doc) {
      return switch (_selectedCategory) {
        'Scans' => doc.kind == DocumentKind.scan,
        'ID Cards' => doc.kind == DocumentKind.idCard,
        'Imported' => doc.kind == DocumentKind.imported,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          AppConstants.spaceLg,
          AppConstants.pagePadding,
          AppConstants.bottomNavClearance,
        ),
        children: <Widget>[
          const Text(
            'Files',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          widget.library.maybeWhen(
            data: (List<ScannedDocument> docs) =>
                FilesStorageMeter(documentCount: docs.length),
            orElse: () => const FilesStorageMeter(documentCount: 0),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          FilesFilterChips(
            selectedFilter: _selectedCategory,
            onFilterChanged: (String cat) =>
                setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          widget.library.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object err, StackTrace _) => ErrorBanner.fromError(
              error: err,
              onRetry: widget.onRefresh,
            ),
            data: (List<ScannedDocument> docs) {
              final List<ScannedDocument> filtered = _applyFilter(docs);
              if (filtered.isEmpty) {
                return ModernEmptyState(
                  title: 'No $_selectedCategory files',
                  subtitle: 'Try another filter or import a document.',
                );
              }
              return HomeDocumentList(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                documents: filtered,
                onTap: widget.onTapDocument,
                onDelete: widget.onDelete,
              );
            },
          ),
        ],
      ),
    );
  }
}
