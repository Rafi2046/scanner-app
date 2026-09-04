import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Frosted glass 4-tab bottom navigation bar with a center gap for camera FAB.
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF12151C).withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavItem(
                    icon: Icons.folder_rounded,
                    label: 'Files',
                    isSelected: selectedIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  const SizedBox(width: 64), // Gap for center Camera FAB
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Tools',
                    isSelected: selectedIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Me',
                    isSelected: selectedIndex == 3,
                    onTap: () => onTabSelected(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isSelected ? AppTheme.primaryMint : const Color(0xFF8C93A0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
