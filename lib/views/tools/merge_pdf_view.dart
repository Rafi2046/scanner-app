import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/pdf_tools_provider.dart';
import 'package:scanner_app/services/document_share_helper.dart';
import 'package:scanner_app/views/preview/document_preview_view.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Item in the merge PDF list queue.
class MergePdfItem {
  const MergePdfItem({
    required this.id,
    required this.title,
    required this.path,
    required this.pageCount,
    required this.fileSizeBytes,
    this.thumbnailPath,
    this.isFromDevice = false,
  });

  final String id;
  final String title;
  final String path;
  final int pageCount;
  final int fileSizeBytes;
  final String? thumbnailPath;
  final bool isFromDevice;
}

/// Fully functional iLovePDF-style Merge PDF screen.
class MergePdfView extends ConsumerStatefulWidget {
  const MergePdfView({super.key});

  @override
  ConsumerState<MergePdfView> createState() => _MergePdfViewState();
}

class _MergePdfViewState extends ConsumerState<MergePdfView> {
  final List<MergePdfItem> _items = <MergePdfItem>[];
  late final TextEditingController _nameController;
  bool _isMerging = false;

  @override
  void initState() {
    super.initState();
    final String defaultName =
        'Merged_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
    _nameController = TextEditingController(text: defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _totalPageCount =>
      _items.fold<int>(0, (int sum, MergePdfItem item) => sum + item.pageCount);

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFromDevice() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final List<MergePdfItem> newItems = <MergePdfItem>[];

      for (final PlatformFile file in result.files) {
        final String? path = file.path;
        if (path == null || !File(path).existsSync()) continue;

        int pageCount = 1;
        int size = file.size;
        try {
          final File f = File(path);
          if (size <= 0) size = await f.length();
          final List<int> bytes = await f.readAsBytes();
          final PdfDocument doc = PdfDocument(inputBytes: bytes);
          pageCount = doc.pages.count;
          doc.dispose();
        } catch (_) {}

        final String fileName = file.name.toLowerCase().endsWith('.pdf')
            ? file.name.substring(0, file.name.length - 4)
            : file.name;

        newItems.add(
          MergePdfItem(
            id: 'dev_${DateTime.now().microsecondsSinceEpoch}_${newItems.length}',
            title: fileName,
            path: path,
            pageCount: pageCount,
            fileSizeBytes: size,
            isFromDevice: true,
          ),
        );
      }

      if (newItems.isNotEmpty) {
        setState(() {
          _items.addAll(newItems);
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import PDF: $e')),
      );
    }
  }

  void _showLibraryPickerSheet() {
    final List<ScannedDocument> docs = ref
            .read(libraryNotifierProvider)
            .valueOrNull
            ?.where((ScannedDocument d) =>
                d.hasPdf &&
                d.pdfPath != null &&
                File(d.pdfPath!).existsSync())
            .toList() ??
        const <ScannedDocument>[];

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scanned PDF documents in library.')),
      );
      return;
    }

    final Set<String> selectedDocIds = <String>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Select from App Scans',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                if (selectedDocIds.length == docs.length) {
                                  selectedDocIds.clear();
                                } else {
                                  selectedDocIds.addAll(
                                    docs.map((ScannedDocument d) => d.id),
                                  );
                                }
                              });
                            },
                            child: Text(
                              selectedDocIds.length == docs.length
                                  ? 'Deselect All'
                                  : 'Select All',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppTheme.cardBorder,
                    ),
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: docs.length,
                        itemBuilder: (BuildContext _, int index) {
                          final ScannedDocument doc = docs[index];
                          final bool isSelected =
                              selectedDocIds.contains(doc.id);
                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: AppTheme.primary,
                            title: Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${doc.pageCount} ${doc.pageCount == 1 ? "page" : "pages"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            onChanged: (bool? val) {
                              setSheetState(() {
                                if (val == true) {
                                  selectedDocIds.add(doc.id);
                                } else {
                                  selectedDocIds.remove(doc.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppTheme.cardBorder,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: selectedDocIds.isEmpty
                              ? null
                              : () {
                                  Navigator.of(sheetCtx).pop();
                                  final List<MergePdfItem> newItems =
                                      <MergePdfItem>[];
                                  for (final ScannedDocument doc in docs) {
                                    if (selectedDocIds.contains(doc.id)) {
                                      int size = 0;
                                      try {
                                        size = File(doc.pdfPath!).lengthSync();
                                      } catch (_) {}
                                      newItems.add(
                                        MergePdfItem(
                                          id:
                                              'doc_${doc.id}_${DateTime.now().microsecondsSinceEpoch}',
                                          title: doc.title,
                                          path: doc.pdfPath!,
                                          pageCount: doc.pageCount,
                                          fileSizeBytes: size,
                                          thumbnailPath:
                                              doc.imagePaths.isNotEmpty
                                                  ? doc.imagePaths.first
                                                  : null,
                                          isFromDevice: false,
                                        ),
                                      );
                                    }
                                  }
                                  setState(() {
                                    _items.addAll(newItems);
                                  });
                                  HapticFeedback.lightImpact();
                                },
                          child: Text(
                            selectedDocIds.isEmpty
                                ? 'Select Documents'
                                : 'Add ${selectedDocIds.length} ${selectedDocIds.length == 1 ? "Document" : "Documents"}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSourceSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add PDF Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.folderOpen,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Phone Storage / Files',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Import PDF files saved on your phone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _pickFromDevice();
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Scanned Documents',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Select from documents scanned in this app',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _showLibraryPickerSheet();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeMerge() async {
    if (_items.length < 2) return;
    HapticFeedback.lightImpact();

    setState(() => _isMerging = true);

    try {
      final List<String> paths =
          _items.map((MergePdfItem item) => item.path).toList();
      final String customTitle = _nameController.text.trim();

      final ScannedDocument? createdDoc = await ref
          .read(pdfToolsNotifierProvider.notifier)
          .mergePdfs(paths, customTitle: customTitle);

      if (!mounted) return;
      setState(() => _isMerging = false);

      if (createdDoc != null && createdDoc.hasPdf) {
        _showSuccessSheet(createdDoc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDFs merged successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMerging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to merge PDFs: $e')),
      );
    }
  }

  void _showSuccessSheet(ScannedDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 28,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDFs Merged Successfully!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${doc.title} · ${doc.pageCount} ${doc.pageCount == 1 ? "page" : "pages"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(
                              color: AppTheme.cardBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(LucideIcons.share2, size: 17),
                          label: const Text('Share'),
                          onPressed: () {
                            DocumentShareHelper.sharePdfFile(
                              context,
                              pdfPath: doc.pdfPath!,
                              title: doc.title,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(LucideIcons.fileText, size: 17),
                          label: const Text('View PDF'),
                          onPressed: () {
                            Navigator.of(sheetCtx).pop();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => DocumentPreviewView(
                                  title: doc.title,
                                  pdfPath: doc.pdfPath!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      visible: _isMerging,
      message: 'Merging ${_items.length} PDF documents…',
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Merge PDF',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          actions: <Widget>[
            if (_items.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => _items.clear());
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Add PDF',
              icon: const Icon(
                LucideIcons.plus,
                color: AppTheme.primary,
                size: 22,
              ),
              onPressed: _showAddSourceSheet,
            ),
          ],
        ),
        body: _items.isEmpty ? _buildEmptyState() : _buildQueueView(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              LucideIcons.combine,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Merge PDF Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Combine multiple PDF files in any order.\nImport PDFs from your phone or select from scanned documents.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(LucideIcons.folderOpen, size: 18),
              label: const Text(
                'Import PDFs from Phone',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: _pickFromDevice,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
                backgroundColor: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                LucideIcons.fileText,
                size: 18,
                color: AppTheme.primary,
              ),
              label: const Text(
                'Select from App Scans',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              onPressed: _showLibraryPickerSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueView() {
    return Column(
      children: <Widget>[
        // Status & reorder instruction strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              bottom: BorderSide(color: AppTheme.cardBorder, width: 0.8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.arrowUpDown,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_items.length} files ($_totalPageCount pages) · Drag to reorder',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showAddSourceSheet,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: <Widget>[
                      Icon(LucideIcons.plus, size: 14, color: AppTheme.primary),
                      SizedBox(width: 3),
                      Text(
                        'Add File',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reorderable list of PDFs
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _items.length,
            buildDefaultDragHandles: false,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final MergePdfItem item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
              HapticFeedback.selectionClick();
            },
            itemBuilder: (BuildContext context, int index) {
              final MergePdfItem item = _items[index];
              return _buildItemTile(item, index);
            },
          ),
        ),

        // Bottom docked merge control
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildItemTile(MergePdfItem item, int index) {
    return Container(
      key: ValueKey<String>(item.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.9),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: <Widget>[
            // Drag start listener handle
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  LucideIcons.gripVertical,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Number badge
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Thumbnail or PDF badge
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 46,
                child: (item.thumbnailPath != null &&
                        File(item.thumbnailPath!).existsSync())
                    ? Image.file(File(item.thumbnailPath!), fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFFEF2F2),
                        child: const Center(
                          child: Icon(
                            LucideIcons.fileText,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: item.isFromDevice
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item.isFromDevice ? 'Device' : 'Scan',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: item.isFromDevice
                                ? AppTheme.primary
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.pageCount} ${item.pageCount == 1 ? "page" : "pages"} · ${_formatFileSize(item.fileSizeBytes)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              splashRadius: 18,
              icon: const Icon(
                LucideIcons.x,
                size: 17,
                color: Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final bool canMerge = _items.length >= 2 && !_isMerging;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 0.8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Output document name text field
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Output PDF Name',
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.edit3,
                    size: 17,
                    color: AppTheme.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(LucideIcons.combine, size: 18),
                  label: Text(
                    _items.length < 2
                        ? 'Add at least 2 PDFs to merge'
                        : 'Merge ${_items.length} PDFs ($_totalPageCount pages)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: canMerge ? _executeMerge : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
