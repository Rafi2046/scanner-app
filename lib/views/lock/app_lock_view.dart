import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/providers/auth_provider.dart';
import 'package:scanner_app/core/utils/error_message.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// Full-screen gate shown while [AuthState.isLocked] is true.
class AppLockView extends ConsumerWidget {
  const AppLockView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 72),
                const SizedBox(height: 24),
                Text(
                  'Scanner is locked',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use biometrics or your device PIN to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Unlock',
                  onPressed: () async {
                    try {
                      await ref.read(authNotifierProvider.notifier).unlock();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(appErrorMessage(error))),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
