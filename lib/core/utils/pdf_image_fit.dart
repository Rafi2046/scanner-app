import 'dart:math' as math;
import 'dart:ui';

/// Geometry helpers for drawing images into PDF pages while preserving aspect ratio.
abstract final class PdfImageFit {
  /// ISO A4 in PDF points (1/72 inch).
  static const Size a4 = Size(595.28, 841.89);

  /// Scales [imageSize] to fit inside [slot], then centers it.
  static Rect containCentered({
    required Size imageSize,
    required Rect slot,
  }) {
    if (imageSize.width <= 0 || imageSize.height <= 0 || slot.isEmpty) {
      return slot;
    }

    final double scale = math.min(
      slot.width / imageSize.width,
      slot.height / imageSize.height,
    );
    final double fittedWidth = imageSize.width * scale;
    final double fittedHeight = imageSize.height * scale;

    return Rect.fromLTWH(
      slot.left + (slot.width - fittedWidth) / 2,
      slot.top + (slot.height - fittedHeight) / 2,
      fittedWidth,
      fittedHeight,
    );
  }

  /// Two equal vertical slots on A4 for front (top) and back (bottom) ID sides.
  static ({Rect frontSlot, Rect backSlot}) idCardSlots({
    required Size pageSize,
    required double margin,
    required double gap,
  }) {
    final double contentWidth = pageSize.width - (margin * 2);
    final double contentHeight = pageSize.height - (margin * 2);
    final double slotHeight = (contentHeight - gap) / 2;

    final Rect frontSlot = Rect.fromLTWH(
      margin,
      margin,
      contentWidth,
      slotHeight,
    );
    final Rect backSlot = Rect.fromLTWH(
      margin,
      margin + slotHeight + gap,
      contentWidth,
      slotHeight,
    );

    return (frontSlot: frontSlot, backSlot: backSlot);
  }
}
