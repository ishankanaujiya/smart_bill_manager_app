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
  Future<void> updateUser(AppUser user) async {
    final model = UserModel.fromEntity(user);
    // Only write the mutable fields; keep created_at untouched.
    await _collection.doc(user.id).set({
      'updated_at': FieldValue.serverTimestamp(),
      'full_name': model.fullName,
      'email': model.email,
      'phone_number': model.phoneNumber,
      'display_name': model.displayName,
      'profile_picture': model.profilePicture,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _collection.doc(uid).delete();
  }
}
