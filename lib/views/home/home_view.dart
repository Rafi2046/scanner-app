import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/views/document_details/document_details_view.dart';
import 'package:scanner_app/views/document_scan/custom_scan_view.dart';
import 'package:scanner_app/views/home/tabs/files_tab_view.dart';
import 'package:scanner_app/views/home/tabs/home_tab_view.dart';
import 'package:scanner_app/views/home/tabs/me_tab_view.dart';
import 'package:scanner_app/views/home/tabs/tools_tab_view.dart';
import 'package:scanner_app/views/home/widgets/center_camera_fab.dart';
import 'package:scanner_app/views/home/widgets/main_bottom_bar.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

/// 4-tab shell with center camera FAB.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    listenAsyncError(ref, libraryNotifierProvider, context);

    final AsyncValue<List<ScannedDocument>> library =
        ref.watch(libraryNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedTab,
          children: <Widget>[
            HomeTabView(
              library: library,
              scanning: false,
              searchQuery: _searchQuery,
              searchController: _searchController,
              onSearchChanged: (String q) =>
                  setState(() => _searchQuery = q.trim().toLowerCase()),
              onOpenSettings: () => setState(() => _selectedTab = 3),
              onScanDocument: () =>
                  _push(const CustomScanView(mode: CustomScanMode.document)),
              onIdCard: () =>
                  _push(const CustomScanView(mode: CustomScanMode.idCard)),
              onOcr: () => _push(const OcrResultView()),
              onMergePdf: () => _push(const MergePdfView()),
              onWatermark: () => _push(const WatermarkView()),
              onSign: () => _push(const SignatureView()),
              onProtect: () => _push(const PasswordLockView()),
              onAllTools: () => setState(() => _selectedTab = 2),
              onDelete: (String id) =>
                  ref.read(libraryNotifierProvider.notifier).deleteDocument(id),
              onTapDocument: (ScannedDocument doc) => _push(
                DocumentDetailsView(
                  documentId: doc.id,
                  initialDocument: doc,
                ),
              ),
              onRefresh: () =>
                  ref.read(libraryNotifierProvider.notifier).loadLibrary(),
            ),
            FilesTabView(
              library: library,
              onImport: () =>
                  ref.read(pdfToolsNotifierProvider.notifier).importFiles(),
              onIdScan: () =>
                  _push(const CustomScanView(mode: CustomScanMode.idCard)),
              onMerge: () => _push(const MergePdfView()),
              onDelete: (String id) =>
                  ref.read(libraryNotifierProvider.notifier).deleteDocument(id),
              onTapDocument: (ScannedDocument doc) => _push(
                DocumentDetailsView(
                  documentId: doc.id,
                  initialDocument: doc,
                ),
              ),
              onRefresh: () =>
                  ref.read(libraryNotifierProvider.notifier).loadLibrary(),
            ),
            ToolsTabView(
              onSmartScan: () =>
                  _push(const CustomScanView(mode: CustomScanMode.document)),
              onIdCard: () =>
                  _push(const CustomScanView(mode: CustomScanMode.idCard)),
              onOcr: () => _push(const OcrResultView()),
              onMergePdf: () => _push(const MergePdfView()),
              onWatermark: () => _push(const WatermarkView()),
              onSign: () => _push(const SignatureView()),
              onPasswordLock: () => _push(const PasswordLockView()),
              onCompress: () => _push(const CompressView()),
              onPdfToImage: () => _push(const PdfToImageView()),
              onImport: () =>
                  ref.read(pdfToolsNotifierProvider.notifier).importFiles(),
            ),
            const MeTabView(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: CenterCameraFab(
        enabled: true,
        onPressed: () =>
            _push(const CustomScanView(mode: CustomScanMode.document)),
      ),
      bottomNavigationBar: MainBottomBar(
        selectedIndex: _selectedTab,
        onTabSelected: (int index) => setState(() => _selectedTab = index),
      ),
    );
  }
}
