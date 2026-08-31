/// Domain entity representing a registered user.
///
/// This is the core business object, independent of any data source.
/// It maps directly to a document in the Firestore "Users" collection.
class AppUser {
  const AppUser({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.profilePicture,
  });

  /// Firestore document ID — same as the Firebase Auth UID.
  final String id;

  /// When the user document was first created.
  final DateTime createdAt;

  /// When the user document was last updated.
  final DateTime updatedAt;

  /// Legal full name (first + last).
  final String fullName;

  /// Email address used for authentication.
  final String email;

  /// Nepali mobile number (10 digits, starts with 98/97).
  /// May be `null` for Google sign-in users who haven't completed their profile.
  final String? phoneNumber;

  /// Display name shown inside groups. May differ from [fullName].
  /// May be `null` for Google sign-in users who haven't completed their profile.
  final String? displayName;

  /// URL of the profile picture.
  /// May be `null` for email/password users who haven't uploaded one.
  final String? profilePicture;

  /// Returns `true` when every field has a non-null value.
  ///
  /// Used after Google sign-in to decide whether the user needs to
  /// complete the registration flow before reaching the home screen.
  bool get isProfileComplete =>
      fullName.isNotEmpty &&
      email.isNotEmpty &&
      phoneNumber != null &&
      phoneNumber!.isNotEmpty &&
      displayName != null &&
      displayName!.isNotEmpty;

  /// Creates a copy of this entity with the given fields replaced.
  AppUser copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? profilePicture,
  }) {
    return AppUser(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
