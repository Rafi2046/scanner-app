import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Modern custom header with dynamic greeting, brand badge, and search bar.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenSettings,
    this.onClearSearch,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback? onClearSearch;

  static String _getGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Top Greeting Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: AppTheme.primaryMint,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Scanner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryMint,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Settings & Security',
              icon: const Icon(
                Icons.settings_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              onPressed: onOpenSettings,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder, width: 1),
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search documents...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                        if (onClearSearch != null) onClearSearch!();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
