import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/app.dart';
import 'package:scanner_app/views/home/widgets/files_storage_meter.dart';

void main() {
  testWidgets('HomeView shows Scanner title, Bento tools, and Scan button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScannerApp(),
      ),
    );

    // Verify Brand title & header
    expect(find.text('Scanner'), findsOneWidget);

    // Verify Quick Tools
    expect(find.text('ID Card'), findsOneWidget);
    expect(find.text('eSign'), findsOneWidget);
    expect(find.text('Watermark'), findsOneWidget);
    expect(find.text('All Tools'), findsOneWidget);

    // Verify Recent Files section
    expect(find.text('Recent Files'), findsOneWidget);

    // Verify Scan option
    expect(find.text('Scan'), findsWidgets);
  });

  testWidgets('Search input field updates text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScannerApp(),
      ),
    );

    final Finder searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Passport');
    await tester.pump();

    expect(find.text('Passport'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs to Files, Tools, and Me',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScannerApp(),
      ),
    );

    // Tap Files tab
    await tester.tap(find.text('Files'));
    await tester.pump();
    expect(find.byType(FilesStorageMeter), findsOneWidget);

    // Tap Tools tab
    await tester.tap(find.text('Tools'));
    await tester.pump();
    expect(find.text('Scan & Capture'), findsOneWidget);

    // Tap Account tab
    await tester.tap(find.text('Account'));
    await tester.pump();
    expect(find.text('Local user'), findsOneWidget);
  });
}
