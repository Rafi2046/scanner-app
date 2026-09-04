import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Brand row + search field for the Home tab.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenSettings,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: AppConstants.logoSize,
              height: AppConstants.logoSize,
              decoration: const BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spaceSm),
            const Expanded(
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Search focus',
              onPressed: () {},
              icon: const Icon(
                Icons.search_rounded,
                color: AppTheme.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'Account',
              onPressed: onOpenSettings,
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceMd),
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search files…',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
              vertical: AppConstants.spaceMd,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppTheme.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
