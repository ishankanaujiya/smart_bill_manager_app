import '../../domain/entities/group.dart';

/// Abstract repository for the "Groups" Firestore collection.
abstract class GroupRepository {
  /// Creates a new group document in Firestore.
  ///
  /// A new document ID is auto-generated. The created [Group] (with the
  /// assigned document ID and server-set timestamps) is returned.
  Future<Group> createGroup(Group group);

  /// Fetches the group document for the given [id].
  ///
  /// Returns `null` if no document exists.
  Future<Group?> getGroup(String id);

  /// Fetches all groups that the user with [uid] is a member of.
  ///
  /// A group is included when the user appears in either the `members`
  /// list or the `created_by` list. Because the creator is always added
  /// as a member (admin) during group creation, the `member_ids`
  /// `array-contains` query covers both cases in a single read.
  Future<List<Group>> getGroupsForUser(String uid);

  /// Streams all groups that the user with [uid] is a member of.
  ///
  /// Same membership rule as [getGroupsForUser], but emits a new list
  /// whenever any matching document changes in Firestore. Use this for
  /// UI that must stay in sync with the backend in real time.
  Stream<List<Group>> watchGroupsForUser(String uid);

  /// Updates an existing group document with the fields in [group].
  ///
  /// The `updated_at` timestamp is always refreshed.
  Future<void> updateGroup(Group group);

  /// Deletes the group document for the given [id].
  Future<void> deleteGroup(String id);
}
