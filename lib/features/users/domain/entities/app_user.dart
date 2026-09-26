/// Sentinel used by [AppUser.copyWith] to distinguish "leave this nullable
/// field unchanged" from "set it to `null`".
const Object _unset = Object();

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

  /// Returns `true` when the core profile fields are populated.
  ///
  /// Used after Google sign-in to decide whether the user needs to
  /// complete the registration flow before reaching the home screen.
  ///
  /// [phoneNumber] is intentionally excluded — Google does not provide a
  /// phone number, so requiring it here would always route Google users
  /// through profile completion. The phone number can be collected later
  /// from within the app.
  bool get isProfileComplete =>
      fullName.isNotEmpty &&
      email.isNotEmpty &&
      displayName != null &&
      displayName!.isNotEmpty;

  /// Creates a copy of this entity with the given fields replaced.
  ///
  /// The nullable fields ([phoneNumber], [displayName], [profilePicture]) use
  /// an "unset" sentinel so a caller can explicitly clear one by passing
  /// `null` (e.g. `copyWith(profilePicture: null)` when the user removes their
  /// photo), while omitting the argument leaves the current value untouched.
  AppUser copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? email,
    Object? phoneNumber = _unset,
    Object? displayName = _unset,
    Object? profilePicture = _unset,
  }) {
    return AppUser(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber:
          phoneNumber == _unset ? this.phoneNumber : phoneNumber as String?,
      displayName:
          displayName == _unset ? this.displayName : displayName as String?,
      profilePicture: profilePicture == _unset
          ? this.profilePicture
          : profilePicture as String?,
    );
  }
}
