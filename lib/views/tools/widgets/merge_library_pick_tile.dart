import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// Compact selectable scan row with preview thumbnail.
class MergeLibraryPickTile extends StatelessWidget {
  const MergeLibraryPickTile({
    super.key,
    required this.document,
    required this.selected,
    required this.onToggle,
    required this.onPreview,
  });

  final ScannedDocument document;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onPreview;

  static String formatDate(DateTime dt) {
    final DateTime now = DateTime.now();
    final bool isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return DateFormat.jm().format(dt);
    }
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final String? thumb =
        document.imagePaths.isNotEmpty ? document.imagePaths.first : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.5)
              : const Color(0xFFF1F3F5),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                MergePaperThumb(
                  path: thumb,
                  pageCount: document.pageCount,
                  selected: selected,
                  onPreview: onPreview,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
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
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${document.pageCount} '
                              '${document.pageCount == 1 ? 'page' : 'pages'}'
                              ' · ${formatDate(document.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MergePickCheck(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact circular selection indicator.
class MergePickCheck extends StatelessWidget {
  const MergePickCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppTheme.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppTheme.primary : const Color(0xFFD1D5DB),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
          : null,
    );
  }
}

/// Compact thumbnail with expand affordance.
class MergePaperThumb extends StatelessWidget {
  const MergePaperThumb({
    super.key,
    required this.path,
    required this.pageCount,
    required this.selected,
    required this.onPreview,
  });

  final String? path;
  final int pageCount;
  final bool selected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPreview,
      child: Container(
        width: 48,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (path != null && File(path!).existsSync())
              Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ThumbFallback(),
              )
            else
              const _ThumbFallback(),
            Positioned(
              right: 3,
              bottom: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  LucideIcons.maximize2,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
            if (pageCount > 1)
              Positioned(
                left: 3,
                bottom: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${pageCount}P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
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

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.primarySoft,
      child: Center(
        child: Icon(LucideIcons.fileText, color: AppTheme.primary, size: 20),
      ),
    );
  }
}
