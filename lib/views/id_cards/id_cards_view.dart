import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/views/document_details/document_details_view.dart';
import 'package:scanner_app/views/document_scan/custom_scan_view.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';

/// Browse saved ID cards; scan a new one from the app bar / empty CTA.
class IdCardsView extends ConsumerWidget {
  const IdCardsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ScannedDocument>> library =
        ref.watch(libraryNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: const Text(
          'ID Cards',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Scan ID Card',
            onPressed: () => _openScan(context),
            icon: const Icon(LucideIcons.plus, color: AppTheme.primary),
          ),
        ],
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace _) => Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: ErrorBanner.fromError(
            error: err,
            onRetry: () =>
                ref.read(libraryNotifierProvider.notifier).loadLibrary(),
          ),
        ),
        data: (List<ScannedDocument> docs) {
          final List<ScannedDocument> cards = docs
              .where((ScannedDocument d) => d.kind == DocumentKind.idCard)
              .toList();

          if (cards.isEmpty) {
            return Center(
              child: ModernEmptyState(
                title: 'No ID cards yet',
                subtitle: 'Scan the front and back to save an ID card PDF.',
                actionLabel: 'Scan ID Card',
                onScan: () => _openScan(context),
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () =>
                ref.read(libraryNotifierProvider.notifier).loadLibrary(),
            child: HomeDocumentList(
              documents: cards,
              padding: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding,
                AppConstants.spaceSm,
                AppConstants.pagePadding,
                AppConstants.spaceXxl,
              ),
              onDelete: (String id) =>
                  ref.read(libraryNotifierProvider.notifier).deleteDocument(id),
              onTap: (ScannedDocument doc) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DocumentDetailsView(
                      documentId: doc.id,
                      initialDocument: doc,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScan(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.creditCard, size: 18),
        label: const Text(
          'Scan ID Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomScanView(mode: CustomScanMode.idCard),
      ),
    );
  }
}
