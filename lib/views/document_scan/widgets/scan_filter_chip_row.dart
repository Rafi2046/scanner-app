import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

class ScanFilterChipRow extends StatelessWidget {
  const ScanFilterChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ScanFilter selected;
  final ValueChanged<ScanFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
      child: Row(
        children: <Widget>[
          for (final ScanFilter filter in ScanFilter.values) ...<Widget>[
            _FilterChip(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            const SizedBox(width: AppConstants.spaceSm),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : const Color(0xFF1A1D24),
      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
            vertical: AppConstants.spaceMd,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
