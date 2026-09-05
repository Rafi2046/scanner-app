import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sweeping laser beam scan animation with real-time top-down reveal effect.
/// Guaranteed to fire whenever triggered, providing immediate visual scanner feedback.
class DocumentScanBeam extends StatefulWidget {
  const DocumentScanBeam({
    super.key,
    required this.imagePath,
    this.previousImagePath,
    this.trigger,
    this.duration = const Duration(milliseconds: 1350),
    this.onCompleted,
  });

  final String imagePath;
  final String? previousImagePath;
  final Object? trigger;
  final Duration duration;
  final VoidCallback? onCompleted;

  @override
  State<DocumentScanBeam> createState() => _DocumentScanBeamState();
}

class _DocumentScanBeamState extends State<DocumentScanBeam>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;

  String? _transitionFromPath;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.90, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _transitionFromPath = null;
          });
          HapticFeedback.lightImpact();
          widget.onCompleted?.call();
        }
      }
    });

    // Auto-trigger scan on initial mount so entering Enhance shows the laser scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startScan();
    });
  }

  void _startScan() {
    _transitionFromPath = widget.previousImagePath;
    _isScanning = true;
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0.0);
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant DocumentScanBeam oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // Trigger scan on either explicit trigger change or imagePath change
    if ((widget.trigger != null && widget.trigger != oldWidget.trigger) ||
        widget.imagePath != oldWidget.imagePath) {
      _startScan();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentPath = widget.imagePath;
    final String? prevPath = _transitionFromPath ?? widget.previousImagePath;
    final bool hasDistinctPrev = prevPath != null &&
        prevPath != currentPath &&
        File(prevPath).existsSync();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double progress = _progressAnim.value;
        final double opacity = _fadeAnim.value;

        return Stack(
          fit: StackFit.loose,
          alignment: Alignment.center,
          children: <Widget>[
            // 1. Base Image (Underneath document during transition)
            if (_isScanning && hasDistinctPrev)
              Image.file(
                File(prevPath),
                key: ValueKey<String>('scan_prev_$prevPath'),
                fit: BoxFit.contain,
              )
            else
              Image.file(
                File(currentPath),
                key: ValueKey<String>('scan_curr_$currentPath'),
                fit: BoxFit.contain,
              ),

            // 2. Revealed Image (Top-Down Wipe behind the laser)
            if (_isScanning && hasDistinctPrev)
              Positioned.fill(
                child: ClipRect(
                  clipper: _TopDownRevealClipper(progress),
                  child: Image.file(
                    File(currentPath),
                    key: ValueKey<String>('scan_revealed_$currentPath'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // 3. Sweeping High-Tech Laser Beam with Scanner Bed Wash
            if (_isScanning)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LaserBeamPainter(
                      progress: progress,
                      opacity: opacity,
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

class _TopDownRevealClipper extends CustomClipper<Rect> {
  _TopDownRevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height * progress);
  }

  @override
  bool shouldReclip(covariant _TopDownRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _LaserBeamPainter extends CustomPainter {
  const _LaserBeamPainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  static const Color mintAccent = Color(0xFF00E5A3);
  static const Color cyanAura = Color(0xFF00D2FF);
  static const Color pureWhite = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.height <= 0 || size.width <= 0) return;

    // Laser sweeps smoothly down the document
    final double y = (size.height * progress).clamp(0.0, size.height);
    const double beamTrailHeight = 120.0;
    final double topY = (y - beamTrailHeight).clamp(0.0, size.height);

    // 1. Scanner Bed Optical Light Sheet (Trailing illuminated gradient wash)
    final Rect trailRect = Rect.fromLTRB(0, topY, size.width, y);
    if (trailRect.height > 0) {
      final Paint trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            mintAccent.withValues(alpha: 0.0),
            mintAccent.withValues(alpha: 0.06 * opacity),
            mintAccent.withValues(alpha: 0.20 * opacity),
            mintAccent.withValues(alpha: 0.50 * opacity),
          ],
          stops: const <double>[0.0, 0.35, 0.70, 1.0],
        ).createShader(trailRect);
      canvas.drawRect(trailRect, trailPaint);

      // Subtle vertical optical scanline highlights inside the light wash
      final Paint rayPaint = Paint()
        ..color = pureWhite.withValues(alpha: 0.09 * opacity)
        ..strokeWidth = 1.2;
      final double step = size.width / 10;
      for (double x = step; x < size.width; x += step) {
        canvas.drawLine(
          Offset(x, y - (trailRect.height * 0.45)),
          Offset(x, y),
          rayPaint,
        );
      }
    }

    // 2. Forward Light Fringe (Soft ambient glow 16px ahead of the laser)
    final double bottomY = (y + 16.0).clamp(0.0, size.height);
    final Rect forwardRect = Rect.fromLTRB(0, y, size.width, bottomY);
    if (forwardRect.height > 0) {
      final Paint forwardPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            mintAccent.withValues(alpha: 0.25 * opacity),
            mintAccent.withValues(alpha: 0.0),
          ],
        ).createShader(forwardRect);
      canvas.drawRect(forwardRect, forwardPaint);
    }

    // 3. Wide Diffuse Ambient Laser Aura
    final Paint wideAuraPaint = Paint()
      ..color = cyanAura.withValues(alpha: 0.40 * opacity)
      ..strokeWidth = 16.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), wideAuraPaint);

    // 4. Vibrant Mint Glow Bar
    final Paint neonGlowPaint = Paint()
      ..color = mintAccent.withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), neonGlowPaint);

    // 5. Intense Solid Laser Line
    final Paint linePaint = Paint()
      ..color = mintAccent.withValues(alpha: 0.98 * opacity)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 6. Ultra-Bright White Hot Core Line
    final Paint corePaint = Paint()
      ..color = pureWhite.withValues(alpha: 0.98 * opacity)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);

    // 7. Left & Right Optical Scanner Head Emitters & Corner Brackets
    _drawEmitterHead(canvas, x: 0, y: y, isLeft: true);
    _drawEmitterHead(canvas, x: size.width, y: y, isLeft: false);
  }

  void _drawEmitterHead(
    Canvas canvas, {
    required double x,
    required double y,
    required bool isLeft,
  }) {
    final double dir = isLeft ? 1.0 : -1.0;

    // Glowing halo
    final Paint haloPaint = Paint()
      ..color = mintAccent.withValues(alpha: 0.70 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(Offset(x + dir * 6, y), 8.0, haloPaint);

    // High-tech scanner bracket [ or ]
    final Path bracket = Path();
    final double bx = x + dir * 14;
    bracket.moveTo(bx, y - 10);
    bracket.lineTo(x + dir * 3, y - 10);
    bracket.lineTo(x + dir * 3, y + 10);
    bracket.lineTo(bx, y + 10);

    final Paint bracketPaint = Paint()
      ..color = pureWhite.withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(bracket, bracketPaint);

    // Bright central emitter pin
    final Paint pinPaint = Paint()
      ..color = pureWhite.withValues(alpha: 0.98 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x + dir * 3, y), 3.5, pinPaint);
  }

  @override
  bool shouldRepaint(covariant _LaserBeamPainter old) => true;
}
