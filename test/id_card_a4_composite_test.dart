import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A4 ID Card Composite and Layout tests', () {
    late Directory tempDir;
    late String frontPath;
    late String backPath;
    late String compositeOutPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('id_a4_test_');
      frontPath = p.join(tempDir.path, 'front.jpg');
      backPath = p.join(tempDir.path, 'back.jpg');
      compositeOutPath = p.join(tempDir.path, 'composite_a4.jpg');

      final img.Image frontImg = img.Image(width: 856, height: 540);
      img.fill(frontImg, color: img.ColorRgb8(200, 240, 200));
      File(frontPath).writeAsBytesSync(img.encodeJpg(frontImg));

      final img.Image backImg = img.Image(width: 856, height: 540);
      img.fill(backImg, color: img.ColorRgb8(200, 200, 240));
      File(backPath).writeAsBytesSync(img.encodeJpg(backImg));
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('createIdCardA4CompositeImage creates a pristine A4 JPEG with both cards', () async {
      const PdfService service = PdfService();
      final String resultPath = await service.createIdCardA4CompositeImage(
        frontImagePath: frontPath,
        backImagePath: backPath,
        outputPath: compositeOutPath,
      );

      expect(File(resultPath).existsSync(), isTrue);
      final img.Image? decoded = img.decodeImage(File(resultPath).readAsBytesSync());
      expect(decoded, isNotNull);
      expect(decoded!.width, 1414);
      expect(decoded.height, 2000);
      // Aspect ratio matches ISO A4 (1 : 1.414)
      final double ratio = decoded.height / decoded.width;
      expect((ratio - 1.414).abs() < 0.01, isTrue);
    });

    test('CustomScanState ID Card flow supports 2-sided cards', () {
      const CustomScanState state = CustomScanState(
        mode: CustomScanMode.idCard,
        idCategory: IdCardCategory.general,
        pages: <ScanPageDraft>[
          ScanPageDraft(imagePath: 'front.jpg', idSide: IdScanSide.front),
          ScanPageDraft(imagePath: 'back.jpg', idSide: IdScanSide.back),
        ],
      );

      expect(state.canSaveIdCard, isTrue);
      expect(state.canSave, isTrue);
    });
  });
}
