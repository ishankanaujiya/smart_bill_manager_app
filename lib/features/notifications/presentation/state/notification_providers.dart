import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_router.dart';
import '../../../groups/presentation/state/group_providers.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [NotificationRepository] instance.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

/// Provides the [NotificationRouter] used to open a notification's target.
///
/// Overridable in tests so tapping a row never touches Firebase.
final notificationRouterProvider = Provider<NotificationRouter>((ref) {
  return NotificationRouter();
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifications for the current user
// ─────────────────────────────────────────────────────────────────────────────

/// Streams the notifications addressed to the currently signed-in user.
///
/// Returns an empty list when there is no signed-in user. Emits a fresh list
/// whenever a matching document changes, so the inbox (and the unread badge)
/// stay in sync with the backend in real time.
final notificationsForCurrentUserProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream.value(<AppNotification>[]);
  }
  return ref.read(notificationRepositoryProvider).watchNotificationsForUser(uid);
});

/// The number of unread notifications for the currently signed-in user.
///
/// Derived from [notificationsForCurrentUserProvider]; defaults to 0 while
/// loading, on error, or when signed out.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsForCurrentUserProvider);
  return async.valueOrNull?.where((n) => !n.read).length ?? 0;
});

// ─────────────────────────────────────────────────────────────────────────────
// Actions
// ─────────────────────────────────────────────────────────────────────────────

/// Encapsulates the write actions available on the notification inbox.
///
/// Kept as a thin, injectable wrapper over [NotificationRepository] so the
/// read/unread transitions can be unit-tested with a mocked repository.
class NotificationActions {
  const NotificationActions(this._repository);

  final NotificationRepository _repository;

  /// Marks a single notification as read.
  Future<void> markAsRead(String id) => _repository.markAsRead(id);

  /// Marks every unread notification of the user with [uid] as read.
  Future<void> markAllAsRead(String uid) => _repository.markAllAsRead(uid);
}

/// Provides the [NotificationActions] instance.
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref.read(notificationRepositoryProvider));
});
