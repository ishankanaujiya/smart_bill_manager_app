import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

/// Firebase Authentication implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Initializes the Google Sign-In SDK.
  ///
  /// Must be called once before any Google sign-in attempt. Called from
  /// [main] during app startup.
  static Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize();
  }

  @override
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the interactive Google Sign-In flow.
      final googleAccount = await _googleSignIn.authenticate();
      final authTokens = googleAccount.authentication;

      // Obtain the Google auth credential for Firebase.
      final credential = GoogleAuthProvider.credential(
        idToken: authTokens.idToken,
      );

      // Sign in to Firebase with the Google credential.
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user!);
    } on GoogleSignInException catch (e) {
      // User cancelled or the flow was interrupted.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return const AuthResult.failure('Sign-in was cancelled.');
      }
      return AuthResult.failure(
        'Google sign-in failed: ${e.description}',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return const AuthResult.failure(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<PasswordResetResult> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const PasswordResetSent();
    } on FirebaseAuthException catch (e) {
      return PasswordResetFailure(_mapAuthError(e));
    } catch (_) {
      return const PasswordResetFailure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Maps [FirebaseAuthException] codes to user-friendly messages.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'missing-email':
        return 'Please enter your email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Authentication failed. Please try again.';
    }
  }
}
