import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom action bar for Enhance view with custom signature styling.
class ScanEnhanceBottomBar extends StatelessWidget {
  const ScanEnhanceBottomBar({
    super.key,
    required this.onRetake,
    required this.onRotateLeft,
    required this.onCrop,
    required this.onExtractText,
    required this.onSign,
    required this.onConfirm,
    this.busy = false,
  });

  final VoidCallback onRetake;
  final VoidCallback onRotateLeft;
  final VoidCallback onCrop;
  final VoidCallback onExtractText;
  final VoidCallback onSign;
  final VoidCallback onConfirm;
  final bool busy;

  static const Color accent = Color(0xFF00D2A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14171C),
        border: Border(
          top: BorderSide(color: Color(0xFF22262F), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                icon: Icons.rotate_left_rounded,
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
                icon: Icons.document_scanner_outlined,
                label: 'OCR Text',
                badge: 'AI',
                badgeColor: accent,
                onTap: busy ? null : onExtractText,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                icon: Icons.draw_outlined,
                label: 'Sign',
                onTap: busy ? null : onSign,
              ),
            ),
            const SizedBox(width: 8),
            // Glowing Confirm Checkmark Button with large touch target
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: busy ? null : onConfirm,
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.white.withValues(alpha: 0.3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF00E6B0),
                        Color(0xFF00B388),
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
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF0F141A),
                            size: 26,
                          ),
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
        borderRadius: BorderRadius.circular(10),
        splashColor: const Color(0xFF00D2A0).withValues(alpha: 0.25),
        highlightColor: const Color(0xFF00D2A0).withValues(alpha: 0.12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
                    size: 22,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -10,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? Colors.white70 : Colors.white24,
                  fontSize: 10,
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
