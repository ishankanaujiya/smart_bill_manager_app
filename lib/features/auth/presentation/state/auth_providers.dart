import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/session_service.dart';
import '../../../groups/data/service/cloudinary_service.dart';
import '../../../users/data/repositories/user_repository_impl.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/domain/repositories/user_repository.dart';
import '../../domain/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository providers
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provides the singleton [UserRepository] instance.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

/// Provides the singleton [CloudinaryService] instance.
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
/// Provides the singleton [SessionService] instance.
///
/// Used to persist the "remember me" preference across app launches.
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth state stream
// ─────────────────────────────────────────────────────────────────────────────

/// Streams the Firebase auth state.
///
/// Emits `null` when the user is signed out, or the [User] object when
/// signed in. Used by the [authStateProvider] to drive navigation.
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

// ─────────────────────────────────────────────────────────────────────────────
// Current AppUser (Firestore document)
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the [AppUser] Firestore document for the currently signed-in
/// Firebase user.
///
/// Returns `null` when no user is signed in or no Firestore document exists.
/// This is used to check whether the user's profile is complete after
/// Google sign-in.
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return null;

  final userRepo = ref.read(userRepositoryProvider);
  return userRepo.getUser(user.uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth actions notifier
// ─────────────────────────────────────────────────────────────────────────────

/// State for asynchronous auth operations.
sealed class AuthActionState {
  const AuthActionState();
}

class AuthActionIdle extends AuthActionState {
  const AuthActionIdle();
}

class AuthActionLoading extends AuthActionState {
  const AuthActionLoading();
}

class AuthActionSuccess extends AuthActionState {
  const AuthActionSuccess(this.user);
  final User user;
}

class AuthActionError extends AuthActionState {
  const AuthActionError(this.message);
  final String message;
}

/// Notifier that wraps auth operations (register, sign in, Google sign-in)
/// and exposes the loading/success/error state to the UI.
class AuthActionNotifier extends StateNotifier<AuthActionState> {
  AuthActionNotifier(
    this._authRepo,
    this._userRepo,
    this._sessionService,
    this._cloudinary,
  ) : super(const AuthActionIdle());

  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final SessionService _sessionService;
  final CloudinaryService _cloudinary;

  /// Registers a new user with email/password and stores their profile
  /// data in the Firestore "Users" collection.
  ///
  /// This is called from the Profile screen's "Finish" button — the final
  /// step of the registration flow. All form data collected across the
  /// registration screens is passed here.
  Future<bool> completeRegistration({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String displayName,
    String? profilePicture,
    String? profilePicturePath,
  }) async {
    state = const AuthActionLoading();

    try {
      // 1. Create the Firebase Auth account.
      final result = await _authRepo.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result is AuthFailure) {
        state = AuthActionError(result.message);
        return false;
      }

      final firebaseUser = (result as AuthSuccess).user;

      // 2. Upload the profile picture to Cloudinary if a local file was picked.
      String? profilePictureUrl = profilePicture;
      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        final file = File(profilePicturePath);
        if (await file.exists()) {
          profilePictureUrl =
              await _cloudinary.uploadFile(file) ?? profilePictureUrl;
        }
      }

      // 3. Store the user data in Firestore.
      final now = DateTime.now();
      final appUser = AppUser(
        id: firebaseUser.uid,
        createdAt: now,
        updatedAt: now,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
        profilePicture: profilePictureUrl,
      );

      await _userRepo.createUser(appUser);

      state = AuthActionSuccess(firebaseUser);
      return true;
    } catch (e) {
      state = AuthActionError(
        'Failed to save your profile. Please check your connection and try again.',
      );
      return false;
    }
  }

  /// Signs in an existing user with email and password.
  ///
  /// [rememberMe] persists the session across app launches when `true`. When
  /// `false` the user will be asked to sign in again on the next app launch.
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AuthActionLoading();

    try {
      final result = await _authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result is AuthFailure) {
        state = AuthActionError(result.message);
        return false;
      }

      await _sessionService.setRememberMe(rememberMe);
      state = AuthActionSuccess((result as AuthSuccess).user);
      return true;
    } catch (e) {
      state = AuthActionError(
        'Sign-in failed. Please check your connection and try again.',
      );
      return false;
    }
  }

  /// Initiates Google Sign-In.
  ///
  /// After successful authentication, checks whether a Firestore user
  /// document exists. If not, or if the profile is incomplete, stores
  /// the available Google data (email, display name, profile picture)
  /// with nulls for missing fields so the registration flow can fill
  /// them in.
  ///
  /// Google sign-in is an interactive, consent-based flow with no
  /// "remember me" checkbox, so the session is persisted by default —
  /// the user stays signed in across launches until they explicitly
  /// sign out.
  ///
  /// Returns `(true, null)` when the profile is complete and the user
  /// can go straight to the home screen.
  /// Returns `(true, partialUser)` when the user needs to complete
  /// their profile — [partialUser] contains the data collected from Google.
  /// Returns `(false, null)` when the sign-in failed.
  Future<({bool success, AppUser? partialUser})> signInWithGoogle() async {
    state = const AuthActionLoading();

    try {
      final result = await _authRepo.signInWithGoogle();

      if (result is AuthFailure) {
        state = AuthActionError(result.message);
        return (success: false, partialUser: null);
      }

      final firebaseUser = (result as AuthSuccess).user;

      // Persist the session for Google sign-in (no "remember me" checkbox
      // is presented for the social sign-in flow).
      await _sessionService.setRememberMe(true);

      // Check if a Firestore user document already exists.
      final existingUser = await _userRepo.getUser(firebaseUser.uid);

      if (existingUser != null && existingUser.isProfileComplete) {
        // Profile is complete — user can go straight to home.
        state = AuthActionSuccess(firebaseUser);
        return (success: true, partialUser: null);
      }

      // Profile is incomplete or doesn't exist.
      // Store whatever data we have from Google, with nulls for missing fields.
      final now = DateTime.now();
      final partialUser = AppUser(
        id: firebaseUser.uid,
        createdAt: existingUser?.createdAt ?? now,
        updatedAt: now,
        fullName: existingUser?.fullName ??
            firebaseUser.displayName ??
            '',
        email: firebaseUser.email ?? existingUser?.email ?? '',
        phoneNumber: existingUser?.phoneNumber,
        displayName: existingUser?.displayName ??
            firebaseUser.displayName,
        profilePicture: existingUser?.profilePicture ??
            firebaseUser.photoURL,
      );

      // Create or update the Firestore document with partial data.
      if (existingUser == null) {
        await _userRepo.createUser(partialUser);
      } else {
        await _userRepo.updateUser(partialUser);
      }

      state = AuthActionSuccess(firebaseUser);
      return (success: true, partialUser: partialUser);
    } catch (e) {
      state = AuthActionError(
        'Google sign-in failed. Please check your connection and try again.',
      );
      return (success: false, partialUser: null);
    }
  }

  /// Completes a user's profile after Google sign-in when fields were missing.
  ///
  /// Updates the Firestore document with the data collected from the
  /// registration flow, merging with the existing Google-provided data.
  Future<bool> completeGoogleProfile({
    required AppUser partialUser,
    required String fullName,
    required String phoneNumber,
    required String displayName,
    String? profilePicturePath,
  }) async {
    state = const AuthActionLoading();

    try {
      // Upload the profile picture to Cloudinary if a local file was picked.
      String? profilePictureUrl = partialUser.profilePicture;
      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        final file = File(profilePicturePath);
        if (await file.exists()) {
          profilePictureUrl =
              await _cloudinary.uploadFile(file) ?? profilePictureUrl;
        }
      }

      final updatedUser = partialUser.copyWith(
        fullName: fullName,
        phoneNumber: phoneNumber,
        displayName: displayName,
        updatedAt: DateTime.now(),
        profilePicture: profilePictureUrl,
      );

      await _userRepo.updateUser(updatedUser);

      state = AuthActionSuccess(_authRepo.currentUser!);
      return true;
    } catch (e) {
      state = AuthActionError(
        'Failed to save your profile. Please check your connection and try again.',
      );
      return false;
    }
  }

  /// Signs out the current user.
  ///
  /// Also clears the "remember me" preference so the next app launch
  /// starts from the welcome screen.
  Future<void> signOut() async {
    state = const AuthActionLoading();
    await _sessionService.clear();
    await _authRepo.signOut();
    state = const AuthActionIdle();
  }

  /// Resets the state back to idle (e.g. to clear an error).
  void reset() {
    state = const AuthActionIdle();
  }
}

/// Provider for [AuthActionNotifier].
final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AuthActionState>((ref) {
  return AuthActionNotifier(
    ref.read(authRepositoryProvider),
    ref.read(userRepositoryProvider),
    ref.read(sessionServiceProvider),
    ref.read(cloudinaryServiceProvider),
  );
});
