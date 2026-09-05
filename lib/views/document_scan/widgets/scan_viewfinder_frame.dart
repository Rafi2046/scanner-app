import 'package:flutter/material.dart';

/// Paints the mint framing outline with bottom indicator notch and card guide.
class ScanViewfinderFrame extends StatelessWidget {
  const ScanViewfinderFrame({
    super.key,
    required this.isIdCard,
  });

  final bool isIdCard;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ViewfinderPainter(isIdCard: isIdCard),
      child: const SizedBox.expand(),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({required this.isIdCard});

  final bool isIdCard;

  static const Color mint = Color(0xFF00D2A0);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..color = mint
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double pad = 4.0;
    final Rect frameRect = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);
    final RRect roundedFrame = RRect.fromRectAndRadius(frameRect, const Radius.circular(16));
    canvas.drawRRect(roundedFrame, borderPaint);

    // Draw little bottom center tab notch connecting towards mode selector
    final double centerX = size.width / 2;
    final double bottomY = size.height - pad;
    final Path notchPath = Path()
      ..moveTo(centerX - 16, bottomY)
      ..lineTo(centerX - 12, bottomY + 4)
      ..lineTo(centerX + 12, bottomY + 4)
      ..lineTo(centerX + 16, bottomY);

    final Paint notchPaint = Paint()
      ..color = mint
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(notchPath, notchPaint);

    if (isIdCard) {
      // Draw inner dashed/subtle ID card bounding guide
      final Paint idPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final double cardWidth = size.width * 0.82;
      final double cardHeight = cardWidth / 1.58;
      final Rect cardRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: cardWidth,
        height: cardHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(12)),
        idPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.isIdCard != isIdCard;
}
