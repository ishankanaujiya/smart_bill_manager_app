# OneSignal Notification Proxy

A tiny Vercel serverless function that sits between the Flutter app and the
OneSignal REST API. It:

1. Verifies the sender's Firebase ID token (via `firebase-admin`).
2. Builds notification copy from server-side templates (so the client cannot
   push arbitrary text).
3. Persists one document per recipient into the Firestore `notifications`
   collection (the app's in-app inbox).
4. Forwards the request to OneSignal targeting recipients by their
   `external_id` (= Firebase UID).

## Deploy to Vercel (one-time setup)

### Prerequisites
- A free [Vercel](https://vercel.com) account.
- The [Vercel CLI](https://vercel.com/docs/cli): `npm i -g vercel`.

### Steps

1. **Create a Vercel project pointing at this folder:**

   ```bash
   cd onesignal-proxy
   vercel
   ```

   - When asked for the root directory, confirm `onesignal-proxy` (or `.` if
     you're already in it).
   - Framework preset: **Other**.

2. **Set environment variables** in the Vercel dashboard
   (Project → Settings → Environment Variables):

   | Variable | Value |
   |---|---|
   | `ONESIGNAL_APP_ID` | `23e8d468-eca9-429a-aee2-5b6084d787c4` |
   | `ONESIGNAL_REST_API_KEY` | Your OneSignal REST API key (dashboard → Settings → Keys & IDs) |
   | `FIREBASE_SERVICE_ACCOUNT` | The full service-account JSON as a **single-line string** (Firebase console → Project settings → Service accounts → Generate new private key) |

   > **Security:** Never commit the service account key or REST API key to the
   > repository. They must only live in Vercel's encrypted environment variables.

3. **Deploy:**

   ```bash
   vercel --prod
   ```

   Note the production URL (e.g. `https://smartbill-notify.vercel.app`).

4. **Update the Flutter app** — set `NotificationDispatcher.proxyBaseUrl` in
   `lib/core/notifications/notification_dispatcher.dart` to the production URL.

## Local testing

```bash
cd onesignal-proxy
npm install
vercel dev
```

Then in another terminal:

```bash
# Should return 401
curl -X POST http://localhost:3000/api/notify \
  -H "Content-Type: application/json" \
  -d '{}'

# With a valid Firebase ID token
curl -X POST http://localhost:3000/api/notify \
  -H "Authorization: Bearer <FIREBASE_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "groupAdded",
    "targetUserIds": ["<RECIPIENT_UID>"],
    "params": {
      "actorName": "Alice",
      "groupName": "Trip to Pokhara",
      "groupId": "<GROUP_ID>"
    }
  }'
```

## Notification types and parameters

| `type` | Required `params` |
|---|---|
| `groupAdded` | `actorName`, `groupName`, `groupId` |
| `billCreated` | `actorName`, `groupName`, `billTitle`, `amount`, `groupId`, `billId` |
| `paymentRequested` | `actorName`, `billTitle`, `groupId`, `billId` |
| `paymentApproved` | `actorName`, `billTitle`, `groupId`, `billId` |
| `paymentRejected` | `actorName`, `billTitle`, `groupId`, `billId` |
| `paymentReminder` | `actorName`, `billTitle`, `groupName`, `groupId`, `billId` |

## Firestore inbox (`notifications`)

For every accepted request the proxy writes **one document per recipient**
into the top-level `notifications` collection, so the app can show an in-app
notification list (the home-screen bell icon). Document shape:

| Field | Type | Notes |
|---|---|---|
| `user_id` | String | Recipient's Firebase UID — the app queries on this field. |
| `type` | String | One of the `type` values above. |
| `title` | String | Rendered heading. |
| `body` | String | Rendered body. |
| `group_id` | String \| null | For navigation. |
| `bill_id` | String \| null | For navigation. |
| `read` | Boolean | Always `false` on create; the app flips it to `true`. |
| `created_at` | Timestamp | Server timestamp. |

- Documents are written with the **Admin SDK**, which bypasses Firestore
  security rules. Clients can only read / mark-as-read their own documents
  (see the `notifications` block in `firestore.rules`).
- The write is **best-effort**: a Firestore failure is logged and never
  prevents the push from being delivered.
- The app's list query is `where user_id == uid` only (sorted newest-first in
  memory), so it needs **no composite index** — Firestore's automatic
  single-field index is enough. `firestore.indexes.json` stays empty.

> **Remember to redeploy** (`vercel --prod`) after changing this function,
> otherwise new notifications are pushed but never stored in the inbox.
