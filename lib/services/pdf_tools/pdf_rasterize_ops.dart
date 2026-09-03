import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart' hide PdfException;
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/pdf_tools/rasterized_pdf_page.dart';

/// Renders PDF pages to compressed JPEGs via pdfrx + flutter_image_compress.
abstract final class PdfRasterizeOps {
  static Future<List<RasterizedPdfPage>> rasterize({
    required String pdfPath,
    int maxEdge = AppConstants.compressMaxEdge,
    int quality = AppConstants.compressJpegQuality,
  }) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(pdfPath);
      if (document.pages.isEmpty) {
        throw const PdfException('The PDF has no pages.');
      }

      final List<RasterizedPdfPage> pages = <RasterizedPdfPage>[];
      for (int i = 0; i < document.pages.length; i++) {
        pages.add(
          await _renderPage(
            document.pages[i],
            maxEdge: maxEdge,
            quality: quality,
          ),
        );
      }
      return pages;
    } on PdfException {
      rethrow;
    } catch (error) {
      throw PdfException(
        'Failed to rasterize PDF pages.',
        cause: error,
      );
    } finally {
      await document?.dispose();
    }
  }

  static Future<RasterizedPdfPage> _renderPage(
    PdfPage page, {
    required int maxEdge,
    required int quality,
  }) async {
    final double pageWidth = page.width;
    final double pageHeight = page.height;
    if (pageWidth <= 0 || pageHeight <= 0) {
      throw const PdfException('A PDF page has invalid dimensions.');
    }

    final double scale = math.min(maxEdge / pageWidth, maxEdge / pageHeight);
    final int renderWidth = math.max(1, (pageWidth * scale).round());
    final int renderHeight = math.max(1, (pageHeight * scale).round());

    final PdfImage? rendered = await page.render(
      fullWidth: renderWidth.toDouble(),
      fullHeight: renderHeight.toDouble(),
    );
    if (rendered == null) {
      throw const PdfException('Failed to render a PDF page.');
    }

    try {
      final Uint8List jpeg = await _rgbaToCompressedJpeg(
        pixels: rendered.pixels,
        width: rendered.width,
        height: rendered.height,
        quality: quality,
        pixelFormat: rendered.format,
      );
      return RasterizedPdfPage(
        jpegBytes: jpeg,
        pageSize: ui.Size(pageWidth, pageHeight),
      );
    } finally {
      rendered.dispose();
    }
  }

  static Future<Uint8List> _rgbaToCompressedJpeg({
    required Uint8List pixels,
    required int width,
    required int height,
    required int quality,
    required ui.PixelFormat pixelFormat,
  }) async {
    final img.ChannelOrder order = pixelFormat == ui.PixelFormat.bgra8888
        ? img.ChannelOrder.bgra
        : img.ChannelOrder.rgba;
    final img.Image decoded = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.buffer,
      bytesOffset: pixels.offsetInBytes,
      rowStride: width * 4,
      order: order,
      numChannels: 4,
    );
    final Uint8List png = Uint8List.fromList(img.encodePng(decoded));
    final Uint8List compressed = await FlutterImageCompress.compressWithList(
      png,
      quality: quality,
      minWidth: AppConstants.compressMaxEdge,
      minHeight: AppConstants.compressMaxEdge,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (compressed.isEmpty) {
      throw const PdfException('Image compression produced an empty file.');
    }
    return compressed;
  }
}
