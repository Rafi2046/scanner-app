import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Horizontal privilege and limit chips on the Me / Profile tab.
class MePrivilegeChips extends StatelessWidget {
  const MePrivilegeChips({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: _PrivilegeCard(
            icon: Icons.pages_rounded,
            title: '${AppConstants.documentPageLimit} Pages',
            subtitle: 'Max per scan',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _PrivilegeCard(
            icon: Icons.badge_outlined,
            title: '${AppConstants.idCardPageLimit} P / side',
            subtitle: 'ID card limits',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _PrivilegeCard(
            icon: Icons.compress_rounded,
            title: '${AppConstants.compressJpegQuality}% Quality',
            subtitle: 'PDF optimize',
          ),
        ),
      ],
    );
  }
}

class _PrivilegeCard extends StatelessWidget {
  const _PrivilegeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 20, color: AppTheme.primaryMint),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
