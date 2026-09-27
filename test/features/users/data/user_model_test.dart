import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/users/data/model/user_model.dart';
import 'package:smart_bill_manager/features/users/domain/entities/app_user.dart';

void main() {
  AppUser user({String? photo, String? phone}) => AppUser(
        id: 'u1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        fullName: 'Aarati Sharma',
        email: 'aarati@example.com',
        phoneNumber: phone,
        displayName: 'Aarati',
        profilePicture: photo,
      );

  group('toUpdateMap', () {
    test('deletes profile_picture when it is null', () {
      final map = UserModel.fromEntity(user()).toUpdateMap();
      expect(map['profile_picture'], isA<FieldValue>());
    });

    test('deletes phone_number when it is null', () {
      final map = UserModel.fromEntity(user()).toUpdateMap();
      expect(map['phone_number'], isA<FieldValue>());
    });

    test('keeps profile_picture when a value is present', () {
      final map = UserModel.fromEntity(
        user(photo: 'https://example.com/a.png'),
      ).toUpdateMap();
      expect(map['profile_picture'], 'https://example.com/a.png');
    });

    test('never rewrites created_at', () {
      final map = UserModel.fromEntity(user()).toUpdateMap();
      expect(map.containsKey('created_at'), isFalse);
    });

    test('always refreshes updated_at', () {
      final map = UserModel.fromEntity(user()).toUpdateMap();
      expect(map['updated_at'], isA<FieldValue>());
    });
  });
}
