import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Premium dark-scan action strip for crop (icons + teal confirm).
class ScanCropActionBar extends StatelessWidget {
  const ScanCropActionBar({
    super.key,
    required this.onRetake,
    required this.onAutoCrop,
    required this.onConfirm,
    this.busy = false,
  });

  final VoidCallback? onRetake;
  final VoidCallback? onAutoCrop;
  final VoidCallback? onConfirm;
  final bool busy;

  static const Color _teal = Color(0xFF00D2A0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          AppConstants.spaceSm,
          AppConstants.pagePadding,
          AppConstants.spaceLg,
        ),
        child: Row(
          children: <Widget>[
            _ToolButton(
              icon: LucideIcons.camera,
              label: 'Retake',
              onTap: busy ? null : onRetake,
            ),
            const SizedBox(width: AppConstants.spaceSm),
            _ToolButton(
              icon: LucideIcons.scan,
              label: 'Auto',
              onTap: busy ? null : onAutoCrop,
            ),
            const Spacer(),
            Material(
              color: busy ? const Color(0xFF2A2F3A) : _teal,
              borderRadius: BorderRadius.circular(16),
              elevation: busy ? 0 : 4,
              shadowColor: _teal.withValues(alpha: 0.45),
              child: InkWell(
                onTap: busy ? null : onConfirm,
                borderRadius: BorderRadius.circular(16),
                child: const SizedBox(
                  width: 58,
                  height: 58,
                  child: Icon(
                    LucideIcons.check,
                    color: Color(0xFF0B1220),
                    size: 28,
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

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: const Color(0xFF1A1D24),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 76,
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: enabled ? Colors.white : Colors.white38,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.white70 : Colors.white30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
