import '../../domain/entities/app_notification.dart';

/// Abstract repository for the "Notifications" Firestore collection.
///
/// Documents are created by the notification proxy (Admin SDK), one per
/// recipient. This repository only reads a user's own notifications and
/// flips the `read` flag — clients never create or delete documents.
abstract class NotificationRepository {
  /// Streams the notifications addressed to the user with [uid], newest first.
  ///
  /// Emits a fresh list whenever any matching document is added, modified,
  /// or removed. The list is capped at the most recent 50 notifications.
  Stream<List<AppNotification>> watchNotificationsForUser(String uid);

  /// Marks the notification with [id] as read.
  Future<void> markAsRead(String id);

  /// Marks every unread notification belonging to the user with [uid] as read.
  Future<void> markAllAsRead(String uid);
}
