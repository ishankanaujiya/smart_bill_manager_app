import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/notifications/data/model/notification_model.dart';
import 'package:smart_bill_manager/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('NotificationModel', () {
    final createdAt = DateTime(2026, 1, 2, 3, 4);

    test('fromMap parses a full document', () {
      final model = NotificationModel.fromMap(
        {
          'user_id': 'u1',
          'type': 'billCreated',
          'title': 'New bill in "Trip"',
          'body': 'Alice created a bill "Dinner" for NPR 400.',
          'group_id': 'g1',
          'bill_id': 'b1',
          'read': false,
          'created_at': Timestamp.fromDate(createdAt),
        },
        id: 'n1',
      );

      expect(model.id, 'n1');
      expect(model.userId, 'u1');
      expect(model.type, 'billCreated');
      expect(model.title, 'New bill in "Trip"');
      expect(model.body, contains('Dinner'));
      expect(model.groupId, 'g1');
      expect(model.billId, 'b1');
      expect(model.read, isFalse);
      expect(model.createdAt, createdAt);
    });

    test('fromMap tolerates missing fields', () {
      final model = NotificationModel.fromMap(const <String, dynamic>{}, id: 'n2');

      expect(model.userId, '');
      expect(model.type, '');
      expect(model.title, '');
      expect(model.body, '');
      expect(model.groupId, isNull);
      expect(model.billId, isNull);
      expect(model.read, isFalse);
    });

    test('fromMap accepts a DateTime created_at', () {
      final model = NotificationModel.fromMap(
        {'created_at': createdAt},
        id: 'n3',
      );

      expect(model.createdAt, createdAt);
    });

    test('toMap emits snake_case keys and preserves values', () {
      final model = NotificationModel.fromEntity(
        AppNotification(
          id: 'n4',
          userId: 'u2',
          type: 'groupAdded',
          title: 'Added to "X"',
          body: 'Bob added you to the group "X".',
          createdAt: createdAt,
          groupId: 'g2',
          read: true,
        ),
      );

      final map = model.toMap();

      expect(map['user_id'], 'u2');
      expect(map['type'], 'groupAdded');
      expect(map['title'], 'Added to "X"');
      expect(map['group_id'], 'g2');
      expect(map['bill_id'], isNull);
      expect(map['read'], isTrue);
      expect(map['created_at'], createdAt);
    });

    test('toMap uses a server timestamp when isNew', () {
      final model = NotificationModel.fromEntity(
        AppNotification(
          id: '',
          userId: 'u3',
          type: 'billCreated',
          title: 't',
          body: 'b',
          createdAt: createdAt,
        ),
      );

      final map = model.toMap(isNew: true);

      expect(map['created_at'], isA<FieldValue>());
    });

    test('toEntity maps back to the domain entity', () {
      final model = NotificationModel.fromMap(
        {
          'user_id': 'u4',
          'type': 'paymentApproved',
          'title': 'Approved',
          'body': 'Your payment was approved.',
          'group_id': 'g3',
          'bill_id': 'b3',
          'read': true,
          'created_at': Timestamp.fromDate(createdAt),
        },
        id: 'n5',
      );

      final entity = model.toEntity();

      expect(entity.id, 'n5');
      expect(entity.userId, 'u4');
      expect(entity.type, 'paymentApproved');
      expect(entity.title, 'Approved');
      expect(entity.body, 'Your payment was approved.');
      expect(entity.groupId, 'g3');
      expect(entity.billId, 'b3');
      expect(entity.read, isTrue);
      expect(entity.createdAt, createdAt);
    });
  });
}
