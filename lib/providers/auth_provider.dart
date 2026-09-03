import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/providers/auth_state.dart';
import 'package:scanner_app/providers/service_providers.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  AppLifecycleListener? _lifecycle;

  @override
  AuthState build() {
    _lifecycle = AppLifecycleListener(
      onHide: _lockIfEnabled,
      onPause: _lockIfEnabled,
    );
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    Future<void>.microtask(_hydrate);
    return const AuthState();
  }

  Future<void> _hydrate() async {
    try {
      final bool enabled =
          await ref.read(authServiceProvider).getLockEnabled();
      final bool available =
          await ref.read(authServiceProvider).isBiometricAvailable();
      state = AuthState(
        isEnabled: enabled,
        isAvailable: available,
        isLocked: enabled,
      );
    } catch (_) {
      state = const AuthState();
    }
  }

  void _lockIfEnabled() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  Future<void> unlock() async {
    final bool ok = await _prompt(
      reason: 'Unlock Scanner',
    );
    if (ok) {
      state = state.copyWith(isLocked: false);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      if (!state.isAvailable) {
        throw const AuthException(
          'Biometrics are not available on this device.',
        );
      }
      final bool ok = await _prompt(
        reason: 'Confirm identity to enable app lock',
      );
      if (!ok) {
        return;
      }
    }

    await ref.read(authServiceProvider).setLockEnabled(enabled);
    state = state.copyWith(
      isEnabled: enabled,
      isLocked: false,
    );
  }

  Future<bool> _prompt({required String reason}) async {
    try {
      return await ref.read(authServiceProvider).authenticate(reason: reason);
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException('Authentication failed.', cause: error);
    }
  }
}
