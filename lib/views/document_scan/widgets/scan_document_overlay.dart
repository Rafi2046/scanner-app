import 'package:flutter/material.dart';

/// Clean, static camera overlay for ID cards.
/// Replaces jumpy live object detection with a clean, static framing guide.
class ScanDocumentOverlay extends StatelessWidget {
  const ScanDocumentOverlay({
    super.key,
    required this.isIdCard,
    this.frameHint = 'Fit ID card inside the frame',
  });

  final bool isIdCard;
  final String frameHint;

  @override
  Widget build(BuildContext context) {
    if (!isIdCard) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double cardW = width * 0.84;
        final double cardH = cardW / 1.586; // ISO/IEC 7810 ID-1 standard ratio
        final Rect cardRect = Rect.fromCenter(
          center: Offset(width / 2, height / 2),
          width: cardW,
          height: cardH,
        );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              size: Size(width, height),
              painter: _IdCardGuidePainter(cardRect: cardRect),
            ),
            Positioned(
              top: cardRect.bottom + 16,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    frameHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IdCardGuidePainter extends CustomPainter {
  const _IdCardGuidePainter({required this.cardRect});

  final Rect cardRect;

  static const Color accent = Color(0xFF00D2A0);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(14));

    // 1. Subtle dark vignette/scrim outside the card area
    final Path fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cardPath = Path()..addRRect(rrect);
    final Path scrimPath = Path.combine(PathOperation.difference, fullPath, cardPath);
    canvas.drawPath(
      scrimPath,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    // 2. Subtle white guide border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Crisp modern corner brackets in mint accent
    final Paint cornerPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double cLen = 22.0;
    final double l = cardRect.left;
    final double t = cardRect.top;
    final double r = cardRect.right;
    final double b = cardRect.bottom;
    const double radiusOffset = 14.0;

    // Top-left corner
    canvas.drawLine(Offset(l + radiusOffset, t), Offset(l + radiusOffset + cLen, t), cornerPaint);
    canvas.drawLine(Offset(l, t + radiusOffset), Offset(l, t + radiusOffset + cLen), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(r - radiusOffset, t), Offset(r - radiusOffset - cLen, t), cornerPaint);
    canvas.drawLine(Offset(r, t + radiusOffset), Offset(r, t + radiusOffset + cLen), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(l + radiusOffset, b), Offset(l + radiusOffset + cLen, b), cornerPaint);
    canvas.drawLine(Offset(l, b - radiusOffset), Offset(l, b - radiusOffset - cLen), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(r - radiusOffset, b), Offset(r - radiusOffset - cLen, b), cornerPaint);
    canvas.drawLine(Offset(r, b - radiusOffset), Offset(r, b - radiusOffset - cLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _IdCardGuidePainter oldDelegate) =>
      oldDelegate.cardRect != cardRect;
}
