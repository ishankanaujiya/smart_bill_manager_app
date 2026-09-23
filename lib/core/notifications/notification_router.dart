import 'package:flutter/material.dart';

import '../../features/expenses/data/repositories/bill_repository_impl.dart';
import '../../features/expenses/domain/repositories/bill_repository.dart';
import '../../features/expenses/presentation/view/bill_details_screen.dart';
import '../../features/groups/data/repositories/group_repository_impl.dart';
import '../../features/groups/domain/repositories/group_repository.dart';
import '../../features/groups/presentation/view/group_details_screen.dart';

/// Resolves a notification's navigation payload to the screen it should open.
///
/// Used both by push-notification taps (see [NotificationService]) and by
/// in-app notification rows, so a given notification `type` always resolves to
/// the same destination regardless of where it was tapped.
///
/// Payload shape (matches the `data` object sent to OneSignal by the proxy):
/// - `type`    : String  (e.g. `groupAdded`, `billCreated`, ...)
/// - `groupId` : String? (required for `groupAdded` and every bill type)
/// - `billId`  : String? (required for every bill type)
class NotificationRouter {
  NotificationRouter({
    GroupRepository? groupRepository,
    BillRepository? billRepository,
  })  : _groupRepositoryOverride = groupRepository,
        _billRepositoryOverride = billRepository;

  final GroupRepository? _groupRepositoryOverride;
  final BillRepository? _billRepositoryOverride;

  // Resolved lazily so that constructing a router (e.g. as a field of a
  // singleton) never touches Firebase — important for tests.
  GroupRepository get _groupRepository =>
      _groupRepositoryOverride ?? GroupRepositoryImpl();
  BillRepository get _billRepository =>
      _billRepositoryOverride ?? BillRepositoryImpl();

  /// Opens the destination described by [data] on [nav].
  ///
  /// Returns `true` when a screen was pushed. Silently does nothing (returns
  /// `false`) when the payload is incomplete, the target no longer exists, or
  /// an error occurs — notification navigation must never crash the app.
  Future<bool> open({
    required NavigatorState nav,
    required String currentUserId,
    required Map<String, dynamic> data,
  }) async {
    final type = data['type'] as String?;
    if (type == null) return false;

    try {
      if (type == 'groupAdded') {
        final groupId = data['groupId'] as String?;
        if (groupId == null || groupId.isEmpty) return false;
        return _pushGroupDetails(
          nav: nav,
          groupId: groupId,
          currentUserId: currentUserId,
        );
      }

      // All bill-related types require both groupId and billId.
      final groupId = data['groupId'] as String?;
      final billId = data['billId'] as String?;
      if (groupId == null ||
          groupId.isEmpty ||
          billId == null ||
          billId.isEmpty) {
        return false;
      }

      return _pushBillDetails(
        nav: nav,
        groupId: groupId,
        billId: billId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('[NotificationRouter] open error: $e');
      return false;
    }
  }

  Future<bool> _pushGroupDetails({
    required NavigatorState nav,
    required String groupId,
    required String currentUserId,
  }) async {
    final group = await _groupRepository.getGroup(groupId);
    if (group == null) return false;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailsScreen(
          group: group,
          currentUserId: currentUserId,
        ),
      ),
    );
    return true;
  }

  Future<bool> _pushBillDetails({
    required NavigatorState nav,
    required String groupId,
    required String billId,
    required String currentUserId,
  }) async {
    final bill = await _billRepository.getBill(groupId, billId);
    if (bill == null) return false;

    // BillDetailsScreen can stand alone — push it directly.
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => BillDetailsScreen(
          bill: bill,
          currentUserId: currentUserId,
        ),
      ),
    );
    return true;
  }
}
