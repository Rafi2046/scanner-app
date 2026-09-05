import 'package:flutter/material.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/home/widgets/modern_document_card.dart';

class HomeDocumentList extends StatelessWidget {
  const HomeDocumentList({
    super.key,
    required this.documents,
    required this.onDelete,
    this.onTap,
    this.onRename,
    this.physics,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.only(bottom: 88),
  });

  final List<ScannedDocument> documents;
  final ValueChanged<String> onDelete;
  final ValueChanged<ScannedDocument>? onTap;
  final void Function(String id, String newTitle)? onRename;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: documents.length,
      itemBuilder: (BuildContext context, int index) {
        final ScannedDocument document = documents[index];
        return ModernDocumentCard(
          document: document,
          onTap: onTap != null ? () => onTap!(document) : null,
          onDelete: () => onDelete(document.id),
          onRename: onRename != null
              ? (String newTitle) => onRename!(document.id, newTitle)
              : null,
        );
      },
    );
  }
}
