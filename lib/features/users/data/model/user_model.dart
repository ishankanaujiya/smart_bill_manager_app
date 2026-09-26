import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// Firestore data model for the "Users" collection.
///
/// Handles serialization/deserialization between [AppUser] domain entities
/// and Firestore `Map<String, dynamic>` documents.
///
/// Collection name: `users`
/// Document ID:     Firebase Auth UID
class UserModel {
  const UserModel._({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.profilePicture,
  });

  /// Firestore collection path.
  static const String collectionName = 'users';

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? displayName;
  final String? profilePicture;

  /// Creates a [UserModel] from a Firestore document.
  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return UserModel._(
      id: doc.id,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      fullName: data['full_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phone_number'] as String?,
      displayName: data['display_name'] as String?,
      profilePicture: data['profile_picture'] as String?,
    );
  }

  /// Creates a [UserModel] from a plain map (useful for testing).
  factory UserModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return UserModel._(
      id: id,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String?,
      displayName: map['display_name'] as String?,
      profilePicture: map['profile_picture'] as String?,
    );
  }

  /// Serializes to a Firestore-compatible map.
  ///
  /// Timestamps are stored as [FieldValue.serverTimestamp] when the value
  /// is `null` (i.e. on create), so the server sets them consistently.
  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'created_at': isNew ? FieldValue.serverTimestamp() : createdAt,
      'updated_at': FieldValue.serverTimestamp(),
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'profile_picture': profilePicture,
    };
  }

  /// Serializes the mutable fields for a merge update.
  ///
  /// Optional fields are mapped to [FieldValue.delete] when they are `null`,
  /// so clearing a value (e.g. removing the profile picture) removes the field
  /// from the document instead of leaving the previous value behind.
  /// `created_at` is intentionally omitted — it must never be rewritten.
  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber ?? FieldValue.delete(),
      'display_name': displayName ?? FieldValue.delete(),
      'profile_picture': profilePicture ?? FieldValue.delete(),
    };
  }

  /// Converts to the domain entity.
  AppUser toEntity() {
    return AppUser(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
      profilePicture: profilePicture,
    );
  }

  /// Creates a [UserModel] from an [AppUser] entity.
  static UserModel fromEntity(AppUser user) {
    return UserModel._(
      id: user.id,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      profilePicture: user.profilePicture,
    );
  }
}
