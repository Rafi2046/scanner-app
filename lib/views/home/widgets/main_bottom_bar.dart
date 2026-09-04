import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Light bottom nav with center gap for the camera FAB.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(
          top: BorderSide(color: AppTheme.cardBorder),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppConstants.bottomBarHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.folder_outlined,
                  label: 'Files',
                  selected: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
              ),
              const SizedBox(width: AppConstants.fabSize),
              Expanded(
                child: _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tools',
                  selected: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Account',
                  selected: selectedIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
              ),
            ],
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
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        selected ? AppTheme.primary : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
