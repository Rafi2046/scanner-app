import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clean, minimalist, and ultra-responsive bottom action toolbar for Enhance view.
/// Perfectly proportioned to prevent overflow on narrow screens while maintaining
/// CamScanner Pro elegance and tactile micro-interactions.
class ScanEnhanceBottomBar extends StatelessWidget {
  const ScanEnhanceBottomBar({
    super.key,
    required this.onRetake,
    required this.onRotateLeft,
    required this.onCrop,
    required this.onExtractText,
    required this.onSign,
    required this.onConfirm,
    this.pageCount = 1,
    this.busy = false,
  });

  final VoidCallback onRetake;
  final VoidCallback onRotateLeft;
  final VoidCallback onCrop;
  final VoidCallback onExtractText;
  final VoidCallback onSign;
  final VoidCallback onConfirm;
  final int pageCount;
  final bool busy;

  static const Color accent = Color(0xFF00D2A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _ToolbarAction(
                icon: Icons.replay_rounded,
                label: 'Retake',
                onTap: busy ? null : onRetake,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                icon: Icons.rotate_right_rounded,
                label: 'Rotate',
                onTap: busy ? null : onRotateLeft,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                icon: Icons.crop_rounded,
                label: 'Crop',
                onTap: busy ? null : onCrop,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                icon: Icons.document_scanner_rounded,
                label: 'OCR',
                badge: 'AI',
                badgeColor: accent,
                onTap: busy ? null : onExtractText,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                icon: Icons.draw_rounded,
                label: 'Sign',
                onTap: busy ? null : onSign,
              ),
            ),
            const SizedBox(width: 6),

            // Clean, non-bulky checkmark save button with optional page counter badge
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: busy
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onConfirm();
                      },
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.white.withValues(alpha: 0.25),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF00E5A3),
                        Color(0xFF00B078),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      if (busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Color(0xFF07120E),
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF07120E),
                          size: 24,
                        ),

                      // Multi-page count badge
                      if (!busy && pageCount > 1)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2028),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accent, width: 1.0),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Center(
                              child: Text(
                                '$pageCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF00D2A0).withValues(alpha: 0.15),
        highlightColor: const Color(0xFF00D2A0).withValues(alpha: 0.08),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    icon,
                    color: enabled ? Colors.white : Colors.white38,
                    size: 19,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? Colors.white70 : Colors.white24,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
