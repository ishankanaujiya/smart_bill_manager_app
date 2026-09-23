import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../model/notification_model.dart';

/// Firestore implementation of [NotificationRepository].
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Maximum number of notifications kept in the inbox view.
  static const int _pageSize = 50;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(NotificationModel.collectionName);

  @override
  Stream<List<AppNotification>> watchNotificationsForUser(String uid) {
    // Query on `user_id` only — a single-field index Firestore creates
    // automatically — then order and cap in memory. This deliberately avoids
    // a composite `(user_id, created_at)` index so the inbox works without
    // any extra index deployment. A user's own inbox is small, so sorting
    // client-side is cheap.
    return _collection
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromDocument(doc).toEntity())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(_pageSize).toList();
    });
  }

  @override
  Future<void> markAsRead(String id) async {
    await _collection.doc(id).update({'read': true});
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    // Two equality filters only — served by single-field indexes, so no
    // composite index is needed for this query.
    final snapshot = await _collection
        .where('user_id', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
