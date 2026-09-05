import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/services/document_share_helper.dart';

/// Clean, premium card row for a document with 3-dot options sheet.
class ModernDocumentCard extends StatelessWidget {
  const ModernDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
    this.onRename,
    this.onShare,
  });

  final ScannedDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onRename;
  final VoidCallback? onShare;

  void _showMoreOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _DocumentOptionsSheet(
          document: document,
          onTap: onTap,
          onDelete: onDelete,
          onRename: onRename,
        );
      },
    );
  }

  static String _formatDate(DateTime dt) {
    final DateTime now = DateTime.now();
    final bool isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    final bool isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    final String timeStr = DateFormat.jm().format(dt);

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imagePath =
        document.imagePaths.isEmpty ? null : document.imagePaths.first;
    final bool hasImage =
        imagePath != null && File(imagePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F3F5), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppTheme.primary.withValues(alpha: 0.05),
          highlightColor: AppTheme.primary.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                _Thumb(
                  hasImage: hasImage,
                  pageCount: document.pageCount,
                  path: imagePath,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5.5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PDF',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${document.pageCount} ${document.pageCount == 1 ? "page" : "pages"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _formatDate(document.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showMoreOptions(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.moreVertical,
                          size: 15,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.hasImage,
    required this.pageCount,
    this.path,
  });

  final bool hasImage;
  final int pageCount;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.2),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (hasImage && path != null)
              Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppTheme.primarySoft,
                  child: Center(
                    child: Icon(
                      LucideIcons.fileText,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              )
            else
              const ColoredBox(
                color: AppTheme.primarySoft,
                child: Center(
                  child: Icon(
                    LucideIcons.fileText,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            if (pageCount > 1)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pageCount}P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sleek, minimalist Lucide-powered bottom sheet for document options.
class _DocumentOptionsSheet extends ConsumerWidget {
  const _DocumentOptionsSheet({
    required this.document,
    this.onTap,
    this.onDelete,
    this.onRename,
  });

  final ScannedDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onRename;

  static final DateFormat _dateFormat = DateFormat.yMMMd().add_jm();

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Document?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${document.title}"? This cannot be undone.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (onDelete != null) {
                  onDelete!();
                } else {
                  await ref
                      .read(libraryNotifierProvider.notifier)
                      .deleteDocument(document.id);
                }
                if (context.mounted) {
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

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller =
        TextEditingController(text: document.title);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Rename Document',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter document name',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
              ),
              onPressed: () async {
                final String newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != document.title) {
                  if (onRename != null) {
                    onRename!(newTitle);
                  } else {
                    await ref
                        .read(libraryNotifierProvider.notifier)
                        .renameDocument(document.id, newTitle);
                  }
                }
                if (ctx.mounted) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? imagePath =
        document.imagePaths.isEmpty ? null : document.imagePaths.first;
    final bool hasImage =
        imagePath != null && File(imagePath).existsSync();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Grab handle pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Preview
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 12, 12),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: hasImage
                          ? Image.file(File(imagePath), fit: BoxFit.cover)
                          : const ColoredBox(
                              color: AppTheme.primarySoft,
                              child: Icon(
                                LucideIcons.fileText,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${document.pageCount} ${document.pageCount == 1 ? "page" : "pages"} · ${_dateFormat.format(document.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 18,
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.8, color: AppTheme.cardBorder),

            // Actions - Clean, minimalist, monochrome Lucide icons
            const SizedBox(height: 4),
            _ActionRow(
              icon: LucideIcons.share2,
              title: 'Share Document',
              onTap: () {
                Navigator.of(context).pop();
                DocumentShareHelper.shareDocument(context, document);
              },
            ),
            _ActionRow(
              icon: LucideIcons.edit3,
              title: 'Rename',
              onTap: () {
                Navigator.of(context).pop();
                _showRenameDialog(context, ref);
              },
            ),
            if (onTap != null)
              _ActionRow(
                icon: LucideIcons.fileText,
                title: 'Open Details',
                onTap: () {
                  Navigator.of(context).pop();
                  onTap!();
                },
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(
                height: 12,
                thickness: 0.8,
                color: AppTheme.cardBorder,
              ),
            ),

            _ActionRow(
              icon: LucideIcons.trash2,
              title: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(context, ref);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color itemColor =
        isDestructive ? AppTheme.danger : const Color(0xFF1F2937);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color:
                    isDestructive ? AppTheme.danger : const Color(0xFF4B5563),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: itemColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
