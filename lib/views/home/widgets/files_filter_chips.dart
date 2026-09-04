import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Horizontal category filter chips for the Files library tab.
class FilesFilterChips extends StatelessWidget {
  const FilesFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const List<String> categories = <String>[
    'All',
    'Scans',
    'ID Cards',
    'Imported',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spaceSm),
        itemBuilder: (BuildContext context, int index) {
          final String cat = categories[index];
          final bool isSelected = selectedFilter == cat;

          return InkWell(
            onTap: () => onFilterChanged(cat),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
