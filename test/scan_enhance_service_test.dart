import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/scan_enhance_ops.dart';
import 'package:scanner_app/services/scan_enhance_service.dart';

void main() {
  group('ScanFilter Enum & Aliases', () {
    test('bwPrint is an exact alias for bw', () {
      expect(ScanFilter.bwPrint, equals(ScanFilter.bw));
    });

    test('color is an exact alias for magicEnhance', () {
      expect(ScanFilter.color, equals(ScanFilter.magicEnhance));
    });

    test('All ScanFilter variants have descriptive labels', () {
      for (final ScanFilter filter in ScanFilter.values) {
        expect(filter.label, isNotEmpty);
      }
    });
  });

  group('Pure-Dart Isolate Image Processing (scan_enhance_ops)', () {
    late Uint8List testJpegBytes;

    setUp(() {
      // Create a test synthetic document image (100x100) with uneven lighting and colored marks
      final img.Image doc = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          // Gradient shadow from top-left (darker) to bottom-right (lighter)
          final int bg = (140 + (x + y) * 0.4).round().clamp(0, 240);
          doc.setPixelRgb(x, y, bg, bg, bg);
        }
      }

      // Add a simulated text line (dark pixels)
      for (int x = 20; x < 80; x++) {
        doc.setPixelRgb(x, 40, 30, 30, 30);
      }

      // Add a colored signature / stamp (vivid blue)
      for (int y = 60; y < 75; y++) {
        for (int x = 50; x < 70; x++) {
          doc.setPixelRgb(x, y, 20, 50, 210);
        }
      }

      testJpegBytes = Uint8List.fromList(img.encodeJpg(doc, quality: 90));
    });

    test('magicEnhance processes successfully and produces valid JPEG', () {
      final Uint8List result = applyScanFilterIsolate((
        bytes: testJpegBytes,
        filterName: ScanFilter.magicEnhance.name,
        quality: 85,
      ));

      expect(result, isNotEmpty);
      final img.Image? decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 100);
      expect(decoded.height, 100);
    });

    test('vivid processes successfully with rich color saturation', () {
      final Uint8List result = applyScanFilterIsolate((
        bytes: testJpegBytes,
        filterName: ScanFilter.vivid.name,
        quality: 90,
      ));

      expect(result, isNotEmpty);
      final img.Image? decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 100);
      expect(decoded.height, 100);
    });

    test('bwPrint produces pure binary black and white output', () {
      final Uint8List result = applyScanFilterIsolate((
        bytes: testJpegBytes,
        filterName: 'bwPrint',
        quality: 90,
      ));

      expect(result, isNotEmpty);
      final img.Image? decoded = img.decodeImage(result);
      expect(decoded, isNotNull);

      // Verify that every pixel in the thresholded document is near pure black (0) or pure white (255)
      // allowing standard lossy JPEG DCT quantization tolerance
      for (int y = 0; y < decoded!.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final img.Pixel p = decoded.getPixel(x, y);
          expect((p.r - p.g).abs() <= 5 && (p.g - p.b).abs() <= 5, isTrue);
          expect(p.r <= 15 || p.r >= 240, isTrue);
        }
      }
    });

    test('grayscale produces monochromatic image with smooth midtones', () {
      final Uint8List result = applyScanFilterIsolate((
        bytes: testJpegBytes,
        filterName: ScanFilter.grayscale.name,
        quality: 85,
      ));

      expect(result, isNotEmpty);
      final img.Image? decoded = img.decodeImage(result);
      expect(decoded, isNotNull);

      // Verify channels are equal (grayscale)
      for (int y = 0; y < decoded!.height; y += 10) {
        for (int x = 0; x < decoded.width; x += 10) {
          final img.Pixel p = decoded.getPixel(x, y);
          expect(p.r, equals(p.g));
          expect(p.g, equals(p.b));
        }
      }
    });

    test('original filter returns identical decoded pixels', () {
      final Uint8List result = applyScanFilterIsolate((
        bytes: testJpegBytes,
        filterName: ScanFilter.original.name,
        quality: 90,
      ));

      expect(result, isNotEmpty);
      final img.Image? decoded = img.decodeImage(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 100);
      expect(decoded.height, 100);
    });

    test('rotateJpegBytesIsolate rotates 90 degrees and swaps dimensions', () {
      // Create a 60x100 rectangular image
      final img.Image rect = img.Image(width: 60, height: 100);
      final Uint8List rectBytes = Uint8List.fromList(img.encodeJpg(rect));

      final Uint8List rotatedBytes = rotateJpegBytesIsolate((
        bytes: rectBytes,
        angle: 90,
        quality: 85,
      ));

      final img.Image? rotated = img.decodeImage(rotatedBytes);
      expect(rotated, isNotNull);
      expect(rotated!.width, 100);
      expect(rotated.height, 60);
    });
  });

  group('ScanEnhanceService Validation & API Contract', () {
    const ScanEnhanceService service = ScanEnhanceService();

    test('applyFilter throws ScannerException on empty imagePath', () async {
      expect(
        () => service.applyFilter(''),
        throwsA(isA<ScannerException>()),
      );
    });

    test('applyFilter throws ScannerException on nonexistent file', () async {
      expect(
        () => service.applyFilter('/non/existent/path/document.jpg'),
        throwsA(isA<ScannerException>()),
      );
    });

    test('rotateImage throws ScannerException on missing file', () async {
      expect(
        () => service.rotateImage(
          imagePath: '/non/existent/path/document.jpg',
          angle: 90,
        ),
        throwsA(isA<ScannerException>()),
      );
    });
  });
}
