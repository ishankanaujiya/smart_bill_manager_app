import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/features/auth/presentation/state/auth_providers.dart';
import 'package:smart_bill_manager/features/groups/presentation/state/group_providers.dart';

class _MockUser extends Mock implements User {}

void main() {
  late _MockUser userA;
  late _MockUser userB;

  setUp(() {
    userA = _MockUser();
    when(() => userA.uid).thenReturn('user-a');
    userB = _MockUser();
    when(() => userB.uid).thenReturn('user-b');
  });

  ProviderContainer containerWith(Stream<User?> stream) {
    final container = ProviderContainer(
      overrides: [
        authStateStreamProvider.overrideWith((ref) => stream),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('resolves the uid from the auth stream', () async {
    final container = containerWith(Stream.value(userA));

    // Wait for the stream to emit so the provider is not in its loading state.
    await container.read(authStateStreamProvider.future);

    expect(container.read(currentUidProvider), 'user-a');
  });

  test('is null when the auth stream reports a signed-out user', () async {
    final container = containerWith(Stream.value(null));

    await container.read(authStateStreamProvider.future);

    expect(container.read(currentUidProvider), isNull);
  });

  test('follows auth state changes across an account switch', () async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);
    final container = containerWith(controller.stream);

    controller.add(userA);
    await container.read(authStateStreamProvider.future);
    expect(container.read(currentUidProvider), 'user-a');

    // Sign out, then sign in as a different user.
    controller.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentUidProvider), isNull);

    controller.add(userB);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentUidProvider), 'user-b');
  });
}
