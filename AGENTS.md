# Project notes for agents

## Verification

```bash
flutter analyze                 # must report "No issues found!"
flutter test                    # full suite
flutter test <path/to/test.dart>  # a single test file
```

Tests use `flutter_test` + `mocktail`. They deliberately avoid real Firebase and
platform channels (no `Firebase.initializeApp`), so anything touching
`FirebaseAuth.instance`, `FirebaseFirestore.instance`, or secure storage must be
stubbed/overridden in tests — override the Riverpod provider with a mock or a
stub.

Widget tests for screens with perpetual `repeat()` animations must use
fixed-duration `tester.pump(...)` calls instead of `pumpAndSettle`.

## Formatting

`dart format` is **not** applied repo-wide — several large files (e.g.
`lib/features/expenses/presentation/view/bill_details_screen.dart`,
`bill_providers.dart`, `bill.dart`) are not format-clean. Do not run
`dart format` on them, as it produces large unrelated diffs. Match the
surrounding style manually.

## Push notifications

Notifications go through a Vercel serverless proxy:

```
app (NotificationDispatcher) → POST /api/notify → OneSignal
```

- Client side: `lib/core/notifications/notification_dispatcher.dart`
  (`NotificationType` enum → wire value).
- Server side: `onesignal-proxy/api/notify.js` (`TEMPLATES` map). The proxy
  returns **400 Unknown notification type** for any type missing from
  `TEMPLATES`.
- When adding a notification type you must update **both** sides, add a row to
  `onesignal-proxy/README.md`, and **redeploy the proxy**
  (`cd onesignal-proxy && vercel --prod`). `NotificationDispatcher.dispatch`
  swallows non-2xx responses, so a missing deployment fails silently while the
  UI still reports success.
