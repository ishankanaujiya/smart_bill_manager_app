import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/users/domain/entities/app_user.dart';

void main() {
  AppUser base() => AppUser(
        id: 'u1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        fullName: 'Aarati Sharma',
        email: 'aarati@example.com',
        phoneNumber: '9812345678',
        displayName: 'Aarati',
        profilePicture: 'https://example.com/a.png',
      );

  test('copyWith clears profilePicture when null is passed', () {
    expect(base().copyWith(profilePicture: null).profilePicture, isNull);
  });

  test('copyWith clears phoneNumber when null is passed', () {
    expect(base().copyWith(phoneNumber: null).phoneNumber, isNull);
  });

  test('copyWith clears displayName when null is passed', () {
    expect(base().copyWith(displayName: null).displayName, isNull);
  });

  test('copyWith leaves omitted nullable fields unchanged', () {
    final updated = base().copyWith(fullName: 'New Name');
    expect(updated.fullName, 'New Name');
    expect(updated.profilePicture, 'https://example.com/a.png');
    expect(updated.phoneNumber, '9812345678');
    expect(updated.displayName, 'Aarati');
  });

  test('copyWith still replaces nullable fields when a value is passed', () {
    final updated = base().copyWith(profilePicture: 'https://example.com/b.png');
    expect(updated.profilePicture, 'https://example.com/b.png');
  });
}
