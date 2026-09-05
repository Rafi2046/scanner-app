import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

class ScanShutterButton extends StatelessWidget {
  const ScanShutterButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppTheme.cardBorder,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ScanBottomBar extends StatelessWidget {
  const ScanBottomBar({
    super.key,
    required this.child,
  });

  final Widget child;

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
        child: child,
      ),
    );
  }
}
