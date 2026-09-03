import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/document_scan_provider.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/views/home/widgets/home_drawer.dart';
import 'package:scanner_app/views/home/widgets/empty_library_state.dart';
import 'package:scanner_app/views/home/widgets/home_document_list.dart';
import 'package:scanner_app/views/home/widgets/home_scan_bar.dart';
import 'package:scanner_app/views/id_card_scan/id_card_scan_view.dart';
import 'package:scanner_app/views/tools/tools_hub_view.dart';
import 'package:scanner_app/views/widgets/error_banner.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';

/// Library dashboard — Recents + scan entry points (Milestone 1).
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenAsyncError(ref, libraryNotifierProvider, context);
    listenAsyncError(ref, documentScanNotifierProvider, context);

    final AsyncValue<List<ScannedDocument>> library =
        ref.watch(libraryNotifierProvider);
    final bool scanning = ref.watch(documentScanNotifierProvider).isLoading;

    return LoadingOverlay(
      visible: scanning,
      message: 'Scanning…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scanner'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Tools',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ToolsHubView(),
                  ),
                );
              },
              icon: const Icon(Icons.grid_view_outlined),
            ),
          ],
        ),
        drawer: const HomeDrawer(),
        body: SafeArea(
          child: library.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => ErrorBanner.fromError(
              error: error,
              onRetry: () =>
                  ref.read(libraryNotifierProvider.notifier).loadLibrary(),
            ),
            data: (List<ScannedDocument> documents) {
              if (documents.isEmpty) {
                return const EmptyLibraryState();
              }
              return HomeDocumentList(
                documents: documents,
                onDelete: (String id) => ref
                    .read(libraryNotifierProvider.notifier)
                    .deleteDocument(id),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: scanning
              ? null
              : () => ref
                  .read(documentScanNotifierProvider.notifier)
                  .startDocumentScan(),
          tooltip: 'Scan document',
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: HomeScanBar(
          enabled: !scanning,
          onScanDocument: () => ref
              .read(documentScanNotifierProvider.notifier)
              .startDocumentScan(),
          onScanIdCard: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const IdCardScanView(),
              ),
            );
          },
        ),
      ),
    );
  }
}
