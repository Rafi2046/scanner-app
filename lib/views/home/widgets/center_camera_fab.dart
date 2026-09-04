import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Elevated circular Camera Shutter Action Button for the center of Bottom Bar.
class CenterCameraFab extends StatelessWidget {
  const CenterCameraFab({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: enabled
                ? const LinearGradient(
                    colors: <Color>[AppTheme.primaryMint, AppTheme.primaryTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: <Color>[Color(0xFF4B5563), Color(0xFF6B7280)],
                  ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: enabled
                    ? AppTheme.primaryMint.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onPressed : null,
              splashColor: Colors.white.withValues(alpha: 0.3),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Scan',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryMint,
          ),
        ),
      ],
    );
  }
}
