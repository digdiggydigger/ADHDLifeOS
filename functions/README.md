# Capture endpoint

The Firebase replacement for the retired AWS `POST /captures` route. The iOS Shortcut posts here;
this writes the capture into Firestore (and Storage, for photo and voice) so it appears in the app's
Inbox.

Claude Code has no Firebase CLI auth, so **E deploys this** — the same manual-step convention as
`firestore.rules`.

## Deploy

Requires the **Blaze** plan; Firebase will not deploy functions on Spark.

```bash
cd functions
npm install

# One-time: the shared secret the Shortcut sends, and the account captures are written to.
# Pick something long and random for the secret — a password manager's generator is ideal.
firebase functions:secrets:set CAPTURE_SECRET
firebase deploy --only functions
```

`CAPTURE_UID` is a plain param, not a secret. Set it once in `.env` beside this file (gitignored):

```
CAPTURE_UID=xcKeMrUiFoZRGQOEUMNW8y6aXmc2
```

Deploy prints the function URL. It is normally:

```
https://us-central1-adhdlifeos-acb49.cloudfunctions.net/capture
```

If it prints something different, use what it printed — the Shortcut has that URL in one Text action.

## Contract

`POST` with `Content-Type: application/json` and `X-LifeOS-Key: <CAPTURE_SECRET>`.

```jsonc
{
  "kind": "note",              // note | task | link | voice | photo — defaults to note
  "content": "Ring the dentist",
  "title": "optional",
  "lifeAreaId": "optional UUID",
  "media": {                   // required for voice/photo, rejected for the rest
    "data": "<base64>",
    "contentType": "image/jpeg"
  }
}
```

Responses: `201 {id, kind}` · `400` bad payload · `401` bad/missing key · `413` media over 20 MB ·
`500` server not configured · `502` Firebase write failed.

## Why a shared secret and not a Firebase ID token

A Shortcut cannot refresh an expiring token unattended, and this is a single-user personal app. The
secret lives in Secret Manager and in the Shortcut on E's device; rotate it with
`firebase functions:secrets:set CAPTURE_SECRET` followed by a redeploy, and update the Shortcut.

**The endpoint fails closed.** `secretMatches('', '')` is legitimately `true` — two empty strings are
equal — so a deploy that forgot to attach the secret would otherwise have accepted anyone who simply
omitted the header. An unset secret now returns `500` to every caller instead.

## The document contract, and the trap in it

`Capture` (`ADHD LifeOS/Capture/CaptureModels.swift`) is decoded straight off the Firestore
document, so a wrong key name does not error — it silently drops the field.

- **Only `created_at` is snake_cased.** `lifeAreaId`, `mediaURL` and `mediaContentType` stay
  camelCase, because that is what Swift's synthesized encoder produces.
- `created_at` must be a real Firestore `Timestamp`, not a string.
- **The document name and the `id` field must be identical.** The app addresses a capture by the id
  it decoded out of the body (`markProcessed`), so if they ever diverge, triage silently stops
  working on Shortcut-written captures.
- Absent optionals are omitted rather than written as `null`, matching the app's own encoder.
- Media objects go to `users/{uid}/captures/{lowercase-uuid}.{ext}`, the same layout
  `FirebaseManager.makeUploadTarget` uses, so the account-deletion sweep and the Storage rules keep
  working on Shortcut-written media.

All of the above is pinned by `test/capture.test.js`.

## Tests

```bash
cd functions && npm test
```

28 tests, no credentials needed: the document mapping, payload validation, the Storage path and
download-URL construction, and the handler's method/auth/validation paths — everything that runs
before Firebase is touched. The success path writes to Firestore and Storage, so it is verified
against the real project after deployment rather than mocked into a shape that proves nothing.
