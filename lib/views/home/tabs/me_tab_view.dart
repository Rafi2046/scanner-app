import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/providers/auth_state.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

/// Tab 3: account + biometric lock.
class MeTabView extends ConsumerWidget {
  const MeTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authNotifierProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        AppConstants.spaceLg,
        AppConstants.pagePadding,
        AppConstants.bottomNavClearance,
      ),
      children: <Widget>[
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        Container(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primarySoft,
                child: Icon(Icons.person_rounded, color: AppTheme.primary),
              ),
              SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Local user',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppConstants.spaceXs),
                    Text(
                      '100% offline · files stay on device',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        const Text(
          'Security',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spaceSm),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: SwitchListTile(
            secondary: const Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.primary,
            ),
            title: const Text(
              'Biometric app lock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              auth.isAvailable
                  ? 'Lock when the app goes to background'
                  : 'Biometrics unavailable on this device',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            value: auth.isEnabled,
            onChanged: !auth.isAvailable
                ? null
                : (bool enabled) async {
                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .setEnabled(enabled);
                    } catch (error) {
                      if (context.mounted) {
                        showErrorSnackBar(context, error);
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }
}
