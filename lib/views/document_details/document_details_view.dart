import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/preview/document_preview_view.dart';
import 'package:share_plus/share_plus.dart';

/// Clean, premium Document Details View inspired by CamScanner multi-page layout.
class DocumentDetailsView extends ConsumerStatefulWidget {
  const DocumentDetailsView({
    super.key,
    required this.documentId,
    this.initialDocument,
  });

  final String documentId;
  final ScannedDocument? initialDocument;

  @override
  ConsumerState<DocumentDetailsView> createState() => _DocumentDetailsViewState();
}

class _DocumentDetailsViewState extends ConsumerState<DocumentDetailsView> {
  static final DateFormat _dateFormat = DateFormat.yMMMd().add_jm();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  ScannedDocument? _resolveDoc(List<ScannedDocument>? docs) {
    if (docs != null) {
      for (final ScannedDocument d in docs) {
        if (d.id == widget.documentId) {
          return d;
        }
      }
    }
    return widget.initialDocument;
  }

  void _showRenameDialog(ScannedDocument doc) {
    final TextEditingController controller =
        TextEditingController(text: doc.title);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          title: const Row(
            children: <Widget>[
              Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Rename Document',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter document name',
              filled: true,
              fillColor: AppTheme.scaffoldBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
              ),
              onPressed: () async {
                final String newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != doc.title) {
                  Navigator.of(ctx).pop();
                  await ref
                      .read(libraryNotifierProvider.notifier)
                      .renameDocument(doc.id, newTitle);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document renamed successfully.'),
                      ),
                    );
                  }
                } else {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(ScannedDocument doc) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          title: const Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded,
                  color: AppTheme.danger, size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Document?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${doc.title}"? This cannot be undone.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref
                    .read(libraryNotifierProvider.notifier)
                    .deleteDocument(doc.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted.')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareDocument(ScannedDocument doc) async {
    HapticFeedback.lightImpact();
    try {
      if (doc.hasPdf && File(doc.pdfPath!).existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(doc.pdfPath!)],
            text: doc.title,
          ),
        );
      } else if (doc.imagePaths.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: doc.imagePaths.map((String p) => XFile(p)).toList(),
            text: doc.title,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No files available to share.')),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please restart app to activate sharing module.'),
        ),
      );
    }
  }

  void _showAddPageSheet(ScannedDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
              vertical: AppConstants.spaceMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                const Text(
                  'Add Page to Document',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceLg),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Camera Scanner',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text('Capture new page with camera'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 95,
                    );
                    if (photo != null) {
                      _appendPages(doc, <String>[photo.path]);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.accentBlue,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Import from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: const Text('Select one or more photos'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final List<XFile> photos = await _picker.pickMultiImage(
                      imageQuality: 95,
                    );
                    if (photos.isNotEmpty) {
                      _appendPages(
                        doc,
                        photos.map((XFile x) => x.path).toList(),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppConstants.spaceSm),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _appendPages(
    ScannedDocument doc,
    List<String> tempPaths,
  ) async {
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(libraryNotifierProvider.notifier)
          .addPagesToDocument(doc.id, tempPaths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tempPaths.length} ${tempPaths.length == 1 ? "page" : "pages"} added successfully.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _openFullScreenViewer(ScannedDocument doc, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenViewer(
          document: doc,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ScannedDocument>? docs =
        ref.watch(libraryNotifierProvider).valueOrNull;
    final ScannedDocument? doc = _resolveDoc(docs);

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Document not found.'),
        ),
      );
    }

    final int pageCount = doc.imagePaths.length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _showRenameDialog(doc),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          if (doc.hasPdf)
            IconButton(
              tooltip: 'PDF Preview',
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppTheme.textPrimary,
                size: 20,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DocumentPreviewView(
                      title: doc.title,
                      pdfPath: doc.pdfPath!,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            onPressed: () => _shareDocument(doc),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            onSelected: (String val) {
              switch (val) {
                case 'rename':
                  _showRenameDialog(doc);
                  break;
                case 'pdf':
                  if (doc.hasPdf) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DocumentPreviewView(
                          title: doc.title,
                          pdfPath: doc.pdfPath!,
                        ),
                      ),
                    );
                  }
                  break;
                case 'share':
                  _shareDocument(doc);
                  break;
                case 'delete':
                  _showDeleteConfirmation(doc);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'rename',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textPrimary),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              if (doc.hasPdf)
                const PopupMenuItem<String>(
                  value: 'pdf',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.picture_as_pdf_outlined,
                          size: 18, color: AppTheme.textPrimary),
                      SizedBox(width: 12),
                      Text('View PDF'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.ios_share_rounded,
                        size: 18, color: AppTheme.textPrimary),
                    SizedBox(width: 12),
                    Text('Share Document'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.danger),
                    SizedBox(width: 12),
                    Text(
                      'Delete Document',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // Document metadata badge header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    AppConstants.spaceSm,
                    AppConstants.pagePadding,
                    AppConstants.spaceSm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: Text(
                          _kindLabel(doc.kind),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${doc.pageCount} ${doc.pageCount == 1 ? "page" : "pages"} · ${_dateFormat.format(doc.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Multi-page grid + Add Page Card
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.pagePadding,
                  vertical: AppConstants.spaceSm,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index < pageCount) {
                        return _buildPageCard(
                          doc: doc,
                          index: index,
                          imagePath: doc.imagePaths[index],
                        );
                      } else {
                        return _buildAddPageCard(doc);
                      }
                    },
                    childCount: pageCount + 1,
                  ),
                ),
              ),

              // Clearance for bottom action bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  color: AppTheme.surfaceColor,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Updating document...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(doc),
          ),
        ],
      ),
    );
  }

  String _kindLabel(DocumentKind kind) {
    return switch (kind) {
      DocumentKind.scan => 'Document Scan',
      DocumentKind.idCard => 'ID Card',
      DocumentKind.imported => 'Imported',
      DocumentKind.toolOutput => 'Exported',
    };
  }

  /// Single page thumbnail card with page number label beneath
  Widget _buildPageCard({
    required ScannedDocument doc,
    required int index,
    required String imagePath,
  }) {
    final File file = File(imagePath);
    final bool exists = file.existsSync();

    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg - 1),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFullScreenViewer(doc, index),
                  child: exists
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.textSecondary,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Add Page card (+ icon) with dashed/dot-dot border
  Widget _buildAddPageCard(ScannedDocument doc) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primarySoft.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            ),
            child: CustomPaint(
              foregroundPainter: const _DashedBorderPainter(
                color: Color(0xCC3B6FF5),
                strokeWidth: 1.8,
                dashLength: 6.0,
                gapLength: 4.5,
                borderRadius: AppConstants.radiusLg,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  onTap: () => _showAddPageSheet(doc),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            color: AppTheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Add Page',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Scan or Import',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  /// Bottom toolbar matching CamScanner tools
  Widget _buildBottomBar(ScannedDocument doc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 0.8),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _ToolbarItem(
              icon: Icons.add_a_photo_outlined,
              label: 'Add',
              onTap: () => _showAddPageSheet(doc),
            ),
            _ToolbarItem(
              icon: Icons.tune_rounded,
              label: 'Edit',
              onTap: () {
                if (doc.imagePaths.isNotEmpty) {
                  _openFullScreenViewer(doc, 0);
                }
              },
            ),
            _ToolbarItem(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: () => _shareDocument(doc),
            ),
            _ToolbarItem(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onTap: () {
                if (doc.hasPdf) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DocumentPreviewView(
                        title: doc.title,
                        pdfPath: doc.pdfPath!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No PDF available.')),
                  );
                }
              },
            ),
            _ToolbarItem(
              icon: Icons.document_scanner_outlined,
              label: 'OCR',
              onTap: () {
                final String? first = doc.imagePaths.firstOrNull;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OcrResultView(initialImagePath: first),
                  ),
                );
              },
            ),
            _ToolbarItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              isDanger: true,
              onTap: () => _showDeleteConfirmation(doc),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final Color color = isDanger ? AppTheme.danger : AppTheme.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen interactive viewer with zoom and page swipe
