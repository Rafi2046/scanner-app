import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/document_badges.dart';

/// Clean, modern card for a scanned document in the library.
class ModernDocumentCard extends StatelessWidget {
  const ModernDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
  });

  final ScannedDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  static final DateFormat _dateFormat = DateFormat.yMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final String? firstImage =
        document.imagePaths.isNotEmpty ? document.imagePaths.first : null;
    final bool hasValidImage =
        firstImage != null && File(firstImage).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                // Thumbnail
                Stack(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasValidImage
                          ? Image.file(File(firstImage), fit: BoxFit.cover)
                          : const Center(
                              child: Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppTheme.primaryMint,
                                size: 26,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${document.pageCount}p',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Title and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        document.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(document.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          DocumentKindBadge(kind: document.kind),
                          if (document.hasPdf) ...<Widget>[
                            const SizedBox(width: 6),
                            const PdfFormatBadge(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete menu
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete document',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
