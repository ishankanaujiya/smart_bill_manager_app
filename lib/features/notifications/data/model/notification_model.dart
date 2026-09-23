import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

/// Firestore data model for the "Notifications" collection.
///
/// Handles serialization/deserialization between [AppNotification] domain
/// entities and Firestore `Map<String, dynamic>` documents.
///
/// Collection name: `notifications`
/// Document ID:     auto-generated
///
/// Document shape (snake_case, matching the security rules):
/// - `user_id`    : String    (recipient's Firebase UID — the query key)
/// - `type`       : String    (notification type wire value)
/// - `title`      : String    (rendered heading)
/// - `body`       : String    (rendered body)
/// - `group_id`   : String?   (navigation target)
/// - `bill_id`    : String?   (navigation target)
/// - `read`       : bool      (false on create)
/// - `created_at` : Timestamp (server)
class NotificationModel {
  const NotificationModel._({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.groupId,
    this.billId,
  });

  /// Firestore collection name.
  static const String collectionName = 'notifications';

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? groupId;
  final String? billId;

  /// Creates a [NotificationModel] from a Firestore document.
  factory NotificationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationModel._(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: _parseDate(data['created_at']),
      read: data['read'] as bool? ?? false,
      groupId: data['group_id'] as String?,
      billId: data['bill_id'] as String?,
    );
  }

  /// Creates a [NotificationModel] from a plain map (useful for testing).
  factory NotificationModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return NotificationModel._(
      id: id,
      userId: map['user_id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: _parseDate(map['created_at']),
      read: map['read'] as bool? ?? false,
      groupId: map['group_id'] as String?,
      billId: map['bill_id'] as String?,
    );
  }

  /// Serializes to a Firestore-compatible map.
  ///
  /// `created_at` uses [FieldValue.serverTimestamp] when [isNew] is true so
  /// the server sets it consistently.
  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'group_id': groupId,
      'bill_id': billId,
      'read': read,
      'created_at': isNew ? FieldValue.serverTimestamp() : createdAt,
    };
  }

  /// Converts to the domain entity.
  AppNotification toEntity() {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      groupId: groupId,
      billId: billId,
      read: read,
    );
  }

  /// Creates a [NotificationModel] from an [AppNotification] entity.
  static NotificationModel fromEntity(AppNotification notification) {
    return NotificationModel._(
      id: notification.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      createdAt: notification.createdAt,
      read: notification.read,
      groupId: notification.groupId,
      billId: notification.billId,
    );
  }

  /// Parses a Firestore timestamp, tolerating both [Timestamp] and [DateTime]
  /// values (and `null`).
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
