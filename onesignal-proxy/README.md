# OneSignal Notification Proxy

A tiny Vercel serverless function that sits between the Flutter app and the
OneSignal REST API. It:

1. Verifies the sender's Firebase ID token (via `firebase-admin`).
2. Builds notification copy from server-side templates (so the client cannot
   push arbitrary text).
3. Forwards the request to OneSignal targeting recipients by their
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
