import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/home_header.dart';
import 'package:scanner_app/views/home/widgets/home_quick_tools.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';
import 'package:scanner_app/views/home/widgets/recent_doc_action_strip.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';

/// Tab 0: Home Dashboard view.
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
  final VoidCallback onAllTools;
  final ValueChanged<String> onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryMint,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  HomeHeader(
                    searchController: searchController,
                    onSearchChanged: onSearchChanged,
                    onOpenSettings: onOpenSettings,
                  ),
                  const SizedBox(height: 16),
                  HomeQuickTools(
                    onSmartScan: onScanDocument,
                    onIdCard: onIdCard,
                    onOcr: onOcr,
                    onMergePdf: onMergePdf,
                    onAllTools: onAllTools,
                  ),
                  const SizedBox(height: 22),
                  // Recent Documents Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Recent Documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      library.maybeWhen(
                        data: (List<ScannedDocument> docs) => docs.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.cardBorder),
                                ),
                                child: Text(
                                  '${docs.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryMint,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: library.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryMint,
                    ),
                  ),
                ),
                error: (Object error, StackTrace stackTrace) =>
                    ErrorBanner.fromError(
                  error: error,
                  onRetry: onRefresh,
                ),
                data: (List<ScannedDocument> documents) {
                  final List<ScannedDocument> filteredDocs = searchQuery.isEmpty
                      ? documents
                      : documents
                          .where((d) => d.title.toLowerCase().contains(searchQuery))
                          .toList();

                  if (documents.isEmpty) {
                    return ModernEmptyState(onScan: onScanDocument);
                  }
                  if (filteredDocs.isEmpty) {
                    return ModernEmptyState(
                      title: 'No matching documents',
                      subtitle: 'No documents match "$searchQuery".',
                    );
                  }

                  return Column(
                    children: <Widget>[
                      RecentDocActionStrip(
                        onShare: () {},
                        onOcr: onOcr,
                        onView: () {},
                      ),
                      HomeDocumentList(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        documents: filteredDocs,
                        onDelete: onDelete,
                      ),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
