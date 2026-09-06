import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_batch_pill.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_document_overlay.dart';

/// Full-height camera viewfinder with live document tracking and tap-to-focus.
class ScanCameraViewfinder extends StatefulWidget {
  const ScanCameraViewfinder({
    super.key,
    required this.controller,
    required this.aspectRatio,
    required this.isId,
    required this.isBatch,
    required this.onBatchToggle,
    this.frameHint = 'Fit ID card inside the frame',
    this.onFocusTap,
  });

  final CameraController controller;
  final double aspectRatio;
  final bool isId;
  final bool isBatch;
  final ValueChanged<bool> onBatchToggle;
  final String frameHint;
  final void Function(Offset localPos, Size size)? onFocusTap;

  @override
  State<ScanCameraViewfinder> createState() => _ScanCameraViewfinderState();
}

class _ScanCameraViewfinderState extends State<ScanCameraViewfinder>
    with SingleTickerProviderStateMixin {
  Offset? _focusPos;
  late AnimationController _anim;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _onTapFocus(TapUpDetails details, Size size) {
    final Offset pos = details.localPosition;
    setState(() => _focusPos = pos);
    _anim.forward(from: 0.0);
    HapticFeedback.selectionClick();

    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _focusPos = null);
    });

    if (widget.onFocusTap != null) {
      widget.onFocusTap!(pos, size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails d) => _onTapFocus(d, size),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.width,
                      height: size.width / widget.aspectRatio,
                      child: CameraPreview(widget.controller),
                    ),
                  ),
                  ScanDocumentOverlay(
                    isIdCard: widget.isId,
                    frameHint: widget.frameHint,
                  ),
                  if (_focusPos != null)
                    Positioned(
                      left: _focusPos!.dx - 30,
                      top: _focusPos!.dy - 30,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.4, end: 1.0).animate(
                          CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
                        ),
                        child: const _FocusRing(),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ScanBatchPill(
                        isBatch: widget.isBatch,
                        onToggle: widget.onBatchToggle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FocusRing extends StatelessWidget {
  const _FocusRing();

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF00D2A0);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Outer camera target ring
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.6),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Inner focus crosshair dot
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
