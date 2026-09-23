import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/core/notifications/notification_router.dart';
import 'package:smart_bill_manager/features/groups/presentation/state/group_providers.dart';
import 'package:smart_bill_manager/features/notifications/domain/entities/app_notification.dart';
import 'package:smart_bill_manager/features/notifications/domain/repositories/notification_repository.dart';
import 'package:smart_bill_manager/features/notifications/presentation/state/notification_providers.dart';
import 'package:smart_bill_manager/features/notifications/presentation/view/notifications_screen.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

/// Records the last [open] call instead of touching Firebase, so the tap
/// handler can be exercised without a real Firestore.
class _FakeNotificationRouter implements NotificationRouter {
  String? lastUserId;
  Map<String, dynamic>? lastData;

  @override
  Future<bool> open({
    required NavigatorState nav,
    required String currentUserId,
    required Map<String, dynamic> data,
  }) async {
    lastUserId = currentUserId;
    lastData = data;
    return true;
  }
}

void main() {
  late _MockNotificationRepository repo;
  late _FakeNotificationRouter router;

  setUp(() {
    repo = _MockNotificationRepository();
    router = _FakeNotificationRouter();
  });

  AppNotification notification(
    String id, {
    bool read = false,
    String type = 'billCreated',
  }) =>
      AppNotification(
        id: id,
        userId: 'u1',
        type: type,
        title: 'Title $id',
        body: 'Body $id',
        createdAt: DateTime(2026, 1, 1),
        read: read,
        groupId: 'g1',
        billId: 'b1',
      );

  Widget wrap(List<AppNotification> items) {
    when(() => repo.watchNotificationsForUser('u1'))
        .thenAnswer((_) => Stream.value(items));
    return ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWithValue('u1'),
        notificationRouterProvider.overrideWithValue(router),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('renders the notifications list', (tester) async {
    await tester.pumpWidget(wrap([notification('a'), notification('b')]));
    await settle(tester);

    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Title b'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no notifications',
      (tester) async {
    await tester.pumpWidget(wrap(const []));
    await settle(tester);

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('shows the unread count in the header', (tester) async {
    await tester.pumpWidget(
      wrap([notification('a'), notification('b', read: true)]),
    );
    await settle(tester);

    expect(find.text('1 unread'), findsOneWidget);
  });

  testWidgets('marks a notification read and opens its target on tap',
      (tester) async {
    when(() => repo.markAsRead('a')).thenAnswer((_) async {});

    await tester.pumpWidget(wrap([notification('a')]));
    await settle(tester);

    await tester.tap(find.text('Title a'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => repo.markAsRead('a')).called(1);
    expect(router.lastUserId, 'u1');
    expect(router.lastData, containsPair('type', 'billCreated'));
    expect(router.lastData, containsPair('groupId', 'g1'));
    expect(router.lastData, containsPair('billId', 'b1'));
  });

  testWidgets('does not mark an already-read notification again on tap',
      (tester) async {
    await tester.pumpWidget(wrap([notification('a', read: true)]));
    await settle(tester);

    await tester.tap(find.text('Title a'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verifyNever(() => repo.markAsRead(any()));
  });
}
