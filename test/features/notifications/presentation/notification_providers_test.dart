import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/features/groups/presentation/state/group_providers.dart';
import 'package:smart_bill_manager/features/notifications/domain/entities/app_notification.dart';
import 'package:smart_bill_manager/features/notifications/domain/repositories/notification_repository.dart';
import 'package:smart_bill_manager/features/notifications/presentation/state/notification_providers.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late _MockNotificationRepository repo;

  setUp(() {
    repo = _MockNotificationRepository();
  });

  AppNotification notification(String id, {bool read = false}) =>
      AppNotification(
        id: id,
        userId: 'u1',
        type: 'billCreated',
        title: 'Title $id',
        body: 'Body $id',
        createdAt: DateTime(2026, 1, 1),
        read: read,
      );

  ProviderContainer containerWith(
    List<AppNotification> items, {
    String? uid = 'u1',
  }) {
    when(() => repo.watchNotificationsForUser('u1'))
        .thenAnswer((_) => Stream.value(items));
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue(uid),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('streams the notifications for the signed-in user', () async {
    final container = containerWith([notification('a'), notification('b')]);

    final list =
        await container.read(notificationsForCurrentUserProvider.future);

    expect(list.map((n) => n.id), ['a', 'b']);
  });

  test('unreadNotificationCountProvider counts only unread items', () async {
    final container = containerWith([
      notification('a'),
      notification('b', read: true),
      notification('c'),
    ]);

    await container.read(notificationsForCurrentUserProvider.future);

    expect(container.read(unreadNotificationCountProvider), 2);
  });

  test('returns an empty list and zero count when signed out', () async {
    final container = containerWith([notification('a')], uid: null);

    final list =
        await container.read(notificationsForCurrentUserProvider.future);

    expect(list, isEmpty);
    expect(container.read(unreadNotificationCountProvider), 0);
    verifyNever(() => repo.watchNotificationsForUser(any()));
  });
}
