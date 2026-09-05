import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sweeping laser beam scan animation with real-time top-down reveal effect.
/// As the glowing laser moves from top to bottom, the new filtered document is revealed.
class DocumentScanBeam extends StatefulWidget {
  const DocumentScanBeam({
    super.key,
    required this.child,
    this.previousChild,
    this.autoStart = true,
    this.onCompleted,
    this.trigger,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Widget? previousChild;
  final bool autoStart;
  final VoidCallback? onCompleted;
  final Object? trigger;
  final Duration duration;

  @override
  State<DocumentScanBeam> createState() => _DocumentScanBeamState();
}

class _DocumentScanBeamState extends State<DocumentScanBeam>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;
  bool _active = false;

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
        if (mounted) setState(() => _active = false);
        widget.onCompleted?.call();
      }
    });

    if (widget.autoStart) {
      _startScan();
    }
  }

  void _startScan() {
    _active = true;
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant DocumentScanBeam oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double progress = _progressAnim.value;
        final double opacity = _fadeAnim.value;

        return Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            // 1. Previous document image on bottom during transition
            if (_active && widget.previousChild != null)
              widget.previousChild!
            else
              const SizedBox.shrink(),

            // 2. New filtered document revealed from top to bottom behind the laser
            if (_active && widget.previousChild != null)
              ClipRect(
                clipper: _TopDownRevealClipper(progress),
                child: widget.child,
              )
            else
              widget.child,

            // 3. Sweeping neon laser beam with light wash
            if (_active)
              Positioned.fill(
                child: CustomPaint(
                  painter: _LaserBeamPainter(
                    progress: progress,
                    opacity: opacity,
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

  static const Color mint = Color(0xFF00D2A0);
  static const Color brightMint = Color(0xFFE0FFF7);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final double y = size.height * progress;
    const double beamHeight = 70.0;
    final double topY = (y - beamHeight).clamp(0.0, size.height);

    // 1. Trailing gradient light wash behind the laser head
    final Rect trailRect = Rect.fromLTRB(0, topY, size.width, y);
    if (trailRect.height > 0) {
      final Paint trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            mint.withValues(alpha: 0.0),
            mint.withValues(alpha: 0.10 * opacity),
            mint.withValues(alpha: 0.35 * opacity),
          ],
        ).createShader(trailRect);
      canvas.drawRect(trailRect, trailPaint);
    }

    // 2. Soft outer glow around the laser line
    final Paint glowPaint = Paint()
      ..color = mint.withValues(alpha: 0.50 * opacity)
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);

    // 3. Crisp main laser line
    final Paint linePaint = Paint()
      ..color = mint.withValues(alpha: 0.95 * opacity)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 4. Ultra-bright glowing laser core
    final Paint corePaint = Paint()
      ..color = brightMint.withValues(alpha: 0.95 * opacity)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);

    // 5. Left & right emitter dots
    final Paint dotPaint = Paint()
      ..color = brightMint.withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(4, y), 3.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 4, y), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LaserBeamPainter old) =>
      old.progress != progress || old.opacity != opacity;
}
