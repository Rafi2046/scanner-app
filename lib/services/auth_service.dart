import 'package:local_auth/local_auth.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric availability, prompt, and lock-enabled preference.
class AuthService {
  AuthService({
    LocalAuthentication? localAuth,
  }) : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;
  SharedPreferences? _prefs;

  Future<bool> isBiometricAvailable() async {
    try {
      final bool supported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (error) {
      throw AuthException(
        'Could not check biometric availability.',
        cause: error,
      );
    }
  }

  Future<bool> authenticate({
    String reason = 'Unlock Scanner',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (error) {
      throw AuthException(
        'Authentication failed.',
        cause: error,
      );
    }
  }

  Future<void> setLockEnabled(bool status) async {
    try {
      final SharedPreferences prefs = await _prefsReady();
      await prefs.setBool(AppConstants.biometricLockPrefsKey, status);
    } catch (error) {
      throw AuthException(
        'Could not save lock setting.',
        cause: error,
      );
    }
  }

  Future<bool> getLockEnabled() async {
    try {
      final SharedPreferences prefs = await _prefsReady();
      return prefs.getBool(AppConstants.biometricLockPrefsKey) ?? false;
    } catch (error) {
      throw AuthException(
        'Could not read lock setting.',
        cause: error,
      );
    }
  }

  Future<SharedPreferences> _prefsReady() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
