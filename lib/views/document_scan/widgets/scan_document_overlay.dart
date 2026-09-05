import 'package:flutter/material.dart';
import 'package:scanner_app/models/scan_quad.dart';

/// Mint document overlay — animates between idle frame and detected document.
class ScanDocumentOverlay extends StatefulWidget {
  const ScanDocumentOverlay({
    super.key,
    required this.normalizedQuad,
    required this.isIdCard,
    this.cameraAspectRatio = 9 / 16,
  });

  final ScanQuad? normalizedQuad;
  final bool isIdCard;
  final double cameraAspectRatio;

  @override
  State<ScanDocumentOverlay> createState() => _ScanDocumentOverlayState();
}

class _ScanDocumentOverlayState extends State<ScanDocumentOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  ScanQuad? _prev;
  ScanQuad? _target;

  static const ScanQuad _defQuad = ScanQuad(
    topLeft: Offset(0.02, 0.02),
    topRight: Offset(0.98, 0.02),
    bottomRight: Offset(0.98, 0.98),
    bottomLeft: Offset(0.02, 0.98),
  );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _prev = widget.normalizedQuad ?? _defQuad;
    _target = widget.normalizedQuad ?? _defQuad;
  }

  @override
  void didUpdateWidget(covariant ScanDocumentOverlay old) {
    super.didUpdateWidget(old);
    if (widget.normalizedQuad != old.normalizedQuad) {
      _prev = _lerpQuad(_prev, _target, _anim.value);
      _target = widget.normalizedQuad ?? _defQuad;
      _anim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  ScanQuad _lerpQuad(ScanQuad? a, ScanQuad? b, double t) {
    final ScanQuad from = a ?? _defQuad;
    final ScanQuad to = b ?? _defQuad;
    return ScanQuad(
      topLeft: Offset.lerp(from.topLeft, to.topLeft, t)!,
      topRight: Offset.lerp(from.topRight, to.topRight, t)!,
      bottomRight: Offset.lerp(from.bottomRight, to.bottomRight, t)!,
      bottomLeft: Offset.lerp(from.bottomLeft, to.bottomLeft, t)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (BuildContext context, _) {
        final ScanQuad current = _lerpQuad(_prev, _target, _anim.value);
        return CustomPaint(
          painter: _DocOverlayPainter(
            quad: current,
            isIdCard: widget.isIdCard,
            isDoc: widget.normalizedQuad != null,
            camAspect: widget.cameraAspectRatio,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DocOverlayPainter extends CustomPainter {
  const _DocOverlayPainter({
    required this.quad,
    required this.isIdCard,
    required this.isDoc,
    required this.camAspect,
  });

  final ScanQuad quad;
  final bool isIdCard;
  final bool isDoc;
  final double camAspect;

  static const Color mint = Color(0xFF00D2A0);

  Offset _map(Offset p, Size size) {
    if (camAspect <= 0) return Offset(p.dx * size.width, p.dy * size.height);
    final double viewAspect = size.width / size.height;
    if (viewAspect > camAspect) {
      final double pH = size.width / camAspect;
      return Offset(p.dx * size.width, p.dy * pH - (pH - size.height) / 2.0);
    } else {
      final double pW = size.height * camAspect;
      return Offset(p.dx * pW - (pW - size.width) / 2.0, p.dy * size.height);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset tl = _map(quad.topLeft, size);
    final Offset tr = _map(quad.topRight, size);
    final Offset br = _map(quad.bottomRight, size);
    final Offset bl = _map(quad.bottomLeft, size);

    final Path path = Path()..moveTo(tl.dx, tl.dy)..lineTo(tr.dx, tr.dy)..lineTo(br.dx, br.dy)..lineTo(bl.dx, bl.dy)..close();

    if (isDoc) {
      canvas.drawPath(path, Paint()..color = mint.withValues(alpha: 0.28)..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = mint..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

      final Paint cp = Paint()..color = mint..strokeWidth = 4.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.square;
      const double cLen = 20.0;
      _drawCorner(canvas, cp, tl, tr, bl, cLen);
      _drawCorner(canvas, cp, tr, tl, br, cLen);
      _drawCorner(canvas, cp, br, bl, tr, cLen);
      _drawCorner(canvas, cp, bl, br, tl, cLen);
    } else {
      const double pad = 2.0;
      final Rect r = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()..color = mint.withValues(alpha: 0.65)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      if (isIdCard) {
        final double cW = size.width * 0.82;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: cW, height: cW / 1.58), const Radius.circular(10)), Paint()..color = Colors.white.withValues(alpha: 0.75)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      }
    }
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset c, Offset h, Offset v, double len) {
    final Offset dh = (h - c) / (h - c).distance;
    final Offset dv = (v - c) / (v - c).distance;
    canvas.drawLine(c, c + dh * len, paint);
    canvas.drawLine(c, c + dv * len, paint);
  }

  @override
  bool shouldRepaint(covariant _DocOverlayPainter old) =>
      old.quad != quad || old.isIdCard != isIdCard || old.isDoc != isDoc || old.camAspect != camAspect;
}
