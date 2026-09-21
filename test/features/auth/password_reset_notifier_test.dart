import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_bill_manager/features/auth/presentation/state/password_reset_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepo;
  late PasswordResetNotifier notifier;

  setUp(() {
    authRepo = _MockAuthRepository();
    notifier = PasswordResetNotifier(authRepo);
  });

  group('PasswordResetNotifier', () {
    test('starts in the idle state', () {
      expect(notifier.state, isA<PasswordResetIdle>());
    });

    test('emits success and returns true when the email is sent', () async {
      when(() => authRepo.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const PasswordResetSent());

      final result = await notifier.send('user@example.com');

      expect(result, isTrue);
      expect(notifier.state, isA<PasswordResetSuccess>());
      verify(() => authRepo.sendPasswordResetEmail(email: 'user@example.com'))
          .called(1);
    });

    test('emits an error with the message and returns false on failure',
        () async {
      when(() => authRepo.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer(
        (_) async => const PasswordResetFailure('No account found.'),
      );

      final result = await notifier.send('missing@example.com');

      expect(result, isFalse);
      expect(notifier.state, isA<PasswordResetError>());
      expect(
        (notifier.state as PasswordResetError).message,
        'No account found.',
      );
    });

    test('goes through the sending state while awaiting the repository',
        () async {
      when(() => authRepo.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const PasswordResetSent());

      final future = notifier.send('user@example.com');
      expect(notifier.state, isA<PasswordResetSending>());

      await future;
      expect(notifier.state, isA<PasswordResetSuccess>());
    });

    test('reset() returns the notifier to idle', () async {
      when(() => authRepo.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer(
        (_) async => const PasswordResetFailure('Network error.'),
      );

      await notifier.send('user@example.com');
      expect(notifier.state, isA<PasswordResetError>());

      notifier.reset();
      expect(notifier.state, isA<PasswordResetIdle>());
    });
  });
}
