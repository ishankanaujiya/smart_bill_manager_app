import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/state/auth_providers.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/domain/repositories/user_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User search state
// ─────────────────────────────────────────────────────────────────────────────

/// State for the user search operation.
sealed class UserSearchState {
  const UserSearchState();
}

class UserSearchIdle extends UserSearchState {
  const UserSearchIdle();
}

class UserSearchLoading extends UserSearchState {
  const UserSearchLoading();
}

class UserSearchSuccess extends UserSearchState {
  const UserSearchSuccess(this.users);
  final List<AppUser> users;
}

class UserSearchError extends UserSearchState {
  const UserSearchError(this.message);
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────
// User search notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Notifier that debounces search queries and fetches matching users from
/// the Firestore "Users" collection.
///
/// Queries are debounced by 400ms to avoid hitting Firestore on every
/// keystroke. The currently signed-in user is always excluded from the
/// results so you can't add yourself as a member.
class UserSearchNotifier extends StateNotifier<UserSearchState> {
  UserSearchNotifier(this._userRepo) : super(const UserSearchIdle());

  final UserRepository _userRepo;
  Timer? _debounce;

  /// Searches for users by email or phone number prefix.
  ///
  /// Pass an empty string to reset to idle.
  void search(String query) {
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const UserSearchIdle();
      return;
    }

    state = const UserSearchLoading();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final excludeUid = FirebaseAuth.instance.currentUser?.uid;
        final users = await _userRepo.searchUsers(
          trimmed,
          excludeUid: excludeUid,
        );
        if (!mounted) return;
        state = UserSearchSuccess(users);
      } on FirebaseException catch (e) {
        if (!mounted) return;
        final message = switch (e.code) {
          'permission-denied' =>
            'You don\'t have permission to search users. Please contact support.',
          'unavailable' =>
            'Firestore is temporarily unavailable. Please try again.',
          'network-request-failed' =>
            'Network error. Please check your internet connection.',
          _ => 'Search failed. Please try again.',
        };
        state = UserSearchError(message);
      } catch (_) {
        if (!mounted) return;
        state = const UserSearchError(
          'Search failed. Please try again.',
        );
      }
    });
  }

  /// Resets the search state to idle and cancels any pending query.
  void reset() {
    _debounce?.cancel();
    state = const UserSearchIdle();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Provider for [UserSearchNotifier].
final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  return UserSearchNotifier(ref.read(userRepositoryProvider));
});
