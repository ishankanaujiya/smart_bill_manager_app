import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_bill_manager/features/auth/presentation/state/password_reset_provider.dart';
import 'package:smart_bill_manager/features/auth/presentation/view/forgot_password_screen.dart';
import 'package:smart_bill_manager/features/auth/presentation/widget/auth_text_field.dart';

/// Stub [AuthRepository] that records reset calls and returns a fixed result.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.result = const PasswordResetSent()});

  final PasswordResetResult result;
  int resetCallCount = 0;
  String? lastEmail;

  @override
  Future<PasswordResetResult> sendPasswordResetEmail({
    required String email,
  }) async {
    resetCallCount++;
    lastEmail = email;
    return result;
  }

  @override
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      const AuthResult.failure('Not implemented in tests.');

  @override
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      const AuthResult.failure('Not implemented in tests.');

  @override
  Future<AuthResult> signInWithGoogle() async =>
      const AuthResult.failure('Not implemented in tests.');

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signOut() async {}
}

Widget _buildScreen(_StubAuthRepository stub) {
  return ProviderScope(
    overrides: [
      passwordResetProvider.overrideWith(
        (ref) => PasswordResetNotifier(stub),
      ),
    ],
    child: const MaterialApp(home: ForgotPasswordScreen()),
  );
}

/// The header runs a perpetual pulse animation, so `pumpAndSettle` never
/// finishes. Pump fixed durations instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('renders the request state', (tester) async {
    await tester.pumpWidget(_buildScreen(_StubAuthRepository()));
    await _settle(tester);

    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.byType(AuthTextField), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Check your inbox'), findsNothing);
  });

  testWidgets('pre-fills the email field with initialEmail', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          passwordResetProvider.overrideWith(
            (ref) => PasswordResetNotifier(_StubAuthRepository()),
          ),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(initialEmail: 'prefilled@example.com'),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('prefilled@example.com'), findsOneWidget);
  });

  testWidgets('invalid email shows an error and does not call the repository',
      (tester) async {
    final stub = _StubAuthRepository();
    await tester.pumpWidget(_buildScreen(stub));
    await _settle(tester);

    await tester.enterText(find.byType(AuthTextField), 'not-an-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(stub.resetCallCount, 0);
  });

  testWidgets('valid email sends the reset and shows the success state',
      (tester) async {
    final stub = _StubAuthRepository();
    await tester.pumpWidget(_buildScreen(stub));
    await _settle(tester);

    await tester.enterText(find.byType(AuthTextField), 'user@example.com');
    await tester.tap(find.text('Send reset link'));

    // Let the async request resolve, then the switcher + check animations run.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 800));

    expect(stub.resetCallCount, 1);
    expect(stub.lastEmail, 'user@example.com');
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
    // Resend is on cooldown immediately after a successful send.
    expect(find.textContaining('Resend link in'), findsOneWidget);
  });

  testWidgets('a failure keeps the user on the request state', (tester) async {
    final stub = _StubAuthRepository(
      result: const PasswordResetFailure('Network error.'),
    );
    await tester.pumpWidget(_buildScreen(stub));
    await _settle(tester);

    await tester.enterText(find.byType(AuthTextField), 'user@example.com');
    await tester.tap(find.text('Send reset link'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(stub.resetCallCount, 1);
    // Still on the request state — no success view.
    expect(find.text('Check your inbox'), findsNothing);
    expect(find.text('Send reset link'), findsOneWidget);
  });
}
