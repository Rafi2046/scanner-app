import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/providers/auth_state.dart';
import 'package:scanner_app/views/home/widgets/glass_bottom_sheet.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

/// Opens the glassmorphic settings modal sheet.
void showSettingsGlassSheet(BuildContext context) {
  showGlassBottomSheet<void>(
    context: context,
    title: 'Settings & Security',
    child: const _SettingsSheetContent(),
  );
}

class _SettingsSheetContent extends ConsumerWidget {
  const _SettingsSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F3F5), width: 1),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              title: const Text(
                'Biometric App Lock',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
              ),
              subtitle: Text(
                auth.isAvailable
                    ? 'Require Face ID / Fingerprint to open'
                    : 'Biometrics unavailable on this device',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              activeTrackColor: const Color(0xFF4F46E5),
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
          const SizedBox(height: 14),
          // Privacy Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% Offline & Private. Documents never leave this device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
