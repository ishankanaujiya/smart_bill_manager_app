import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification types
// ─────────────────────────────────────────────────────────────────────────────

/// The set of events that can trigger a push notification.
///
/// These values must match the keys in the `TEMPLATES` map inside
/// `onesignal-proxy/api/notify.js`.
enum NotificationType {
  /// A user was added to a new group.
  groupAdded,

  /// A new bill was created in a group.
  billCreated,

  /// A group member submitted a payment request.
  paymentRequested,

  /// The bill creator approved a payment request.
  paymentApproved,

  /// The bill creator rejected a payment request.
  paymentRejected,
}

extension _NotificationTypeX on NotificationType {
  String get value => switch (this) {
        NotificationType.groupAdded => 'groupAdded',
        NotificationType.billCreated => 'billCreated',
        NotificationType.paymentRequested => 'paymentRequested',
        NotificationType.paymentApproved => 'paymentApproved',
        NotificationType.paymentRejected => 'paymentRejected',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Dispatcher
// ─────────────────────────────────────────────────────────────────────────────

/// Fire-and-forget push notification dispatcher.
///
/// Fetches a fresh Firebase ID token and POSTs to the Vercel proxy which
/// verifies the token, builds notification copy from server-side templates,
/// and forwards to the OneSignal REST API.
///
/// **All errors are swallowed.** Notification delivery is best-effort and
/// must never block or affect the user-facing operation that triggered the
/// event.
class NotificationDispatcher {
  const NotificationDispatcher();

  /// Dispatches a push notification of [type] to [targetUserIds].
  ///
  /// [params] must contain the template parameters expected by the proxy for
  /// the given [type] — see `onesignal-proxy/README.md` for the full list.
  ///
  /// The current user is excluded from [targetUserIds] server-side as well,
  /// but callers should also filter them out before calling to avoid a
  /// wasted network round-trip.
  Future<void> dispatch({
    required NotificationType type,
    required List<String> targetUserIds,
    Map<String, String> params = const {},
  }) async {
    debugPrint('[NotificationDispatcher] dispatch called: type=$type, '
        'targetUserIds=$targetUserIds, params=$params');

    if (targetUserIds.isEmpty) {
      debugPrint('[NotificationDispatcher] no target users — skipping');
      return;
    }

    // Skip during tests / when proxy URL is not configured yet.
    if (NotificationService.proxyBaseUrl.contains('YOUR_VERCEL_URL')) {
      debugPrint(
        '[NotificationDispatcher] proxyBaseUrl is not configured yet — '
        'skipping $type notification.',
      );
      return;
    }

    try {
      // 1. Fetch a fresh Firebase ID token (cached by the SDK; auto-refreshed
      //    when it is within 5 minutes of expiry).
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[NotificationDispatcher] no current user — skipping');
        return;
      }
      final idToken = await user.getIdToken();
      if (idToken == null) {
        debugPrint('[NotificationDispatcher] idToken is null — skipping');
        return;
      }
      debugPrint('[NotificationDispatcher] got Firebase ID token '
          '(${idToken.length} chars), sending to proxy...');

      // 2. POST to the Vercel proxy (fire-and-forget).
      final uri = Uri.parse('${NotificationService.proxyBaseUrl}/api/notify');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'type': type.value,
              'targetUserIds': targetUserIds,
              'params': params,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('[NotificationDispatcher] proxy response: '
          '${response.statusCode} — ${response.body}');

      if (response.statusCode >= 400) {
        debugPrint(
          '[NotificationDispatcher] proxy returned ${response.statusCode}: '
          '${response.body}',
        );
      }
    } catch (e) {
      // Never surface notification errors to the user — delivery is
      // best-effort and must not interfere with the main operation.
      debugPrint('[NotificationDispatcher] dispatch failed ($type): $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [NotificationDispatcher] instance.
final notificationDispatcherProvider = Provider<NotificationDispatcher>((ref) {
  return const NotificationDispatcher();
});
