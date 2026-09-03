import 'package:flutter/material.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/document_list_tile.dart';

class HomeDocumentList extends StatelessWidget {
  const HomeDocumentList({
    super.key,
    required this.documents,
    required this.onDelete,
  });

  final List<ScannedDocument> documents;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: documents.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final ScannedDocument document = documents[index];
        return DocumentListTile(
          document: document,
          onDelete: () => onDelete(document.id),
        );
      },
    );
  }
}
