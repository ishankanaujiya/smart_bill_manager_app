import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../features/expenses/data/repositories/bill_repository_impl.dart';
import '../../features/expenses/presentation/view/bill_details_screen.dart';
import '../../features/groups/data/repositories/group_repository_impl.dart';
import '../../features/groups/presentation/view/group_details_screen.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _oneSignalAppId =
      '23e8d468-eca9-429a-aee2-5b6084d787c4';

  /// Base URL of the Vercel notification proxy.
  ///
  /// Update this to your deployed Vercel URL after running `vercel --prod`
  /// inside the `onesignal-proxy/` folder.
  ///
  /// Example: 'https://smartbill-notify.vercel.app'
  static const String proxyBaseUrl = 'https://smartbillmanagerapp.vercel.app';

  Future<void> initialize() async {
    debugPrint('[NotificationService] initialize() called');
    await OneSignal.initialize(_oneSignalAppId);
    debugPrint('[NotificationService] OneSignal initialized with appId=$_oneSignalAppId');

    // Request notification permission.
    //
    // For initial development/testing this is fine.
    // Later we can move this behind your own "Enable Notifications"
    // UI so the permission dialog isn't shown immediately on startup.
    final granted = await OneSignal.Notifications.requestPermission(false);
    debugPrint('[NotificationService] notification permission granted=$granted');
  }

  /// Tags this device's OneSignal subscription with the given Firebase [uid]
  /// as the external_id. This allows OneSignal to deliver notifications to
  /// all devices where the same user is signed in.
  ///
  /// Call after a successful sign-in and on cold start when a session is
  /// already active.
  Future<void> login(String uid) async {
    debugPrint('[NotificationService] login(uid=$uid) called');
    try {
      await OneSignal.login(uid);
      debugPrint('[NotificationService] OneSignal.login succeeded for uid=$uid');
    } catch (e) {
      // Non-fatal: the user can still use the app without notifications.
      debugPrint('[NotificationService] login failed: $e');
    }
  }

  /// Removes the external_id tag from this device's OneSignal subscription.
  ///
  /// Call before signing out so this device no longer receives push
  /// notifications for the signed-out user.
  Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('[NotificationService] logout failed: $e');
    }
  }

  /// Registers the OneSignal notification-click listener.
  ///
  /// When the user taps a push notification the app navigates to the
  /// relevant screen:
  ///   - `groupAdded`                        → Groups tab (AppShell index 1)
  ///   - `billCreated` / `paymentRequested`
  ///     / `paymentApproved` / `paymentRejected` → Bill details screen
  ///
  /// Must be called **after** [runApp] so that [navigatorKey] is attached
  /// to the widget tree.
  void setupClickHandler(GlobalKey<NavigatorState> navigatorKey) {
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationClick(
        data: event.notification.additionalData ?? {},
        navigatorKey: navigatorKey,
      );
    });
  }

  Future<void> _handleNotificationClick({
    required Map<String, dynamic> data,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    final type = data['type'] as String?;
    if (type == null) return;

    // Wait briefly for the navigator to be ready (cold-start delay).
    NavigatorState? nav;
    for (var i = 0; i < 10; i++) {
      nav = navigatorKey.currentState;
      if (nav != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (nav == null) {
      debugPrint('[NotificationService] navigator not ready — tap ignored');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // user signed out — don't navigate

    try {
      if (type == 'groupAdded') {
        // Navigate to the Groups tab inside AppShell. We push a lightweight
        // marker widget that replaces itself with GroupDetailsScreen once the
        // group is loaded, but the simplest approach is to just ensure the
        // user is on the Groups tab. We navigate to GroupDetailsScreen
        // directly if groupId is provided and we can load the group.
        final groupId = data['groupId'] as String?;
        if (groupId != null && groupId.isNotEmpty) {
          await _pushGroupDetails(
            nav: nav,
            groupId: groupId,
            currentUserId: uid,
          );
        }
        // If groupId is missing, tapping just opens the app — acceptable.
        return;
      }

      // All bill-related types require both groupId and billId.
      final groupId = data['groupId'] as String?;
      final billId = data['billId'] as String?;
      if (groupId == null || groupId.isEmpty || billId == null || billId.isEmpty) {
        return;
      }

      await _pushBillDetails(
        nav: nav,
        groupId: groupId,
        billId: billId,
        currentUserId: uid,
      );
    } catch (e) {
      debugPrint('[NotificationService] _handleNotificationClick error: $e');
    }
  }

  Future<void> _pushGroupDetails({
    required NavigatorState nav,
    required String groupId,
    required String currentUserId,
  }) async {
    final repo = GroupRepositoryImpl();
    final group = await repo.getGroup(groupId);
    if (group == null) return;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailsScreen(
          group: group,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  Future<void> _pushBillDetails({
    required NavigatorState nav,
    required String groupId,
    required String billId,
    required String currentUserId,
  }) async {
    final billRepo = BillRepositoryImpl();
    final bill = await billRepo.getBill(groupId, billId);
    if (bill == null) return;

    // We also need a Group to open GroupDetailsScreen as a parent, but
    // BillDetailsScreen can stand alone — push it directly.
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => BillDetailsScreen(
          bill: bill,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}
