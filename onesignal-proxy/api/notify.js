/**
 * Vercel serverless function — POST /api/notify
 *
 * Accepts a notification dispatch request from the Smart Bill Manager Flutter
 * app, verifies the sender's Firebase ID token, builds a notification payload
 * from server-side templates (so no arbitrary text can be pushed from the
 * client), and forwards it to the OneSignal REST API targeting the recipient
 * users' devices via their OneSignal external_id (= Firebase UID).
 *
 * Required environment variables (set in the Vercel dashboard):
 *   ONESIGNAL_APP_ID        — OneSignal App ID
 *   ONESIGNAL_REST_API_KEY  — OneSignal REST API key (Settings → Keys & IDs)
 *   FIREBASE_SERVICE_ACCOUNT — Full Firebase service-account JSON (one line)
 *
 * Request body (JSON):
 *   {
 *     "type":          string,   // one of the NotificationType values below
 *     "targetUserIds": string[], // Firebase UIDs of recipient users
 *     "params":        object    // template parameters (see TEMPLATES)
 *   }
 *
 * Response:
 *   200 { "ok": true }              — notification dispatched (best-effort)
 *   400 { "error": "..." }          — bad request
 *   401 { "error": "..." }          — missing / invalid token
 *   403 { "error": "..." }          — token valid but sender excluded
 *   405 { "error": "..." }          — method not allowed
 */

'use strict';

const https = require('https');

// ── firebase-admin (lazy singleton) ─────────────────────────────────────────

let _adminApp = null;

function getAdmin() {
  if (_adminApp) return _adminApp;

  const admin = require('firebase-admin');
  if (admin.apps.length === 0) {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT env var is not set');
    const serviceAccount = JSON.parse(raw);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
  _adminApp = admin;
  return _adminApp;
}

// ── Notification templates ───────────────────────────────────────────────────
// All user-visible copy lives here. The client can only influence the
// *parameters* listed for each type — it cannot inject free-form text.

const TEMPLATES = {
  groupAdded: {
    title: ({ groupName }) => `Added to "${groupName}"`,
    body: ({ actorName, groupName }) =>
      `${actorName} added you to the group "${groupName}".`,
    data: ({ groupId }) => ({ type: 'groupAdded', groupId: groupId ?? '' }),
  },
  billCreated: {
    title: ({ groupName }) => `New bill in "${groupName}"`,
    body: ({ actorName, billTitle, amount }) =>
      `${actorName} created a bill "${billTitle}" for NPR ${amount}.`,
    data: ({ groupId, billId }) => ({
      type: 'billCreated',
      groupId: groupId ?? '',
      billId: billId ?? '',
    }),
  },
  paymentRequested: {
    title: ({ billTitle }) => `Payment request — "${billTitle}"`,
    body: ({ actorName, billTitle }) =>
      `${actorName} has submitted a payment request for "${billTitle}".`,
    data: ({ groupId, billId }) => ({
      type: 'paymentRequested',
      groupId: groupId ?? '',
      billId: billId ?? '',
    }),
  },
  paymentApproved: {
    title: ({ billTitle }) => `Payment approved — "${billTitle}"`,
    body: ({ actorName, billTitle }) =>
      `Your payment request for "${billTitle}" was approved.`,
    data: ({ groupId, billId }) => ({
      type: 'paymentApproved',
      groupId: groupId ?? '',
      billId: billId ?? '',
    }),
  },
  paymentRejected: {
    title: ({ billTitle }) => `Payment rejected — "${billTitle}"`,
    body: ({ actorName, billTitle }) =>
      `Your payment request for the bill "${billTitle}" was rejected. Please resubmit.`,
    data: ({ groupId, billId }) => ({
      type: 'paymentRejected',
      groupId: groupId ?? '',
      billId: billId ?? '',
    }),
  },
  paymentReminder: {
    title: ({ billTitle }) => `Payment reminder — "${billTitle}"`,
    body: ({ actorName, billTitle, groupName }) =>
      `Your payment for the bill named "${billTitle}" in ${groupName} is still pending. Please settle the outstanding amount at your earliest convenience`,
    data: ({ groupId, billId }) => ({
      type: 'paymentReminder',
      groupId: groupId ?? '',
      billId: billId ?? '',
    }),
  },
};

// ── OneSignal REST call ──────────────────────────────────────────────────────

function sendOneSignalNotification(payload) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);
    const options = {
      hostname: 'api.onesignal.com',
      path: '/notifications',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        Authorization: `Basic ${process.env.ONESIGNAL_REST_API_KEY}`,
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Main handler ─────────────────────────────────────────────────────────────

module.exports = async function handler(req, res) {
  // CORS preflight
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // ── 1. Verify Firebase ID token ──────────────────────────────────────────
  const authHeader = req.headers['authorization'] ?? '';
  const match = authHeader.match(/^Bearer (.+)$/i);
  if (!match) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }
  const idToken = match[1];

  let decodedToken;
  try {
    const admin = getAdmin();
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (err) {
    console.error('[notify] Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired Firebase ID token' });
  }

  // ── 2. Parse and validate the request body ───────────────────────────────
  const { type, targetUserIds, params = {} } = req.body ?? {};

  if (!type || typeof type !== 'string') {
    return res.status(400).json({ error: '"type" is required and must be a string' });
  }
  if (!Array.isArray(targetUserIds) || targetUserIds.length === 0) {
    return res.status(400).json({ error: '"targetUserIds" must be a non-empty array' });
  }
  if (!TEMPLATES[type]) {
    return res.status(400).json({ error: `Unknown notification type: ${type}` });
  }

  // Exclude the acting user from recipients (safety guard; client already does
  // this, but we enforce it server-side too).
  const senderUid = decodedToken.uid;
  const recipients = targetUserIds.filter((id) => id !== senderUid);
  if (recipients.length === 0) {
    // No recipients left after filtering — not an error; just a no-op.
    return res.status(200).json({ ok: true, skipped: true });
  }

  // ── 3. Build notification payload from template ──────────────────────────
  const template = TEMPLATES[type];
  const title = template.title(params);
  const body = template.body(params);
  const data = template.data(params);

  const oneSignalPayload = {
    app_id: process.env.ONESIGNAL_APP_ID,
    include_external_user_ids: recipients,
    // target_channel tells OneSignal to use push subscriptions when addressing
    // by external_id (required when using include_external_user_ids in v11+).
    target_channel: 'push',
    headings: { en: title },
    contents: { en: body },
    data,
  };

  // ── 4. Forward to OneSignal (best-effort) ────────────────────────────────
  try {
    const result = await sendOneSignalNotification(oneSignalPayload);
    if (result.status >= 400) {
      // Log but don't fail the client request — notification delivery is
      // best-effort and must not block the user-facing operation.
      console.error('[notify] OneSignal error:', result.status, JSON.stringify(result.body));
    }
  } catch (err) {
    console.error('[notify] Failed to reach OneSignal:', err.message);
    // Still return 200 to the client.
  }

  return res.status(200).json({ ok: true });
};
