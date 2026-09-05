import '../../domain/entities/app_user.dart';

/// Abstract repository for the "Users" Firestore collection.
abstract class UserRepository {
  /// Creates a new user document in Firestore.
  ///
  /// Called after a successful Firebase Auth registration or Google sign-in.
  /// If a document already exists for the given [user.id], it will be
  /// overwritten.
  Future<void> createUser(AppUser user);

  /// Fetches the user document for the given [uid].
  ///
  /// Returns `null` if no document exists.
  Future<AppUser?> getUser(String uid);

  /// Searches the "Users" collection by email or phone number.
  ///
  /// [query] is matched as a prefix against the `email` and `phone_number`
  /// fields. Returns a list of matching [AppUser]s, excluding the user with
  /// the given [excludeUid] (the current user).
  ///
  /// Results are limited to 10 documents to keep the query fast.
  Future<List<AppUser>> searchUsers(String query, {String? excludeUid});

  /// Updates an existing user document with the fields in [user].
  ///
  /// Only non-null fields are written. The `updated_at` timestamp is
  /// always refreshed.
  Future<void> updateUser(AppUser user);

  /// Deletes the user document for the given [uid].
  Future<void> deleteUser(String uid);
}
