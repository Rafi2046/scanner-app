import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_app/models/timestamp_config.dart';
import 'package:scanner_app/providers/timestamp_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/draggable_timestamp_overlay.dart';
import 'package:scanner_app/views/document_scan/widgets/edit_timestamp_bottom_sheet.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_mode_carousel.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/views/document_scan/widgets/timestamp_overlay_card.dart';

void main() {
  group('TimestampTemplateType and Config tests', () {
    test('contains all 6 custom preset templates', () {
      expect(TimestampTemplateType.values.length, 6);
      expect(
        TimestampTemplateType.values.map((t) => t.title).toList(),
        <String>[
          'Minimal Clean',
          'On-Site Pro',
          'Clock-In',
          'Digital Clock',
          'Verified Stamp',
          'Travel & Weather',
        ],
      );
    });

    test('TimestampConfig copyWith updates fields correctly including scale and positionRatio', () {
      const TimestampConfig initial = TimestampConfig();
      expect(initial.template, TimestampTemplateType.minimal);
      expect(initial.is24Hour, isFalse);
      expect(initial.showSeconds, isTrue);
      expect(initial.scale, 1.0);
      expect(initial.positionRatio, const Offset(0.04, 0.72));

      final TimestampConfig updated = initial.copyWith(
        template: TimestampTemplateType.onSite,
        is24Hour: true,
        locationText: 'Project Site X',
        scale: 1.5,
        positionRatio: const Offset(0.5, 0.5),
      );
      expect(updated.template, TimestampTemplateType.onSite);
      expect(updated.is24Hour, isTrue);
      expect(updated.locationText, 'Project Site X');
      expect(updated.scale, 1.5);
      expect(updated.positionRatio, const Offset(0.5, 0.5));
    });

    test('TimestampConfigNotifier updates state, scale clamping, and reset', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timestampConfigProvider.notifier);
      expect(container.read(timestampConfigProvider).template, TimestampTemplateType.minimal);

      notifier.setTemplate(TimestampTemplateType.clockIn);
      expect(container.read(timestampConfigProvider).template, TimestampTemplateType.clockIn);

      notifier.setLocationText('Dhanmondi, Dhaka');
      expect(container.read(timestampConfigProvider).locationText, 'Dhanmondi, Dhaka');

      notifier.toggle24Hour(true);
      expect(container.read(timestampConfigProvider).is24Hour, isTrue);

      // Scale clamping tests (0.65x to 1.80x)
      notifier.setScale(1.5);
      expect(container.read(timestampConfigProvider).scale, 1.5);

      notifier.setScale(10.0);
      expect(container.read(timestampConfigProvider).scale, 1.80);

      notifier.setScale(0.1);
      expect(container.read(timestampConfigProvider).scale, 0.65);

      // Position ratio
      notifier.setPositionRatio(const Offset(0.25, 0.35));
      expect(container.read(timestampConfigProvider).positionRatio, const Offset(0.25, 0.35));

      // Reset
      notifier.resetPositionAndScale();
      expect(container.read(timestampConfigProvider).scale, 1.0);
      expect(container.read(timestampConfigProvider).positionRatio, const Offset(0.04, 0.72));
    });

    test('ScanTabMode contains timestamp option', () {
      expect(ScanTabMode.values.contains(ScanTabMode.timestamp), isTrue);
      expect(ScanTabMode.timestamp.label, 'Timestamp');
    });
  });

  group('TimestampOverlayCard rendering tests', () {
    final DateTime testDate = DateTime(2026, 9, 6, 10, 40, 15);

    for (final TimestampTemplateType template in TimestampTemplateType.values) {
      testWidgets('renders template: ${template.title} without overflow', (
        WidgetTester tester,
      ) async {
        final TimestampConfig config = TimestampConfig(
          template: template,
          locationText: 'Shikdar Pharmacy',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: TimestampOverlayCard(
                  config: config,
                  fixedTime: testDate,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        // Verify location or template specific text is present
        expect(find.textContaining('Shikdar Pharmacy'), findsOneWidget);
      });
    }
  });

  group('DraggableTimestampOverlay tests', () {
    testWidgets('renders DraggableTimestampOverlay and responds to drag gesture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  DraggableTimestampOverlay(
                    viewportSize: Size(400, 700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify toolbar buttons are present
      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);

      // Drag the overlay
      await tester.drag(find.byType(TimestampOverlayCard), const Offset(50, -100));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping plus, minus, and reset on toolbar adjusts scale directly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  DraggableTimestampOverlay(
                    viewportSize: Size(400, 700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initial scale is 100%
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Tap minus button
      await tester.tap(find.byIcon(LucideIcons.minus));
      await tester.pumpAndSettle();

      // Scale should decrease to 90%
      expect(find.text('90%'), findsOneWidget);

      // Tap plus button twice
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      expect(find.text('110%'), findsOneWidget);

      // Tap reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('EditTimestampBottomSheet widget tests', () {
    testWidgets('renders Edit Timestamp sheet with Templates and Content tabs including Size and Placement', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditTimestampBottomSheet(),
            ),
          ),
        ),
      );

      // Verify Header and Tabs
      expect(find.text('Edit Timestamp'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);

      // Verify template titles exist in grid
      expect(find.text('Minimal Clean'), findsOneWidget);
      expect(find.text('On-Site Pro'), findsOneWidget);
      expect(find.text('Clock-In'), findsAtLeastNWidgets(1));

      // Switch to Content tab
      await tester.tap(find.text('Content'));
      await tester.pumpAndSettle();

      // Verify Content options
      expect(find.text('Time Format'), findsOneWidget);
      expect(find.text('Display Seconds'), findsOneWidget);
      expect(find.text('Location Tag'), findsOneWidget);
      expect(find.text('Custom Note / Tag'), findsOneWidget);
      expect(find.text('Security Watermark'), findsOneWidget);

      // Verify new Stamp Size and Placement controls
      expect(find.text('Stamp Size'), findsOneWidget);
      expect(find.text('Quick Placement'), findsOneWidget);
      expect(find.text('Bottom-Left'), findsOneWidget);
      expect(find.text('Bottom-Right'), findsOneWidget);
      expect(find.text('Top-Left'), findsOneWidget);
      expect(find.text('Top-Right'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
    });
  });
}
