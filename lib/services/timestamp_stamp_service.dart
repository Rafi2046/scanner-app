import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:scanner_app/models/timestamp_config.dart';

/// Stamping engine that renders vector-crisp timestamp templates onto captured still images.
class TimestampStampService {
  const TimestampStampService();

  Future<String> stampImage({
    required String imagePath,
    required TimestampConfig config,
  }) async {
    try {
      final File file = File(imagePath);
      if (!await file.exists()) return imagePath;

      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image img = frame.image;

      final double imgWidth = img.width.toDouble();
      final double imgHeight = img.height.toDouble();

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

      // Draw original image
      canvas.drawImage(img, Offset.zero, Paint());

      // Draw timestamp overlay positioned and scaled according to config
      _drawTimestampCard(canvas, imgWidth, imgHeight, config);

      final ui.Picture picture = recorder.endRecording();
      final ui.Image stamped = await picture.toImage(imgWidth.toInt(), imgHeight.toInt());
      final ByteData? pngBytes = await stamped.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes == null) return imagePath;

      final String dir = p.dirname(imagePath);
      final String stampedPath = p.join(
        dir,
        'stamped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await File(stampedPath).writeAsBytes(pngBytes.buffer.asUint8List());
      return stampedPath;
    } catch (_) {
      // If stamping encounters any error, fallback gracefully to original photo
      return imagePath;
    }
  }

  void _drawTimestampCard(Canvas canvas, double width, double height, TimestampConfig config) {
    final DateTime now = DateTime.now();
    final double scale = (width / 720.0).clamp(1.0, 3.5) * config.scale;

    final String timeStr = config.is24Hour
        ? (config.showSeconds ? DateFormat('HH:mm:ss').format(now) : DateFormat('HH:mm').format(now))
        : (config.showSeconds ? DateFormat('hh:mm:ss a').format(now) : DateFormat('hh:mm a').format(now));
    final String dateStr = DateFormat('EEEE | MM/dd/yy').format(now);

    final double targetX = config.positionRatio.dx * width;
    final double targetY = config.positionRatio.dy * height;

    switch (config.template) {
      case TimestampTemplateType.onSite:
        _drawOnSite(canvas, targetX, targetY, width, height, scale, timeStr, now, config);
      case TimestampTemplateType.clockIn:
        _drawClockIn(canvas, targetX, targetY, width, height, scale, timeStr, now, config);
      case TimestampTemplateType.digitalLcd:
        _drawDigitalLcd(canvas, targetX, targetY, width, height, scale, timeStr, now, config);
      case TimestampTemplateType.officialStamp:
        _drawOfficialStamp(canvas, targetX, targetY, width, height, scale, timeStr, now, config);
      case TimestampTemplateType.travelPin:
        _drawTravelPin(canvas, targetX, targetY, width, height, scale, timeStr, config);
      case TimestampTemplateType.minimal:
        _drawMinimal(canvas, targetX, targetY, width, height, scale, timeStr, dateStr, config);
    }
  }

