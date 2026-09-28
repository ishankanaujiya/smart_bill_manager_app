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

## Google Sign-In (Android)

Android sign-in goes through the Credential Manager SDK
(`google_sign_in` 7.x → `google_sign_in_android`). The app does **not** pass a
`serverClientId` to `GoogleSignIn.instance.initialize()`; the plugin falls back
to the `default_web_client_id` string generated from the `client_type: 3`
(web) entry in `android/app/google-services.json`, so that file must keep a web
OAuth client entry.

Each **build configuration's signing certificate SHA-1** must be registered as
an Android OAuth client in the Firebase project (Console → Project settings →
Your apps → Android → *Add fingerprint*, or
`firebase apps:android:sha:create <appId> <sha1>`). This repo has two:

| Build    | Keystore                              | SHA-1 |
|----------|---------------------------------------|-------|
| debug    | `~/.android/debug.keystore`           | registered |
| release  | `android/app/upload-keystore.jks`     | **must be registered too** |

Release builds are signed with the upload keystore
(`android/app/build.gradle.kts` → `signingConfigs.release`), so its SHA-1 and
SHA-256 must both be registered or release builds fail sign-in.

**Symptom of a missing/incorrect SHA:** after the user picks a Google account,
`authenticate()` throws `GoogleSignInException(code: canceled)` — the Android
Credential Manager reports the config error as a cancellation, and the plugin
cannot tell the two apart. `AuthRepositoryImpl.signInWithGoogle` now logs the
raw code/description via `debugPrint` so these are diagnosable; check logcat for
`[AuthRepositoryImpl] Google sign-in failed:` before assuming the user really
cancelled.

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

## Notification inbox

Every dispatched push is mirrored into a top-level Firestore `notifications`
collection so the app can show an in-app inbox (home-screen bell icon →
`lib/features/notifications/presentation/view/notifications_screen.dart`).

- Server side: `onesignal-proxy/api/notify.js` writes **one document per
  recipient** (`user_id`, `type`, `title`, `body`, `group_id`, `bill_id`,
  `read`, `created_at`) using the Admin SDK. Best-effort — a Firestore failure
  never blocks the push. **Redeploy the proxy** for changes to take effect.
- Client side: `lib/features/notifications/` (entity → model → repository →
  providers → screen). The list query is `where('user_id', ==, uid)` only —
  ordering/limiting happens in memory — so **no composite index is required**
  and `firestore.indexes.json` stays empty.
- The inbox is scoped by `currentUidProvider`
  (`lib/features/groups/presentation/state/group_providers.dart`), which
  **watches `authStateStreamProvider`** so it stays correct across sign-out /
  sign-in. Do not revert it to a plain `FirebaseAuth.instance.currentUser`
  read — that caches the first uid for the container's lifetime (the app keeps
  one `ProviderScope`), so every per-user stream would show the previous
  user's data after an account switch. `currentAppUserProvider`
  (`lib/features/auth/presentation/state/auth_providers.dart`) follows the
  same rule for the user's profile document.
- Rules: the `notifications` block in `firestore.rules` allows a user to read
  only their own documents and to update **only** the `read` key; create/delete
  are denied (the Admin SDK bypasses rules).
- Tapping a row marks it read and opens the target screen via
  `lib/core/notifications/notification_router.dart` — the same router used by
  push-tap handling in `NotificationService`, so both stay consistent.
