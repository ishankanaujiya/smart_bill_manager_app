import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// State for the "forgot password" flow.
///
/// Deliberately separate from [AuthActionState] so a reset request can never
/// leak its loading/error state into the sign-in screen (and vice-versa).
sealed class PasswordResetState {
  const PasswordResetState();
}

class PasswordResetIdle extends PasswordResetState {
  const PasswordResetIdle();
}

class PasswordResetSending extends PasswordResetState {
  const PasswordResetSending();
}

class PasswordResetSuccess extends PasswordResetState {
  const PasswordResetSuccess();
}

class PasswordResetError extends PasswordResetState {
  const PasswordResetError(this.message);
  final String message;
}

/// Drives the password-reset request and exposes its progress to the UI.
class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  PasswordResetNotifier(this._authRepo) : super(const PasswordResetIdle());

  final AuthRepository _authRepo;

  /// Sends a reset email to [email].
  ///
  /// Returns `true` on success, `false` on failure (message in [state]).
  Future<bool> send(String email) async {
    state = const PasswordResetSending();

    final result = await _authRepo.sendPasswordResetEmail(email: email);

    switch (result) {
      case PasswordResetSent():
        state = const PasswordResetSuccess();
        return true;
      case PasswordResetFailure(:final message):
        state = PasswordResetError(message);
        return false;
    }
  }

  /// Resets the state back to idle (e.g. to clear an error).
  void reset() => state = const PasswordResetIdle();
}

/// Provider for [PasswordResetNotifier].
///
/// `autoDispose` ensures the state is discarded when the forgot-password
/// screen is popped, so a stale success/error never resurfaces on the next
/// visit.
final passwordResetProvider = StateNotifierProvider.autoDispose<
    PasswordResetNotifier, PasswordResetState>((ref) {
  return PasswordResetNotifier(ref.read(authRepositoryProvider));
});
