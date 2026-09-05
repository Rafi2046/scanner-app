import 'dart:io';
import 'package:flutter/material.dart';

/// Circular loupe showing a magnified region centered with sub-pixel precision on [focalDisplay].
class ScanCropMagnifier extends StatelessWidget {
  const ScanCropMagnifier({
    super.key,
    required this.imagePath,
    required this.displaySize,
    required this.focalDisplay,
    this.diameter = 136,
    this.magnification = 2.8,
  });

  final String imagePath;
  final Size displaySize;
  final Offset focalDisplay;
  final double diameter;
  final double magnification;

  @override
  Widget build(BuildContext context) {
    final double radius = diameter / 2;

    // Translation offsets so focalDisplay aligns precisely with the loupe center (radius, radius)
    final double imgW = displaySize.width * magnification;
    final double imgH = displaySize.height * magnification;
    final double left = -focalDisplay.dx * magnification + radius;
    final double top = -focalDisplay.dy * magnification + radius;

    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1B1F24),
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black87,
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Magnified image precisely mapped
              Positioned(
                left: left,
                top: top,
                width: imgW,
                height: imgH,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
              // High-precision crosshair with dark shadow outline for visibility on all backgrounds
              Positioned.fill(
                child: CustomPaint(
                  painter: _PrecisionCrosshairPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrecisionCrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    const Color accent = Color(0xFF00D2A0);

    // Dark shadow outline for visibility against both white paper and dark tables
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final Paint linePaint = Paint()
      ..color = accent
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const double gap = 5.0;
    const double length = 20.0;

    void drawCrossSegment(Offset p1, Offset p2) {
      canvas.drawLine(p1, p2, shadowPaint);
      canvas.drawLine(p1, p2, linePaint);
    }

    // Horizontal segments
    drawCrossSegment(Offset(c.dx - length, c.dy), Offset(c.dx - gap, c.dy));
    drawCrossSegment(Offset(c.dx + gap, c.dy), Offset(c.dx + length, c.dy));

    // Vertical segments
    drawCrossSegment(Offset(c.dx, c.dy - length), Offset(c.dx, c.dy - gap));
    drawCrossSegment(Offset(c.dx, c.dy + gap), Offset(c.dx, c.dy + length));

    // Center precision dot
    final Paint dotShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final Paint dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(c, 2.8, dotShadow);
    canvas.drawCircle(c, 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
