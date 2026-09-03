import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/app.dart';

void main() {
  testWidgets('HomeView shows Scanner title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScannerApp(),
      ),
    );

    expect(find.text('Scanner'), findsOneWidget);
  });
}