class _FullScreenViewer extends ConsumerStatefulWidget {
  const _FullScreenViewer({
    required this.document,
    required this.initialIndex,
  });

  final ScannedDocument document;
  final int initialIndex;

  @override
  ConsumerState<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends ConsumerState<_FullScreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDeletePage(ScannedDocument doc) {
    if (doc.imagePaths.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only page in document.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          title: const Text(
            'Delete Page?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text('Delete Page ${_currentIndex + 1} from this document?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final int deletingIdx = _currentIndex;
                if (_currentIndex > 0) {
                  _currentIndex--;
                }
                await ref
                    .read(libraryNotifierProvider.notifier)
                    .deletePage(doc.id, deletingIdx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Page deleted.')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCurrentPage(ScannedDocument doc) async {
    try {
      if (doc.imagePaths.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(doc.imagePaths[_currentIndex])],
            text: '${doc.title} - Page ${_currentIndex + 1}',
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please restart app to activate sharing module.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ScannedDocument>? docs =
        ref.watch(libraryNotifierProvider).valueOrNull;
    final ScannedDocument doc = docs?.firstWhere(
          (ScannedDocument d) => d.id == widget.document.id,
          orElse: () => widget.document,
        ) ??
        widget.document;

    final int totalPages = doc.imagePaths.length;
    if (_currentIndex >= totalPages && totalPages > 0) {
      _currentIndex = totalPages - 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161920),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Page ${_currentIndex + 1} of $totalPages',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Share Page',
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => _shareCurrentPage(doc),
          ),
          if (totalPages > 1)
            IconButton(
              tooltip: 'Delete Page',
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.redAccent),
              onPressed: () => _confirmDeletePage(doc),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalPages,
        onPageChanged: (int index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (BuildContext context, int index) {
          final String path = doc.imagePaths[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: const Color(0xFF161920),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () {
                  if (doc.imagePaths.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OcrResultView(
                          initialImagePath: doc.imagePaths[_currentIndex],
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Extract Text'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () {
                  if (doc.hasPdf) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DocumentPreviewView(
                          title: doc.title,
                          pdfPath: doc.pdfPath!,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('View PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double inset = strokeWidth / 2.0;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.borderRadius != borderRadius;
}

