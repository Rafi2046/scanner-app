import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Center docked camera shutter FAB.
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
    return SizedBox(
      width: AppConstants.fabSize,
      height: AppConstants.fabSize,
      child: FloatingActionButton(
        onPressed: enabled ? onPressed : null,
        elevation: 4,
        backgroundColor: enabled ? AppTheme.primary : AppTheme.textSecondary,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
