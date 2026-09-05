import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Bottom control bar featuring:
/// - Left: All Features grid button
/// - Center: Large mint-ring shutter button
/// - Right: Gallery/Photos import button
class ScanShutterBar extends StatelessWidget {
  const ScanShutterBar({
    super.key,
    required this.enabled,
    required this.onShutter,
    required this.onAllFeatures,
    required this.onGallery,
  });

  final bool enabled;
  final VoidCallback onShutter;
  final VoidCallback onAllFeatures;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.pagePadding,
        vertical: AppConstants.spaceMd,
      ),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: All Features (Grid icon)
            IconButton(
              onPressed: onAllFeatures,
              icon: const Icon(
                LucideIcons.layoutGrid,
                color: Colors.white,
                size: 26,
              ),
              tooltip: 'All Features',
            ),

            // Center: Glowing mint shutter button
            _ShutterRingButton(
              enabled: enabled,
              onPressed: onShutter,
            ),

            // Right: Gallery / Photos picker
            IconButton(
              onPressed: enabled ? onGallery : null,
              icon: const Icon(
                LucideIcons.image,
                color: Colors.white,
                size: 26,
              ),
              tooltip: 'Import from Photos',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutterRingButton extends StatefulWidget {
  const _ShutterRingButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ShutterRingButton> createState() => _ShutterRingButtonState();
}

class _ShutterRingButtonState extends State<_ShutterRingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const Color mint = Color(0xFF00D2A0);

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: mint, width: 3.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: mint.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
