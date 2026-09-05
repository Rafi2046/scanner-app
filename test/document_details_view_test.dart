import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_app/core/enums/document_kind.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/views/document_details/document_details_view.dart';

void main() {
  testWidgets('DocumentDetailsView renders title, page cards, add page, and bottom bar',
      (WidgetTester tester) async {
    final ScannedDocument doc = ScannedDocument(
      id: 'test_doc_1',
      title: 'Invoice 2026',
      kind: DocumentKind.scan,
      createdAt: DateTime(2026, 9, 6, 1, 16),
      pageCount: 1,
      imagePaths: const <String>['/dummy/path/page_1.jpg'],
      pdfPath: '/dummy/path/doc.pdf',
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DocumentDetailsView(
            documentId: doc.id,
            initialDocument: doc,
          ),
        ),
      ),
    );

    // Verify Title and Subtitle in AppBar
    expect(find.text('Invoice 2026'), findsOneWidget);
    expect(find.textContaining('1 page ·'), findsOneWidget);
    expect(find.text('Document Scan'), findsNothing);

    // Verify "Add Page" tile in grid
    expect(find.text('Add Page'), findsWidgets);

    // Verify un-needed banners are not present
    expect(find.text('Extract text from document (AI OCR)'), findsNothing);

    // Verify Bottom Bar tools
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('OCR'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
