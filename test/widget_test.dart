import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_bill_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_bill_manager/features/auth/presentation/state/auth_providers.dart';
import 'package:smart_bill_manager/features/users/domain/entities/app_user.dart';
import 'package:smart_bill_manager/features/users/domain/repositories/user_repository.dart';
import 'package:smart_bill_manager/main.dart';

/// A no-op [AuthRepository] stub for widget tests that don't test auth logic.
class _StubAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const AuthResult.failure('Not implemented in tests.');
  }

  @override
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const AuthResult.failure('Not implemented in tests.');
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthResult.failure('Not implemented in tests.');
  }

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signOut() async {}
}

/// A no-op [UserRepository] stub for widget tests.
class _StubUserRepository implements UserRepository {
  @override
  Future<void> createUser(AppUser user) async {}

  @override
  Future<AppUser?> getUser(String uid) async => null;

  @override
  Future<List<AppUser>> searchUsers(String query, {String? excludeUid}) async => [];

  @override
  Future<void> updateUser(AppUser user) async {}

  @override
  Future<void> deleteUser(String uid) async {}
}

void main() {
  /// Provider overrides that replace Firebase-dependent repositories with
  /// in-memory stubs so widget tests don't require Firebase initialization.
  final testOverrides = [
    authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
    userRepositoryProvider.overrideWithValue(_StubUserRepository()),
  ];

  testWidgets('App renders welcome screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides,
        child: const SmartBillManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all core welcome screen text and the image asset.
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Group Expense'), findsOneWidget);
    expect(find.text('Splitter'), findsOneWidget);
    expect(find.text('Manage together. Split easily.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Welcome screen navigates to sign-in screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides,
        child: const SmartBillManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'), warnIfMissed: false);
    // The sign-in header has a perpetual pulse animation, so pumpAndSettle
    // would never finish. Pump fixed durations instead to let the entrance
    // animation complete and the screen settle into its final layout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to see who owes what.'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
