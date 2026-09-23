import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../groups/presentation/state/group_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../state/notification_providers.dart';

/// Notification inbox screen.
///
/// Lists the notifications addressed to the signed-in user (newest first),
/// marks them read, and opens the related bill/group when a row is tapped.
/// Pushed from the home-screen bell icon.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Marks the tapped notification read, then opens its target screen.
  Future<void> _onTap(AppNotification notification) async {
    if (!notification.read) {
      // Best-effort: a failed write must not stop navigation.
      try {
        await ref
            .read(notificationActionsProvider)
            .markAsRead(notification.id);
      } catch (_) {
        // Ignore — the row still opens below.
      }
    }

    if (!mounted) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    await ref.read(notificationRouterProvider).open(
          nav: Navigator.of(context),
          currentUserId: uid,
          data: {
            'type': notification.type,
            'groupId': notification.groupId,
            'billId': notification.billId,
          },
        );
  }

  Future<void> _markAllAsRead() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await ref.read(notificationActionsProvider).markAllAsRead(uid);
    } catch (_) {
      // Best-effort — the list updates via the Firestore stream.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notificationsAsync = ref.watch(notificationsForCurrentUserProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colorScheme, unreadCount),
            Expanded(child: _buildBody(colorScheme, notificationsAsync)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme colorScheme, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: colorScheme.onSurface,
            tooltip: 'Back',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread'
                      : 'You are all caught up',
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Body
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    ColorScheme colorScheme,
    AsyncValue<List<AppNotification>> notificationsAsync,
  ) {
    return notificationsAsync.when(
      data: (notifications) => notifications.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildList(notifications, colorScheme),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildErrorState(colorScheme),
    );
  }

  Widget _buildList(
    List<AppNotification> notifications,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.xxxl,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return StaggeredEntrance(
          animation: _entrance,
          interval: Interval(
            (index * 0.05).clamp(0.0, 0.5),
            (0.4 + index * 0.05).clamp(0.2, 1.0),
            curve: Curves.easeOutCubic,
          ),
          slideOffset: 20,
          child: _NotificationTile(
            notification: notification,
            colorScheme: colorScheme,
            onTap: () => _onTap(notification),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No notifications yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Updates about your groups, bills and payments will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load notifications',
              style: AppTextStyles.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(notificationsForCurrentUserProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.colorScheme,
    required this.onTap,
  });

  final AppNotification notification;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _visualFor(notification.type);
    final unread = !notification.read;

    return Material(
      color: unread
          ? colorScheme.primaryContainer
              .withValues(alpha: isDark ? 0.16 : 0.35)
          : colorScheme.surfaceContainerHighest
              .withValues(alpha: isDark ? 0.30 : 0.5),
      borderRadius: AppRadius.radiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.16),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(visual.icon, color: visual.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Maps a notification `type` to its icon and accent colour.
({IconData icon, Color color}) _visualFor(String type) {
  return switch (type) {
    'groupAdded' => (icon: Icons.group_add_rounded, color: AppColors.chartBlue),
    'billCreated' => (
        icon: Icons.receipt_long_rounded,
        color: AppColors.chartTealLight,
      ),
    'paymentRequested' => (
        icon: Icons.payments_rounded,
        color: AppColors.chartOrange,
      ),
    'paymentApproved' => (
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
    'paymentRejected' => (icon: Icons.cancel_rounded, color: AppColors.error),
    'paymentReminder' => (
        icon: Icons.notifications_active_rounded,
        color: AppColors.warning,
      ),
    _ => (icon: Icons.notifications_rounded, color: AppColors.chartPurple),
  };
}

/// Human-friendly "time ago" label for a notification timestamp.
String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dateTime.month - 1]} ${dateTime.day}';
}
