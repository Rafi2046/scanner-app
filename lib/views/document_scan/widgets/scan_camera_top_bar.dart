import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Top utility bar for the immersive camera scanner.
class ScanCameraTopBar extends StatelessWidget {
  const ScanCameraTopBar({
    super.key,
    required this.onClose,
    required this.flashMode,
    required this.onFlashToggle,
    this.onFilterTap,
    this.onMoreTap,
  });

  final VoidCallback onClose;
  final FlashMode flashMode;
  final VoidCallback onFlashToggle;
  final VoidCallback? onFilterTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final bool isFlashOn =
        flashMode == FlashMode.torch || flashMode == FlashMode.always;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceSm,
        vertical: AppConstants.spaceXs,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
            tooltip: 'Close',
          ),
          const Spacer(),
          IconButton(
            onPressed: onFlashToggle,
            icon: Icon(
              isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
              color: isFlashOn ? const Color(0xFF00D2A0) : Colors.white,
              size: 22,
            ),
            tooltip: 'Toggle Flash',
          ),
          const SizedBox(width: AppConstants.spaceXs),
          _BadgeIcon(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 1.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spaceXs),
          _BadgeIcon(
            onTap: onFilterTap ?? () {},
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 21),
          ),
          const SizedBox(width: AppConstants.spaceXs),
          IconButton(
            onPressed: onMoreTap ?? () {},
            icon: const Icon(LucideIcons.moreHorizontal, color: Colors.white, size: 22),
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            Positioned(
              top: -2,
              right: -3,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A00),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
