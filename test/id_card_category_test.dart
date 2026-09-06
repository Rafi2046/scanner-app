import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/views/document_scan/widgets/id_card_type_selector_view.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_mode_carousel.dart';

void main() {
  group('IdCardCategory enum tests', () {
    test('contains all 8 preset categories', () {
      expect(IdCardCategory.values.length, 8);
      expect(IdCardCategory.values.map((c) => c.title).toList(), <String>[
        'General',
        'Driver Licence',
        'ID Card',
        'Passport',
        'Bank Card',
        'Certificate',
        'SSN',
        'Auto Insurance',
      ]);
    });

    test('validates side counts for 1-sided and 2-sided categories', () {
      expect(IdCardCategory.general.sides, 2);
      expect(IdCardCategory.general.isSingleSide, isFalse);

      expect(IdCardCategory.driverLicense.sides, 2);
      expect(IdCardCategory.autoInsurance.sides, 2);

      expect(IdCardCategory.passport.sides, 1);
      expect(IdCardCategory.passport.isSingleSide, isTrue);

      expect(IdCardCategory.certificate.sides, 1);
      expect(IdCardCategory.certificate.isSingleSide, isTrue);
    });
  });

  group('CustomScanState ID Card logic', () {
    test('canSaveIdCard requires 2 sides for 2-sided categories', () {
      const CustomScanState stateFrontOnly = CustomScanState(
        mode: CustomScanMode.idCard,
        idCategory: IdCardCategory.autoInsurance,
        pages: <ScanPageDraft>[
          ScanPageDraft(imagePath: 'front.jpg', idSide: IdScanSide.front),
        ],
      );
      expect(stateFrontOnly.canSaveIdCard, isFalse);

      const CustomScanState stateBothSides = CustomScanState(
        mode: CustomScanMode.idCard,
        idCategory: IdCardCategory.autoInsurance,
        pages: <ScanPageDraft>[
          ScanPageDraft(imagePath: 'front.jpg', idSide: IdScanSide.front),
          ScanPageDraft(imagePath: 'back.jpg', idSide: IdScanSide.back),
        ],
      );
      expect(stateBothSides.canSaveIdCard, isTrue);
    });

    test('canSaveIdCard requires only 1 side for single-side categories', () {
      const CustomScanState stateFrontOnly = CustomScanState(
        mode: CustomScanMode.idCard,
        idCategory: IdCardCategory.passport,
        pages: <ScanPageDraft>[
          ScanPageDraft(imagePath: 'passport.jpg', idSide: IdScanSide.front),
        ],
      );
      expect(stateFrontOnly.canSaveIdCard, isTrue);
    });
  });

  group('IdCardTypeSelectorView widget tests', () {
    testWidgets('renders A4 paper example, chips, security text, and Make it now button', (
      WidgetTester tester,
    ) async {
      IdCardCategory selected = IdCardCategory.general;
      bool madeItNow = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdCardTypeSelectorView(
              selectedCategory: selected,
              onCategorySelected: (cat) => selected = cat,
              onMakeItNow: () => madeItNow = true,
              onClose: () {},
              onToggleFlash: () {},
              isFlashOn: false,
              tabMode: ScanTabMode.idCards,
              onTabModeChanged: (_) {},
              onOpenFeatures: () {},
            ),
          ),
        ),
      );

      // Verify "A4 paper example" badge exists
      expect(find.text('A4 paper example'), findsOneWidget);

      // Verify Security disclaimer text exists
      expect(find.textContaining('Scan ID documents anytime'), findsOneWidget);
      expect(find.text('Learn more >'), findsOneWidget);

      // Verify category chips are present
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Driver Licence'), findsOneWidget);
      expect(find.text('ID Card'), findsOneWidget);

      // Verify "Make it now" button exists and works
      final Finder makeItNowBtn = find.text('Make it now');
      expect(makeItNowBtn, findsOneWidget);

      await tester.tap(makeItNowBtn);
      await tester.pump();
      expect(madeItNow, isTrue);
    });

    testWidgets('renders unique mockups for each of the 8 categories', (
      WidgetTester tester,
    ) async {
      final Map<IdCardCategory, String> expectedTexts = <IdCardCategory, String>{
        IdCardCategory.general: 'IDENTIFICATION DOCUMENT',
        IdCardCategory.driverLicense: 'STATE DRIVER LICENSE',
        IdCardCategory.idCard: 'NATIONAL IDENTITY CARD',
        IdCardCategory.passport: 'PASSPORT / PASSEPORT',
        IdCardCategory.bankCard: 'PLATINUM ELITE',
        IdCardCategory.certificate: 'CERTIFICATE OF ACHIEVEMENT',
        IdCardCategory.ssn: 'SOCIAL SECURITY',
        IdCardCategory.autoInsurance: 'STATE MOTOR VEHICLE INSURANCE ID',
      };

      for (final MapEntry<IdCardCategory, String> entry in expectedTexts.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IdCardTypeSelectorView(
                selectedCategory: entry.key,
                onCategorySelected: (_) {},
                onMakeItNow: () {},
                onClose: () {},
                onToggleFlash: () {},
                isFlashOn: false,
                tabMode: ScanTabMode.idCards,
                onTabModeChanged: (_) {},
                onOpenFeatures: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(entry.value),
          findsOneWidget,
          reason: 'Expected distinct text for ${entry.key.title}',
        );
      }
    });
  });
}

