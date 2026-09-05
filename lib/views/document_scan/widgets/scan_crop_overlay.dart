import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_crop_magnifier.dart';

/// Interactive draggable quad overlay with corner loupe tracking the active handle.
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
  int? _draggingIndex;

  static const Color _accent = Color(0xFF00D2A0);
  static const double _loupeSize = 136;

  @override
  void initState() {
    super.initState();
    _localQuad = widget.quad;
  }

  @override
  void didUpdateWidget(covariant ScanCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_draggingIndex == null) {
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

    final List<Offset> displayPoints =
        _localQuad.points.map(toDisplay).toList();
    final int? drag = _draggingIndex;
    final Offset? focal = drag == null ? null : displayPoints[drag];

    // Compute dynamic loupe position relative to the dragged corner
    Widget? loupeWidget;
    if (focal != null) {
      double loupeLeft = focal.dx - _loupeSize / 2;
      // Position 48px above the corner handle so user's thumb does not cover it
      double loupeTop = focal.dy - _loupeSize - 48;
      // If handle is close to the top edge, smoothly flip the loupe below the handle
      if (loupeTop < 6) {
        loupeTop = focal.dy + 46;
      }
      // Keep strictly within visible boundaries
      loupeLeft = loupeLeft.clamp(4.0, math.max(4.0, display.width - _loupeSize - 4.0));
      loupeTop = loupeTop.clamp(4.0, math.max(4.0, display.height - _loupeSize - 4.0));

      loupeWidget = Positioned(
        left: loupeLeft,
        top: loupeTop,
        child: ScanCropMagnifier(
          imagePath: widget.imagePath,
          displaySize: display,
          focalDisplay: focal,
          diameter: _loupeSize,
          magnification: 2.8,
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: display.width,
        height: display.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
            ),
            CustomPaint(
              size: display,
              painter: _QuadPainter(points: displayPoints),
            ),
            for (int i = 0; i < 4; i++)
              _CornerHandle(
                key: ValueKey<int>(i),
                offset: displayPoints[i],
                accent: _accent,
                onPanStart: () => setState(() => _draggingIndex = i),
                onPanEnd: () => setState(() => _draggingIndex = null),
                onDrag: (Offset local) {
                  final List<Offset> next =
                      List<Offset>.from(_localQuad.points);
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
            ?loupeWidget,
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

class _CornerHandle extends StatefulWidget {
  const _CornerHandle({
    super.key,
    required this.offset,
    required this.onDrag,
    required this.onPanStart,
    required this.onPanEnd,
    required this.accent,
  });

  final Offset offset;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onPanStart;
  final VoidCallback onPanEnd;
  final Color accent;

  @override
  State<_CornerHandle> createState() => _CornerHandleState();
}

class _CornerHandleState extends State<_CornerHandle> {
  Offset? _dragPos;

  @override
  Widget build(BuildContext context) {
    final Offset pos = _dragPos ?? widget.offset;
    const double visual = 34;
    const double hit = 56;
    return Positioned(
      left: pos.dx - hit / 2,
      top: pos.dy - hit / 2,
      width: hit,
      height: hit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragPos = widget.offset;
          widget.onPanStart();
        },
        onPanEnd: (_) {
          _dragPos = null;
          widget.onPanEnd();
        },
        onPanCancel: () {
          _dragPos = null;
          widget.onPanEnd();
        },
        onPanUpdate: (DragUpdateDetails d) {
          final Offset next = (_dragPos ?? widget.offset) + d.delta;
          _dragPos = next;
          widget.onDrag(next);
          setState(() {});
        },
        child: Center(
          child: Container(
            width: visual,
            height: visual,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: widget.accent, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
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
    if (points.length != 4) {
      return;
    }
    final Path path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    final Paint fill = Paint()
      ..color = const Color(0xFF00D2A0).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = const Color(0xFF00D2A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) => true;
}
