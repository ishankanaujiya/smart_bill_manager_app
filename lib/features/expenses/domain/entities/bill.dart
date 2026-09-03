/// How the total bill amount is split among participants.
enum BillSplitMode {
  /// Every included participant pays exactly the same share.
  equal,

  /// Each participant has a manually entered custom share amount.
  custom,
}

/// A single participant's data within a bill.
///
/// This is a lightweight snapshot of the group member's profile at the time
/// the bill is created, plus their split-related state.
class BillParticipant {
  const BillParticipant({
    required this.id,
    required this.fullName,
    required this.email,
    this.displayName,
    this.profilePicture,
    this.customShare = 0.0,
    this.isIncluded = true,
    this.isCurrentUser = false,
  });

  /// Firebase Auth UID of the participant — matches the group member id.
  final String id;

  /// Legal full name.
  final String fullName;

  /// Email address.
  final String email;

  /// Short display name shown in the UI (may differ from [fullName]).
  final String? displayName;

  /// URL of the profile picture. May be `null`.
  final String? profilePicture;

  /// The custom share amount when split mode is [BillSplitMode.custom].
  /// Ignored for equal-split bills.
  final double customShare;

  /// Whether this participant is included in the split calculation.
  final bool isIncluded;

  /// Whether this participant is the currently signed-in user.
  final bool isCurrentUser;

  /// Returns the best display name for this participant.
  String get bestDisplayName =>
      (displayName?.isNotEmpty ?? false) ? displayName! : fullName;

  /// Returns the initial letters used in an avatar fallback.
  String get initials {
    final parts = bestDisplayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  /// Creates a copy of this participant with the given fields replaced.
  BillParticipant copyWith({
    String? id,
    String? fullName,
    String? email,
    String? displayName,
    String? profilePicture,
    double? customShare,
    bool? isIncluded,
    bool? isCurrentUser,
  }) {
    return BillParticipant(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePicture: profilePicture ?? this.profilePicture,
      customShare: customShare ?? this.customShare,
      isIncluded: isIncluded ?? this.isIncluded,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

/// Domain entity representing a bill / shared expense within a group.
///
/// This is a pure Dart class with no Flutter or Firebase dependencies so it
/// can be tested in isolation and will survive infrastructure changes.
class Bill {
  const Bill({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.totalAmount,
    required this.splitMode,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.receiptPhotoPath,
    this.date,
  });

  /// Locally-generated or Firestore document ID of the bill.
  final String id;

  /// ID of the group this bill belongs to.
  final String groupId;

  /// Display name of the group (snapshot).
  final String groupName;

  /// User-entered label for the bill (e.g. "Dinner", "Hotel").
  final String title;

  /// Optional description / note.
  final String? note;

  /// Total monetary amount of the bill.
  final double totalAmount;

  /// Local file path of an optional receipt photo.
  final String? receiptPhotoPath;

  /// The date on which the expense occurred. Defaults to [createdAt].
  final DateTime? date;

  /// How the total is split among participants.
  final BillSplitMode splitMode;

  /// All participants (included and excluded).
  final List<BillParticipant> participants;

  /// Firebase Auth UID of the user who created the bill.
  final String createdBy;

  /// When the bill entity was created locally.
  final DateTime createdAt;

  // ── Convenience getters ──────────────────────────────────────────────────

  /// Only the participants who are actually included in the split.
  List<BillParticipant> get includedParticipants =>
      participants.where((p) => p.isIncluded).toList();

  /// Number of participants included in the split.
  int get includedCount => includedParticipants.length;

  /// Per-person share for an equal split. Returns 0 when no one is included.
  double get perPersonShare =>
      includedCount > 0 ? totalAmount / includedCount : 0.0;

  /// The current user's effective share.
  double shareFor(String userId) {
    final participant = participants.cast<BillParticipant?>().firstWhere(
          (p) => p?.id == userId,
          orElse: () => null,
        );
    if (participant == null || !participant.isIncluded) return 0.0;
    return splitMode == BillSplitMode.equal
        ? perPersonShare
        : participant.customShare;
  }

  /// Creates a copy of this entity with the given fields replaced.
  Bill copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? title,
    String? note,
    double? totalAmount,
    String? receiptPhotoPath,
    DateTime? date,
    BillSplitMode? splitMode,
    List<BillParticipant>? participants,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      title: title ?? this.title,
      note: note ?? this.note,
      totalAmount: totalAmount ?? this.totalAmount,
      receiptPhotoPath: receiptPhotoPath ?? this.receiptPhotoPath,
      date: date ?? this.date,
      splitMode: splitMode ?? this.splitMode,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
