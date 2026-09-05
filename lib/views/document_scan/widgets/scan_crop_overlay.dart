import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanner_app/models/scan_quad.dart';

/// Interactive draggable quad overlay for perspective crop.
class ScanCropOverlay extends StatefulWidget {
  const ScanCropOverlay({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.quad,
    required this.maxSize,
    required this.onQuadChanged,
  });

  final String imagePath;
  final Size imageSize;
  final ScanQuad quad;
  final Size maxSize;
  final ValueChanged<ScanQuad> onQuadChanged;

  @override
  State<ScanCropOverlay> createState() => _ScanCropOverlayState();
}

class _ScanCropOverlayState extends State<ScanCropOverlay> {
  late ScanQuad _localQuad;

  @override
  void initState() {
    super.initState();
    _localQuad = widget.quad;
  }

  @override
  void didUpdateWidget(covariant ScanCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quad != oldWidget.quad) {
      _localQuad = widget.quad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scale = _fitScale(widget.imageSize, widget.maxSize);
    final Size display = Size(
      widget.imageSize.width * scale,
      widget.imageSize.height * scale,
    );

    Offset toDisplay(Offset p) => Offset(p.dx * scale, p.dy * scale);
    Offset toImage(Offset p) => Offset(p.dx / scale, p.dy / scale);

    return Center(
      child: SizedBox(
        width: display.width,
        height: display.height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
            ),
            CustomPaint(
              size: display,
              painter: _QuadPainter(
                points: _localQuad.points.map(toDisplay).toList(),
              ),
            ),
            for (int i = 0; i < 4; i++)
              _CornerHandle(
                offset: toDisplay(_localQuad.points[i]),
                onDrag: (Offset local) {
                  final List<Offset> next = List<Offset>.from(_localQuad.points);
                  next[i] = Offset(
                    toImage(local).dx.clamp(0, widget.imageSize.width),
                    toImage(local).dy.clamp(0, widget.imageSize.height),
                  );
                  final ScanQuad updated = ScanQuad(
                    topLeft: next[0],
                    topRight: next[1],
                    bottomRight: next[2],
                    bottomLeft: next[3],
                  );
                  setState(() => _localQuad = updated);
                  widget.onQuadChanged(updated);
                },
              ),
          ],
        ),
      ),
    );
  }

  double _fitScale(Size image, Size max) {
    final double sx = max.width / image.width;
    final double sy = max.height / image.height;
    return sx < sy ? sx : sy;
  }
}

class _CornerHandle extends StatelessWidget {
  const _CornerHandle({required this.offset, required this.onDrag});

  final Offset offset;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    const double size = 32;
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (DragUpdateDetails d) => onDrag(offset + d.delta),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00D2A0), width: 3.0),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  const _QuadPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;
    final Path path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    final Paint stroke = Paint()
      ..color = const Color(0xFF00D2A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) => true;
}
