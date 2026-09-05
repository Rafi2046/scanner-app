import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scanner_app/models/scan_quad.dart';
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
    required this.normalizedQuad,
    required this.onBatchToggle,
  });

  final CameraController controller;
  final double aspectRatio;
  final bool isId;
  final bool isBatch;
  final ScanQuad? normalizedQuad;
  final ValueChanged<bool> onBatchToggle;

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
      duration: const Duration(milliseconds: 250),
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

    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _focusPos = null);
    });

    // Map tap to camera 0..1 normalized coordinates
    final double viewAspect = size.width / size.height;
    double nx;
    double ny;
    if (viewAspect > widget.aspectRatio) {
      final double pH = size.width / widget.aspectRatio;
      final double offY = (pH - size.height) / 2.0;
      nx = (pos.dx / size.width).clamp(0.0, 1.0);
      ny = ((pos.dy + offY) / pH).clamp(0.0, 1.0);
    } else {
      final double pW = size.height * widget.aspectRatio;
      final double offX = (pW - size.width) / 2.0;
      nx = ((pos.dx + offX) / pW).clamp(0.0, 1.0);
      ny = (pos.dy / size.height).clamp(0.0, 1.0);
    }

    try {
      if (widget.controller.value.focusPointSupported) {
        widget.controller.setFocusPoint(Offset(nx, ny));
      }
      if (widget.controller.value.exposurePointSupported) {
        widget.controller.setExposurePoint(Offset(nx, ny));
      }
    } catch (_) {}
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
                    normalizedQuad: widget.normalizedQuad,
                    isIdCard: widget.isId,
                    cameraAspectRatio: widget.aspectRatio,
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
    const Color mint = Color(0xFF00D2A0);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: mint, width: 1.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: mint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
