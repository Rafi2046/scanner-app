/// Snapshot of biometric lock UI state.
class AuthState {
  const AuthState({
    this.isLocked = false,
    this.isEnabled = false,
    this.isAvailable = false,
  });

  final bool isLocked;
  final bool isEnabled;
  final bool isAvailable;

  AuthState copyWith({
    bool? isLocked,
    bool? isEnabled,
    bool? isAvailable,
  }) {
    return AuthState(
      isLocked: isLocked ?? this.isLocked,
      isEnabled: isEnabled ?? this.isEnabled,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
