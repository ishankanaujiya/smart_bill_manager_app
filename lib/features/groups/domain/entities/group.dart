/// Role of a member within a group.
enum MemberRole { admin, member }

/// Domain entity representing a single member inside a group.
///
/// This is a snapshot of the user's profile at the time they were added,
/// so a group's member list stays readable even if the user later changes
/// their display name or profile picture.
class GroupMember {
  const GroupMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.profilePicture,
    this.role = MemberRole.member,
  });

  /// Firestore document ID of the user — same as the Firebase Auth UID.
  final String id;

  /// Legal full name (first + last) of the user.
  final String fullName;

  /// Email address of the user.
  final String email;

  /// Nepali mobile number. May be `null` for Google sign-in users.
  final String? phoneNumber;

  /// Display name shown inside groups. May differ from [fullName].
  final String? displayName;

  /// URL of the profile picture. May be `null`.
  final String? profilePicture;

  /// Role of this member within the group.
  final MemberRole role;

  /// Returns `true` when this member is the group admin.
  bool get isAdmin => role == MemberRole.admin;

  /// Creates a copy of this entity with the given fields replaced.
  GroupMember copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? profilePicture,
    MemberRole? role,
  }) {
    return GroupMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
    );
  }
}

/// Domain entity representing a group.
///
/// This is the core business object, independent of any data source.
/// It maps directly to a document in the Firestore "groups" collection.
///
/// The Firestore document stores these membership-related fields that the
/// security rules rely on:
/// - `created_by`   — the uid (String) of the user who created the group.
/// - `member_ids`   — a list of uid strings for every member, used by the
///   rules' `array-contains` checks and for fast membership queries.
/// - `group_admin`  — the admin's full profile snapshot (the user who
///   created the group), stored as a single member map.
/// The full member profile snapshots are kept in [members] for display.
class Group {
  const Group({
    required this.id,
    required this.groupName,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.memberIds,
    required this.groupAdmin,
    required this.members,
    required this.memberCount,
    this.groupPicture,
  });

  /// Firestore document ID of the group.
  final String id;

  /// Name of the group, chosen by the creator.
  final String groupName;

  /// URL of the group picture (uploaded to Cloudinary). May be `null`.
  final String? groupPicture;

  /// When the group document was first created.
  final DateTime createdAt;

  /// When the group document was last updated.
  final DateTime updatedAt;

  /// The uid of the user who created the group (also the admin).
  final String createdBy;

  /// List of every member's uid. Mirrors the `id` field of [members] and
  /// is used by Firestore security rules and membership queries.
  final List<String> memberIds;

  /// The admin's full profile snapshot — the user who created the group.
  /// Stored as the `group_admin` field in Firestore.
  final GroupMember groupAdmin;

  /// All members of the group, stored as a list of [GroupMember] snapshots
  /// fetched from the "Users" collection.
  final List<GroupMember> members;

  /// Total number of members in the group.
  final int memberCount;

  /// Creates a copy of this entity with the given fields replaced.
  Group copyWith({
    String? id,
    String? groupName,
    String? groupPicture,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? memberIds,
    GroupMember? groupAdmin,
    List<GroupMember>? members,
    int? memberCount,
  }) {
    return Group(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      groupPicture: groupPicture ?? this.groupPicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      groupAdmin: groupAdmin ?? this.groupAdmin,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
