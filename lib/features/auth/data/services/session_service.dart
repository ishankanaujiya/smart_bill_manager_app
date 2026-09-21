import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's "remember me" preference across app launches.
///
/// Firebase Authentication persists the signed-in session to the device by
/// default. To honour the "remember me" checkbox on the sign-in screen we
/// store a boolean flag locally in secure storage:
///
///  - `true`  → leave the persisted Firebase session in place so the user is
///              signed in automatically on the next app launch. The user is
///              only signed out when they explicitly sign out from the app.
///  - `false` → the persisted Firebase session is cleared on the next app
///              launch (see [AuthGate]) so the user must sign in again.
///
/// The flag is cleared on explicit sign-out so that a fresh launch always
/// starts from the welcome screen unless the user opted into "remember me".
class SessionService {
  SessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _rememberMeKey = 'remember_me';

  /// Returns whether the user opted into "remember me" on their last
  /// successful sign-in. Defaults to `false` when no value has been stored.
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  /// Persists the "remember me" choice made on the sign-in screen.
  Future<void> setRememberMe(bool value) async {
    await _storage.write(
      key: _rememberMeKey,
      value: value ? 'true' : 'false',
    );
  }

  /// Clears the stored preference.
  ///
  /// Called on explicit sign-out so the next launch does not auto-sign-in.
  Future<void> clear() async {
    await _storage.delete(key: _rememberMeKey);
  }
}
