/// Domain entity representing a single in-app notification.
///
/// Each document in the Firestore `notifications` collection targets exactly
/// one recipient (`userId`). Documents are written by the notification proxy
/// using the Admin SDK, one per recipient, at dispatch time — see
/// `onesignal-proxy/api/notify.js`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.groupId,
    this.billId,
    this.read = false,
  });

  /// Firestore document ID.
  final String id;

  /// Firebase Auth UID of the recipient this notification belongs to.
  final String userId;

  /// Raw wire value of the notification type (e.g. `billCreated`). Mirrors the
  /// keys in the proxy's `TEMPLATES` map and [NotificationType] on the client.
  final String type;

  /// Rendered heading (built server-side from the template).
  final String title;

  /// Rendered body (built server-side from the template).
  final String body;

  /// When the notification was created (server timestamp).
  final DateTime createdAt;

  /// Group document ID to open when the notification is tapped, if any.
  final String? groupId;

  /// Bill document ID to open when the notification is tapped, if any.
  final String? billId;

  /// Whether the recipient has already opened this notification.
  final bool read;

  /// Creates a copy of this entity with the given fields replaced.
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    DateTime? createdAt,
    String? groupId,
    String? billId,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      billId: billId ?? this.billId,
      read: read ?? this.read,
    );
  }
}
