import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/providers/auth_state.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authNotifierProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Settings'),
              ),
            ),
            SwitchListTile(
              title: const Text('Biometric app lock'),
              subtitle: Text(
                auth.isAvailable
                    ? 'Lock when the app goes to the background'
                    : 'Biometrics are not available on this device',
              ),
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
          ],
        ),
      ),
    );
  }
}
