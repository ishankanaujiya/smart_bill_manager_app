import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_bill_manager/features/notifications/domain/repositories/notification_repository.dart';
import 'package:smart_bill_manager/features/notifications/presentation/state/notification_providers.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late _MockNotificationRepository repo;
  late NotificationActions actions;

  setUp(() {
    repo = _MockNotificationRepository();
    actions = NotificationActions(repo);
  });

  test('markAsRead delegates to the repository', () async {
    when(() => repo.markAsRead('n1')).thenAnswer((_) async {});

    await actions.markAsRead('n1');

    verify(() => repo.markAsRead('n1')).called(1);
  });

  test('markAllAsRead delegates to the repository', () async {
    when(() => repo.markAllAsRead('u1')).thenAnswer((_) async {});

    await actions.markAllAsRead('u1');

    verify(() => repo.markAllAsRead('u1')).called(1);
  });
}
