import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// Soft card row for a recent file (share + more actions).
class ModernDocumentCard extends StatelessWidget {
  const ModernDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
    this.onShare,
  });

  final ScannedDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  static final DateFormat _dateFormat = DateFormat.yMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final String? imagePath =
        document.imagePaths.isEmpty ? null : document.imagePaths.first;
    final bool hasImage =
        imagePath != null && File(imagePath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            child: Row(
              children: <Widget>[
                _Thumb(hasImage: hasImage, path: imagePath),
                const SizedBox(width: AppConstants.spaceMd),
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
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceXs),
                      Text(
                        _dateFormat.format(document.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: onShare,
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'More',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
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
  const _Thumb({required this.hasImage, this.path});

  final bool hasImage;
  final String? path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      child: SizedBox(
        width: AppConstants.thumbWidth,
        height: AppConstants.thumbHeight,
        child: hasImage
            ? Image.file(File(path!), fit: BoxFit.cover)
            : const ColoredBox(
                color: AppTheme.primarySoft,
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.primary,
                ),
              ),
      ),
    );
  }
}
