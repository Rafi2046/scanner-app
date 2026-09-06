import 'package:flutter/material.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Available modes in the horizontal camera tab bar.
enum ScanTabMode {
  timestamp('Timestamp'),
  text('Extract Text'),
  idCards('ID Cards'),
  scan('Scan'),
  sign('Sign'),
  toWord('To Word'),
  questionSet('Question Set');

  const ScanTabMode(this.label);
  final String label;
}

/// Horizontal mode selector matching the reference image.
class ScanModeCarousel extends StatelessWidget {
  const ScanModeCarousel({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final ScanTabMode selectedMode;
  final ValueChanged<ScanTabMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ScanTabMode.values.map((ScanTabMode mode) {
            final bool isSelected = mode == selectedMode;
            return _ModeItem(
              label: mode.label,
              isSelected: isSelected,
              onTap: () => onModeSelected(mode),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF00D2A0);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
