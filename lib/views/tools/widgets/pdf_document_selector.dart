import 'package:flutter/material.dart';
import 'package:scanner_app/models/scanned_document.dart';

/// Single or multi select list of library PDFs.
class PdfDocumentSelector extends StatelessWidget {
  const PdfDocumentSelector({
    super.key,
    required this.documents,
    required this.selectedIds,
    required this.onToggle,
    this.multiSelect = true,
  });

  final List<ScannedDocument> documents;
  final Set<String> selectedIds;
  final ValueChanged<ScannedDocument> onToggle;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Center(
        child: Text('No PDFs in the library yet. Import or scan first.'),
      );
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final ScannedDocument doc = documents[index];
        final bool selected = selectedIds.contains(doc.id);
        return ListTile(
          leading: Icon(
            multiSelect
                ? (selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank)
                : (selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
          ),
          title: Text(doc.title),
          subtitle: Text('${doc.pageCount} page${doc.pageCount == 1 ? '' : 's'}'),
          selected: selected,
          onTap: () => onToggle(doc),
        );
      },
    );
  }
}
