import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../model/group_model.dart';

/// Firestore implementation of [GroupRepository].
class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(GroupModel.collectionName);

  @override
  Future<Group> createGroup(Group group) async {
    final model = GroupModel.fromEntity(group);
    final docRef =
        await _collection.add(model.toMap(isNew: true));

    // Read the document back so the server-set timestamps and the
    // generated document ID are reflected in the returned entity.
    final snapshot = await docRef.get();
    return GroupModel.fromDocument(snapshot).toEntity();
  }

  @override
  Future<Group?> getGroup(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return GroupModel.fromDocument(doc).toEntity();
  }

  @override
  Future<List<Group>> getGroupsForUser(String uid) async {
    // `member_ids` is a flat list of uid strings, so we can use an
    // efficient `array-contains` query instead of fetching all groups
    // and filtering client-side.
    final snapshot = await _collection
        .where('member_ids', arrayContains: uid)
        .get();

    return snapshot.docs
        .map((doc) => GroupModel.fromDocument(doc).toEntity())
        .toList();
  }

  @override
  Stream<List<Group>> watchGroupsForUser(String uid) {
    // Real-time equivalent of [getGroupsForUser]. Emits a fresh list
    // whenever any matching document is added, modified, or removed.
    return _collection
        .where('member_ids', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromDocument(doc).toEntity())
            .toList());
  }

  @override
  Future<void> updateGroup(Group group) async {
    final model = GroupModel.fromEntity(group);
    // Only write the mutable fields; keep created_at untouched.
    await _collection.doc(group.id).set({
      'updated_at': FieldValue.serverTimestamp(),
      'group_name': model.groupName,
      'group_picture': model.groupPicture,
      'member_ids': model.memberIds,
      'group_admin': model.groupAdmin,
      'members': model.members,
      'member_count': model.memberCount,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _collection.doc(id).delete();
  }
}
