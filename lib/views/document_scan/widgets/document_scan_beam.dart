import 'package:flutter/material.dart';

/// Sweeping laser beam scan animation for the cropped document.
class DocumentScanBeam extends StatefulWidget {
  const DocumentScanBeam({
    super.key,
    required this.child,
    this.autoStart = true,
    this.onCompleted,
    this.trigger,
  });

  final Widget child;
  final bool autoStart;
  final VoidCallback? onCompleted;
  final Object? trigger;

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
      duration: const Duration(milliseconds: 1400),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
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
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        if (_active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                return CustomPaint(
                  painter: _LaserBeamPainter(
                    progress: _progressAnim.value,
                    opacity: _fadeAnim.value,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LaserBeamPainter extends CustomPainter {
  const _LaserBeamPainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  static const Color mint = Color(0xFF00D2A0);
  static const Color brightMint = Color(0xFFC7FFF0);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final double y = size.height * progress;
    const double beamHeight = 65.0;
    final double topY = (y - beamHeight).clamp(0.0, size.height);

    // 1. Trailing gradient light wash behind the laser
    final Rect trailRect = Rect.fromLTRB(0, topY, size.width, y);
    if (trailRect.height > 0) {
      final Paint trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            mint.withValues(alpha: 0.0),
            mint.withValues(alpha: 0.08 * opacity),
            mint.withValues(alpha: 0.28 * opacity),
          ],
        ).createShader(trailRect);
      canvas.drawRect(trailRect, trailPaint);
    }

    // 2. Soft outer glow around the laser line
    final Paint glowPaint = Paint()
      ..color = mint.withValues(alpha: 0.45 * opacity)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);

    // 3. Crisp main laser line
    final Paint linePaint = Paint()
      ..color = mint.withValues(alpha: 0.95 * opacity)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // 4. Ultra-bright laser core
    final Paint corePaint = Paint()
      ..color = brightMint.withValues(alpha: 0.90 * opacity)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);

    // 5. Left & right glowing emitter points
    final Paint dotPaint = Paint()
      ..color = brightMint.withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(4, y), 3.0, dotPaint);
    canvas.drawCircle(Offset(size.width - 4, y), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LaserBeamPainter old) =>
      old.progress != progress || old.opacity != opacity;
}
