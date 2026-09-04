import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/files_filter_chips.dart';
import 'package:scanner_app/views/home/widgets/files_storage_meter.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';

/// Tab 1: Files / Library management view.
class FilesTabView extends StatefulWidget {
  const FilesTabView({
    super.key,
    required this.library,
    required this.onImport,
    required this.onIdScan,
    required this.onMerge,
    required this.onDelete,
    required this.onRefresh,
  });

  final AsyncValue<List<ScannedDocument>> library;
  final VoidCallback onImport;
  final VoidCallback onIdScan;
  final VoidCallback onMerge;
  final ValueChanged<String> onDelete;
  final Future<void> Function() onRefresh;

  @override
  State<FilesTabView> createState() => _FilesTabViewState();
}

class _FilesTabViewState extends State<FilesTabView> {
  String _selectedCategory = 'All';

  List<ScannedDocument> _applyFilter(List<ScannedDocument> docs) {
    if (_selectedCategory == 'All') return docs;
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
      color: AppTheme.primaryMint,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: <Widget>[
          const Text(
            'Document Library',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          widget.library.maybeWhen(
            data: (List<ScannedDocument> docs) =>
                FilesStorageMeter(documentCount: docs.length),
            orElse: () => const FilesStorageMeter(documentCount: 0),
          ),
          const SizedBox(height: 16),
          // Fast Action Buttons Row
          Row(
            children: <Widget>[
              _ActionButton(
                icon: Icons.file_upload_outlined,
                label: 'Import',
                onTap: widget.onImport,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.badge_outlined,
                label: 'ID Card',
                onTap: widget.onIdScan,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.call_merge_rounded,
                label: 'Merge',
                onTap: widget.onMerge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips
          FilesFilterChips(
            selectedFilter: _selectedCategory,
            onFilterChanged: (String cat) =>
                setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 14),
          // Document List
          widget.library.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppTheme.primaryMint),
              ),
            ),
            error: (Object err, StackTrace st) => ErrorBanner.fromError(
              error: err,
              onRetry: widget.onRefresh,
            ),
            data: (List<ScannedDocument> docs) {
              final List<ScannedDocument> filtered = _applyFilter(docs);
              if (filtered.isEmpty) {
                return ModernEmptyState(
                  title: 'No $_selectedCategory documents',
                  subtitle: 'No files match this filter.',
                );
              }
              return HomeDocumentList(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                documents: filtered,
                onDelete: widget.onDelete,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 16, color: AppTheme.primaryMint),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
