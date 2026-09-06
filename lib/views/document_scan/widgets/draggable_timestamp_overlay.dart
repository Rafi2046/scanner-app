import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/models/timestamp_config.dart';
import 'package:scanner_app/providers/timestamp_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/edit_timestamp_bottom_sheet.dart';
import 'package:scanner_app/views/document_scan/widgets/timestamp_overlay_card.dart';

/// Interactive draggable & resizable overlay for camera timestamp.
///
/// Implemented as a full-viewport hit-test overlay so all interactive controls
/// (drag card, corner resize handle, floating [-] and [+] scale toolbar)
/// receive 100% of touches cleanly without leaking taps to camera autofocus.
class DraggableTimestampOverlay extends ConsumerStatefulWidget {
  const DraggableTimestampOverlay({
    super.key,
    required this.viewportSize,
  });

  final Size viewportSize;

  @override
  ConsumerState<DraggableTimestampOverlay> createState() => _DraggableTimestampOverlayState();
}

class _DraggableTimestampOverlayState extends ConsumerState<DraggableTimestampOverlay> {
  final GlobalKey _cardKey = GlobalKey();
  Size _cachedCardSize = const Size(220, 80);

  // Local interaction states for 120fps fluid response
  late double _currentX;
  late double _currentY;
  late double _currentScale;

  bool _isInteracting = false;
  bool _isResizing = false;
  final bool _showControls = true;

  // Pan / Scale tracking
  Offset _startFocalPoint = Offset.zero;
  double _startX = 0.0;
  double _startY = 0.0;
  double _startScale = 1.0;
  int _prevPointerCount = 1;
  double _dragDistance = 0.0;

  // Single-finger corner resize tracking
  Offset _resizeStartPos = Offset.zero;
  double _resizeStartScale = 1.0;

  @override
  void initState() {
    super.initState();
    final TimestampConfig config = ref.read(timestampConfigProvider);
    _currentScale = config.scale.clamp(0.65, 1.80);
    _currentX = config.positionRatio.dx * widget.viewportSize.width;
    _currentY = config.positionRatio.dy * widget.viewportSize.height;
  }

