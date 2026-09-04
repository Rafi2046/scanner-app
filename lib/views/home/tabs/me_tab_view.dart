import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/providers/auth_state.dart';
import 'package:scanner_app/views/home/widgets/me_privilege_chips.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

/// Tab 3: Me / Profile & App Settings.
class MeTabView extends ConsumerWidget {
  const MeTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authNotifierProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: <Widget>[
        // Profile Header
        Row(
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryMint.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.primaryMint, width: 1.5),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryMint,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Rafi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Text(
                    'Offline Pro',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryMint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Offline Security Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.shield_rounded, color: AppTheme.primaryMint, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '100% Private. Scans & signatures never leave your local device.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const MePrivilegeChips(),
        const SizedBox(height: 20),
        // Settings Section
        const Text(
          'Security & Settings',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: SwitchListTile(
            secondary: const Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.primaryMint,
            ),
            title: const Text(
              'Biometric App Lock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              auth.isAvailable
                  ? 'Require biometric auth to unlock app'
                  : 'Biometrics unavailable on this device',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            activeTrackColor: AppTheme.primaryMint,
            value: auth.isEnabled,
            onChanged: !auth.isAvailable
                ? null
                : (bool enabled) async {
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .setEnabled(enabled);
                    } catch (error) {
                      if (context.mounted) showErrorSnackBar(context, error);
                    }
                  },
          ),
        ),
      ],
    );
  }
}
