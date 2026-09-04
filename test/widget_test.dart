import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/app.dart';

void main() {
  testWidgets('HomeView shows Scanner title, Bento tools, and Scan FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScannerApp(),
      ),
    );

    // Verify Brand title & header
    expect(find.text('Scanner'), findsOneWidget);

    // Verify Bento Grid tools
    expect(find.text('Smart Scan'), findsOneWidget);
    expect(find.text('ID Card'), findsOneWidget);
    expect(find.text('Text OCR'), findsOneWidget);
    expect(find.text('Merge PDF'), findsOneWidget);
    expect(find.text('All Tools'), findsOneWidget);

    // Verify Recent Documents section
    expect(find.text('Recent Documents'), findsOneWidget);

    // Verify Scan FAB
    expect(find.text('Scan'), findsOneWidget);
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
    expect(find.text('Document Library'), findsOneWidget);

    // Tap Tools tab
    await tester.tap(find.text('Tools'));
    await tester.pump();
    expect(find.text('Tools Hub'), findsOneWidget);

    // Tap Me tab
    await tester.tap(find.text('Me'));
    await tester.pump();
    expect(find.text('Rafi'), findsOneWidget);
  });
}


