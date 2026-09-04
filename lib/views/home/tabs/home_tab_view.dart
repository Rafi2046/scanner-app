import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/home_header.dart';
import 'package:scanner_app/views/home/widgets/home_quick_tools.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';
import 'package:scanner_app/views/home/widgets/recent_files_header.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';

/// Tab 0: clean Home dashboard.
class HomeTabView extends StatelessWidget {
  const HomeTabView({
    super.key,
    required this.library,
    required this.scanning,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenSettings,
    required this.onScanDocument,
    required this.onIdCard,
    required this.onOcr,
    required this.onMergePdf,
    required this.onWatermark,
    required this.onSign,
    required this.onProtect,
    required this.onAllTools,
    required this.onDelete,
    required this.onRefresh,
  });

  final AsyncValue<List<ScannedDocument>> library;
  final bool scanning;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onScanDocument;
  final VoidCallback onIdCard;
  final VoidCallback onOcr;
  final VoidCallback onMergePdf;
  final VoidCallback onWatermark;
  final VoidCallback onSign;
  final VoidCallback onProtect;
  final VoidCallback onAllTools;
  final ValueChanged<String> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.pagePadding,
              AppConstants.spaceMd,
              AppConstants.pagePadding,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                HomeHeader(
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  onOpenSettings: onOpenSettings,
                ),
                const SizedBox(height: AppConstants.spaceLg),
                HomeQuickTools(
                  onSmartScan: onScanDocument,
                  onIdCard: onIdCard,
                  onOcr: onOcr,
                  onMergePdf: onMergePdf,
                  onWatermark: onWatermark,
                  onSign: onSign,
                  onProtect: onProtect,
                  onAllTools: onAllTools,
                ),
                const SizedBox(height: AppConstants.spaceXl),
                RecentFilesHeader(
                  count: library.valueOrNull?.length,
                  onSeeAll: onAllTools,
                ),
                const SizedBox(height: AppConstants.spaceMd),
                _LibraryBody(
                  library: library,
                  searchQuery: searchQuery,
                  onScanDocument: onScanDocument,
                  onDelete: onDelete,
                  onRefresh: onRefresh,
                ),
                const SizedBox(height: AppConstants.bottomNavClearance),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.library,
    required this.searchQuery,
    required this.onScanDocument,
    required this.onDelete,
    required this.onRefresh,
  });

  final AsyncValue<List<ScannedDocument>> library;
  final String searchQuery;
  final VoidCallback onScanDocument;
  final ValueChanged<String> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return library.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => ErrorBanner.fromError(
        error: error,
        onRetry: onRefresh,
      ),
      data: (List<ScannedDocument> documents) {
        final List<ScannedDocument> filtered = searchQuery.isEmpty
            ? documents
            : documents
                .where(
                  (ScannedDocument d) =>
                      d.title.toLowerCase().contains(searchQuery),
                )
                .toList();

        if (documents.isEmpty) {
          return ModernEmptyState(onScan: onScanDocument);
        }
        if (filtered.isEmpty) {
          return ModernEmptyState(
            title: 'No matching files',
            subtitle: 'Nothing matched "$searchQuery".',
          );
        }

        return HomeDocumentList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          documents: filtered,
          onDelete: onDelete,
        );
      },
    );
  }
}
