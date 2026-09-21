import 'package:firebase_auth/firebase_auth.dart';

/// Result of an authentication operation.
///
/// Either a success containing the Firebase [User], or a failure containing
/// a human-readable error message.
sealed class AuthResult {
  const AuthResult();

  const factory AuthResult.success(User user) = AuthSuccess;
  const factory AuthResult.failure(String message) = AuthFailure;
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final User user;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

/// Result of a password-reset request.
///
/// A reset has no authenticated [User] to carry on success, so it uses its
/// own sealed hierarchy rather than [AuthResult].
sealed class PasswordResetResult {
  const PasswordResetResult();
}

class PasswordResetSent extends PasswordResetResult {
  const PasswordResetSent();
}

class PasswordResetFailure extends PasswordResetResult {
  const PasswordResetFailure(this.message);
  final String message;
}

/// Abstract repository for Firebase Authentication.
abstract class AuthRepository {
  /// Creates a new user account with email and password.
  ///
  /// Returns the Firebase [User] on success, or an error message on failure.
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password.
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Initiates Google Sign-In and returns the authenticated Firebase [User].
  ///
  /// If the user cancels the sign-in flow, returns [AuthResult.failure] with
  /// a cancellation message.
  Future<AuthResult> signInWithGoogle();

  /// Sends a password-reset email to [email].
  ///
  /// Firebase emails a secure link that opens a hosted page where the user
  /// sets a new password. Returns [PasswordResetSent] on success or
  /// [PasswordResetFailure] with a user-friendly message on failure.
  Future<PasswordResetResult> sendPasswordResetEmail({required String email});

  /// Returns the currently signed-in user, or `null` if no user is signed in.
  User? get currentUser;

  /// Streams authentication state changes.
  Stream<User?> authStateChanges();

  /// Signs out the current user.
  Future<void> signOut();
}