  void _drawMinimal(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    String date,
    TimestampConfig config,
  ) {
    final TextPainter tpTime = _text(time, 24 * scale, FontWeight.w800, Colors.white);
    final TextPainter tpDate = _text(date, 12 * scale, FontWeight.w500, Colors.white.withValues(alpha: 0.9));
    final TextPainter? tpLoc = config.showLocation
        ? _text('📍 ${config.locationText}', 11.5 * scale, FontWeight.w600, Colors.white)
        : null;
    final TextPainter? tpVer = config.showVerified
        ? _text('🛡️ ${config.verifiedBy}', 10 * scale, FontWeight.w500, const Color(0xFF00C292))
        : null;

    double cardW = tpTime.width;
    if (tpDate.width > cardW) cardW = tpDate.width;
    if (tpLoc != null && tpLoc.width > cardW) cardW = tpLoc.width;
    if (tpVer != null && tpVer.width > cardW) cardW = tpVer.width;
    cardW += 28 * scale;

    double cardH = tpTime.height + tpDate.height + (16 * scale);
    if (tpLoc != null) cardH += tpLoc.height + (4 * scale);
    if (tpVer != null) cardH += tpVer.height + (4 * scale);

    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, topY, cardW, cardH),
      Radius.circular(12 * scale),
    );

    canvas.drawRRect(rrect, Paint()..color = Colors.black.withValues(alpha: 0.65));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    double curY = topY + (8 * scale);
    tpTime.paint(canvas, Offset(x + 14 * scale, curY));
    curY += tpTime.height + (2 * scale);
    tpDate.paint(canvas, Offset(x + 14 * scale, curY));
    curY += tpDate.height + (4 * scale);
    if (tpLoc != null) {
      tpLoc.paint(canvas, Offset(x + 14 * scale, curY));
      curY += tpLoc.height + (4 * scale);
    }
    if (tpVer != null) {
      tpVer.paint(canvas, Offset(x + 14 * scale, curY));
    }
  }

  void _drawOnSite(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    DateTime now,
    TimestampConfig config,
  ) {
    final TextPainter tpHead = _text('ON-SITE INSPECTION', 11 * scale, FontWeight.w900, Colors.white);
    final TextPainter tpTime = _text('Time: $time', 11 * scale, FontWeight.w700, Colors.white);
    final TextPainter tpDate = _text('Date: ${DateFormat('yyyy-MM-dd').format(now)}', 10 * scale, FontWeight.w500, Colors.white70);
    final TextPainter? tpLoc = config.showLocation
        ? _text('Location: ${config.locationText}', 10 * scale, FontWeight.w500, Colors.white70)
        : null;

    final double cardW = 240 * scale;
    final double cardH = (config.showLocation ? 105 : 85) * scale;
    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topY, cardW, cardH), Radius.circular(10 * scale));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF10141E).withValues(alpha: 0.88));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2563EB)..style = PaintingStyle.stroke..strokeWidth = 1.2 * scale);

    final RRect headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, topY, cardW, 26 * scale),
      topLeft: Radius.circular(9 * scale),
      topRight: Radius.circular(9 * scale),
    );
    canvas.drawRRect(headerRect, Paint()..color = const Color(0xFF2563EB));
    tpHead.paint(canvas, Offset(x + 10 * scale, topY + 6 * scale));

    double curY = topY + 34 * scale;
    tpTime.paint(canvas, Offset(x + 10 * scale, curY));
    curY += 18 * scale;
    tpDate.paint(canvas, Offset(x + 10 * scale, curY));
    if (tpLoc != null) {
      curY += 18 * scale;
      tpLoc.paint(canvas, Offset(x + 10 * scale, curY));
    }
  }

  void _drawClockIn(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    DateTime now,
    TimestampConfig config,
  ) {
    final TextPainter tpBadge = _text('CLOCK-IN', 9 * scale, FontWeight.w900, const Color(0xFF06281E));
    final TextPainter tpDay = _text(DateFormat('MMM dd • EEE').format(now).toUpperCase(), 9 * scale, FontWeight.w700, const Color(0xFF00C292));
    final TextPainter tpTime = _text(time, 24 * scale, FontWeight.w900, Colors.white);
    final TextPainter? tpLoc = config.showLocation
        ? _text('📍 ${config.locationText}', 10 * scale, FontWeight.w500, Colors.white70)
        : null;

    final double cardW = 220 * scale;
    final double cardH = (config.showLocation ? 85 : 68) * scale;
    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topY, cardW, cardH), Radius.circular(10 * scale));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0C1412).withValues(alpha: 0.85));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF00C292)..style = PaintingStyle.stroke..strokeWidth = 1.2 * scale);

    final RRect badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 8 * scale, topY + 8 * scale, tpBadge.width + 10 * scale, 16 * scale),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(badgeRRect, Paint()..color = const Color(0xFF00C292));
    tpBadge.paint(canvas, Offset(x + 13 * scale, topY + 10 * scale));
    tpDay.paint(canvas, Offset(x + 24 * scale + tpBadge.width, topY + 10 * scale));

    tpTime.paint(canvas, Offset(x + 8 * scale, topY + 28 * scale));
    if (tpLoc != null) {
      tpLoc.paint(canvas, Offset(x + 8 * scale, topY + 58 * scale));
    }
  }

  void _drawDigitalLcd(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    DateTime now,
    TimestampConfig config,
  ) {
    const Color lcdColor = Color(0xFF00FFB2);
    final TextPainter tpDate = _text(DateFormat('yyyy/MM/dd EEE').format(now).toUpperCase(), 10 * scale, FontWeight.w700, lcdColor.withValues(alpha: 0.8));
    final TextPainter tpTime = _text(time, 26 * scale, FontWeight.w900, lcdColor);
    final TextPainter? tpLoc = config.showLocation
        ? _text('TARGET: ${config.locationText}', 9.5 * scale, FontWeight.w600, lcdColor.withValues(alpha: 0.85))
        : null;

    final double cardW = 240 * scale;
    final double cardH = (config.showLocation ? 80 : 62) * scale;
    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topY, cardW, cardH), Radius.circular(8 * scale));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF060D0A).withValues(alpha: 0.9));
    canvas.drawRRect(rrect, Paint()..color = lcdColor..style = PaintingStyle.stroke..strokeWidth = 1.2 * scale);

    tpDate.paint(canvas, Offset(x + 10 * scale, topY + 8 * scale));
    tpTime.paint(canvas, Offset(x + 10 * scale, topY + 24 * scale));
    if (tpLoc != null) {
      tpLoc.paint(canvas, Offset(x + 10 * scale, topY + 56 * scale));
    }
  }

  void _drawOfficialStamp(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    DateTime now,
    TimestampConfig config,
  ) {
    const Color gold = Color(0xFFF59E0B);
    final TextPainter tpHead = _text('VERIFIED TIMESTAMP', 10 * scale, FontWeight.w900, gold);
    final TextPainter tpTime = _text('$time • ${DateFormat('yyyy-MM-dd').format(now)}', 13 * scale, FontWeight.w700, Colors.white);
    final TextPainter? tpLoc = config.showLocation ? _text('📍 ${config.locationText}', 9.5 * scale, FontWeight.w500, Colors.white70) : null;

    final double cardW = 230 * scale;
    final double cardH = (config.showLocation ? 70 : 54) * scale;
    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topY, cardW, cardH), Radius.circular(8 * scale));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF140E04).withValues(alpha: 0.9));
    canvas.drawRRect(rrect, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 1.2 * scale);

    tpHead.paint(canvas, Offset(x + 10 * scale, topY + 8 * scale));
    tpTime.paint(canvas, Offset(x + 10 * scale, topY + 24 * scale));
    if (tpLoc != null) {
      tpLoc.paint(canvas, Offset(x + 10 * scale, topY + 44 * scale));
    }
  }

  void _drawTravelPin(
    Canvas canvas,
    double targetX,
    double targetY,
    double width,
    double height,
    double scale,
    String time,
    TimestampConfig config,
  ) {
    final TextPainter tpTime = _text('$time  28°C', 16 * scale, FontWeight.w800, Colors.white);
    final TextPainter? tpLoc = config.showLocation ? _text(config.locationText, 10 * scale, FontWeight.w500, Colors.white70) : null;

    final double cardW = 180 * scale;
    final double cardH = (config.showLocation ? 50 : 38) * scale;
    final double x = targetX.clamp(12.0 * scale, math.max(12.0 * scale, width - cardW - 12.0 * scale));
    final double topY = targetY.clamp(12.0 * scale, math.max(12.0 * scale, height - cardH - 12.0 * scale));

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, topY, cardW, cardH), Radius.circular(16 * scale));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E1E28).withValues(alpha: 0.85));
    canvas.drawRRect(rrect, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.0 * scale);

    tpTime.paint(canvas, Offset(x + 12 * scale, topY + 8 * scale));
    if (tpLoc != null) {
      tpLoc.paint(canvas, Offset(x + 12 * scale, topY + 28 * scale));
    }
  }

  TextPainter _text(String content, double size, FontWeight weight, Color color) {
    return TextPainter(
      text: TextSpan(
        text: content,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
  }
}