  @override
  void didUpdateWidget(covariant DraggableTimestampOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInteracting && !_isResizing) {
      final TimestampConfig config = ref.read(timestampConfigProvider);
      _currentScale = config.scale.clamp(0.65, 1.80);
      _currentX = config.positionRatio.dx * widget.viewportSize.width;
      _currentY = config.positionRatio.dy * widget.viewportSize.height;
    }
  }

  Size _getCardSize() {
    final RenderBox? box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 20) {
      _cachedCardSize = box.size;
      return box.size;
    }
    return _cachedCardSize;
  }

  void _commitPositionAndScale() {
    final double ratioX = (_currentX / widget.viewportSize.width).clamp(0.0, 1.0);
    final double ratioY = (_currentY / widget.viewportSize.height).clamp(0.0, 1.0);

    ref.read(timestampConfigProvider.notifier).setPositionRatio(Offset(ratioX, ratioY));
    ref.read(timestampConfigProvider.notifier).setScale(_currentScale);
  }

  // --- 1-FINGER DRAG & 2-FINGER PINCH ON CARD BODY ---

  void _handleScaleStart(ScaleStartDetails details) {
    _isInteracting = true;
    _startFocalPoint = details.focalPoint;
    _startX = _currentX;
    _startY = _currentY;
    _startScale = _currentScale;
    _prevPointerCount = details.pointerCount;
    _dragDistance = 0.0;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // If pointer count changed (1 finger <-> 2 fingers), re-anchor focal point to avoid jumps
    if (details.pointerCount != _prevPointerCount) {
      _startFocalPoint = details.focalPoint;
      _startX = _currentX;
      _startY = _currentY;
      _startScale = _currentScale;
      _prevPointerCount = details.pointerCount;
      return;
    }

    final Offset delta = details.focalPoint - _startFocalPoint;
    _dragDistance += delta.distance;

    final Size unscaled = _getCardSize();

    if (details.pointerCount > 1) {
      // 2-finger pinch scaling
      final double nextScale = (_startScale * details.scale).clamp(0.65, 1.80);
      final double visualW = unscaled.width * nextScale;
      final double visualH = unscaled.height * nextScale;
      final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
      final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

      _currentScale = nextScale;
      _currentX = _currentX.clamp(4.0, maxLeft);
      _currentY = _currentY.clamp(4.0, maxTop);
    } else {
      // 1-finger smooth translation (drag anywhere on screen)
      final double visualW = unscaled.width * _currentScale;
      final double visualH = unscaled.height * _currentScale;
      final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
      final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

      _currentX = (_startX + delta.dx).clamp(4.0, maxLeft);
      _currentY = (_startY + delta.dy).clamp(4.0, maxTop);
    }

    setState(() {});
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _isInteracting = false;
    _commitPositionAndScale();

    // If it was just a quick static tap without drag, open edit sheet
    if (_dragDistance < 8.0) {
      EditTimestampBottomSheet.show(context);
    }
    setState(() {});
  }

  // --- SINGLE-FINGER CORNER RESIZE HANDLE ---

  void _handleResizeStart(DragStartDetails details) {
    _isResizing = true;
    _resizeStartPos = details.globalPosition;
    _resizeStartScale = _currentScale;
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    final double dx = details.globalPosition.dx - _resizeStartPos.dx;
    final double dy = details.globalPosition.dy - _resizeStartPos.dy;

    // Dragging down-right expands; dragging up-left shrinks
    final double delta = (dx + dy) / 2.0;
    final double nextScale = (_resizeStartScale + (delta / 220.0)).clamp(0.65, 1.80);

    final Size unscaled = _getCardSize();
    final double visualW = unscaled.width * nextScale;
    final double visualH = unscaled.height * nextScale;

    final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
    final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

    setState(() {
      _currentScale = nextScale;
      _currentX = _currentX.clamp(4.0, maxLeft);
      _currentY = _currentY.clamp(4.0, maxTop);
    });
  }

  void _handleResizeEnd(DragEndDetails details) {
    _isResizing = false;
    _commitPositionAndScale();
    setState(() {});
  }

  // --- MINI QUICK SCALE CONTROLS (ONE-HAND OPERATION) ---

  void _adjustScale(double step) {
    HapticFeedback.selectionClick();
    final double nextScale = (_currentScale + step).clamp(0.65, 1.80);
    final Size unscaled = _getCardSize();
    final double visualW = unscaled.width * nextScale;
    final double visualH = unscaled.height * nextScale;

    final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
    final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

    setState(() {
      _currentScale = nextScale;
      _currentX = _currentX.clamp(4.0, maxLeft);
      _currentY = _currentY.clamp(4.0, maxTop);
    });
    _commitPositionAndScale();
  }

  void _resetScale() {
    HapticFeedback.selectionClick();
    final Size unscaled = _getCardSize();
    final double visualW = unscaled.width * 1.0;
    final double visualH = unscaled.height * 1.0;

    final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
    final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

    setState(() {
      _currentScale = 1.0;
      _currentX = _currentX.clamp(4.0, maxLeft);
      _currentY = _currentY.clamp(4.0, maxTop);
    });
    _commitPositionAndScale();
  }

  @override
  Widget build(BuildContext context) {
    final TimestampConfig config = ref.watch(timestampConfigProvider);

    if (!_isInteracting && !_isResizing) {
      _currentScale = config.scale.clamp(0.65, 1.80);
      _currentX = config.positionRatio.dx * widget.viewportSize.width;
      _currentY = config.positionRatio.dy * widget.viewportSize.height;
    }

    final Size unscaled = _getCardSize();
    final double visualW = unscaled.width * _currentScale;
    final double visualH = unscaled.height * _currentScale;

    final double maxLeft = math.max(4.0, widget.viewportSize.width - visualW - 4.0);
    final double maxTop = math.max(4.0, widget.viewportSize.height - visualH - 4.0);

    final double clampedX = _currentX.clamp(4.0, maxLeft);
    final double clampedY = _currentY.clamp(4.0, maxTop);

    // Calculate toolbar position: above card if space permits, otherwise below card
    const double toolbarW = 224.0;
    const double toolbarH = 38.0;
    final double cardCenterX = clampedX + (visualW / 2.0);
    final double toolbarX = (cardCenterX - (toolbarW / 2.0)).clamp(
      8.0,
      math.max(8.0, widget.viewportSize.width - toolbarW - 8.0),
    );
    final double toolbarY = clampedY >= (toolbarH + 10.0)
        ? (clampedY - toolbarH - 6.0)
        : (clampedY + visualH + 8.0);

    final double handleX = (clampedX + visualW - 14.0).clamp(
      4.0,
      widget.viewportSize.width - 32.0,
    );
    final double handleY = (clampedY + visualH - 14.0).clamp(
      4.0,
      widget.viewportSize.height - 32.0,
    );

    final bool activeHighlight = _isInteracting || _isResizing || _showControls;

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 1. The Main Timestamp Card
          Positioned(
            left: clampedX,
            top: clampedY,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                EditTimestampBottomSheet.show(context);
              },
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeHighlight ? const Color(0xFF00C292) : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: activeHighlight
                      ? <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF00C292).withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Transform.scale(
                  scale: _currentScale,
                  alignment: Alignment.topLeft,
                  child: TimestampOverlayCard(
                    key: _cardKey,
                    config: config,
                  ),
                ),
              ),
            ),
          ),

          // 2. Corner Resize Handle (1-finger drag resize!)
          if (activeHighlight)
            Positioned(
              left: handleX,
              top: handleY,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _handleResizeStart,
                onPanUpdate: _handleResizeUpdate,
                onPanEnd: _handleResizeEnd,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C292),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.open_in_full,
                      size: 13,
                      color: Color(0xFF052016),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Mini Floating Scale Toolbar for 1-hand operation (+ / - / Reset / Settings)
          // Positioned within the viewport so all taps are 100% intercepted and never trigger camera focus!
          if (activeHighlight)
            Positioned(
              left: toolbarX,
              top: toolbarY,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00C292), width: 1.2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Minus button (smaller)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _adjustScale(-0.1),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.minus, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scale percentage
                    Text(
                      '${(_currentScale * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF00C292),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Plus button (bigger)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _adjustScale(0.1),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.plus, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 16, color: Colors.white24),
                    const SizedBox(width: 8),
                    // Reset to 100%
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _resetScale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit Sheet
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        EditTimestampBottomSheet.show(context);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C292).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.sliders, size: 14, color: Color(0xFF00C292)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
