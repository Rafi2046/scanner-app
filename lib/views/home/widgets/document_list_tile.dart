import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// Single library row for a saved scan.
class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
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
    return ListTile(
      leading: _LeadingThumb(
        imagePath: document.imagePaths.isEmpty
            ? null
            : document.imagePaths.first,
      ),
      title: Text(document.title),
      subtitle: Text(
        '${document.pageCount} page${document.pageCount == 1 ? '' : 's'} · ${_dateFormat.format(document.createdAt)}',
      ),
      onTap: onTap,
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
    );
  }
}

class _LeadingThumb extends StatelessWidget {
  const _LeadingThumb({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final String? path = imagePath;
    if (path == null || !File(path).existsSync()) {
      return const Icon(Icons.picture_as_pdf_outlined);
    }
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      child: Image.file(
        File(path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }
}
