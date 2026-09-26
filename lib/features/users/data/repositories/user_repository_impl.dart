import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../model/user_model.dart';

/// Firestore implementation of [UserRepository].
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(UserModel.collectionName);

  @override
  Future<void> createUser(AppUser user) async {
    final model = UserModel.fromEntity(user);
    await _collection.doc(user.id).set(model.toMap(isNew: true));
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc).toEntity();
  }

  @override
  Future<List<AppUser>> searchUsers(String query,
      {String? excludeUid}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Firestore doesn't support OR queries across different fields in a
    // single where clause, so we fire both queries in parallel and merge.
    // Each query is wrapped in a try/catch so that if one fails (e.g. due
    // to a missing field on some documents), the other can still return
    // results.
    QuerySnapshot<Map<String, dynamic>>? emailSnapshot;
    QuerySnapshot<Map<String, dynamic>>? phoneSnapshot;

    try {
      emailSnapshot = await _collection
          .where('email', isGreaterThanOrEqualTo: trimmed)
          .where('email', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(10)
          .get();
    } catch (_) {
      // Email query failed — continue with phone results only.
    }

    try {
      phoneSnapshot = await _collection
          .where('phone_number', isGreaterThanOrEqualTo: trimmed)
          .where('phone_number', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(10)
          .get();
    } catch (_) {
      // Phone query failed — continue with email results only.
    }

    // Merge, deduplicate by document ID, and exclude the current user.
    final seen = <String>{};
    final users = <AppUser>[];

    for (final snapshot in [emailSnapshot, phoneSnapshot]) {
      if (snapshot == null) continue;
      for (final doc in snapshot.docs) {
        if (!doc.exists) continue;
        if (excludeUid != null && doc.id == excludeUid) continue;
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        users.add(UserModel.fromDocument(doc).toEntity());
      }
    }

    return users;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final model = UserModel.fromEntity(user);
    // Merge only the mutable fields; `created_at` is left untouched. Null
    // optional fields are deleted (see [UserModel.toUpdateMap]) so that
    // clearing a value — e.g. removing the profile picture — is persisted.
    await _collection
        .doc(user.id)
        .set(model.toUpdateMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _collection.doc(uid).delete();
  }
}
