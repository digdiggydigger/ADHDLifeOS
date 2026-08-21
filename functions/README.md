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

Deploy prints the function URL. A 2nd-gen function runs on Cloud Run, so in this project it is the
Cloud Run form rather than the `cloudfunctions.net` one:

```
https://capture-dg5rypfbaq-uc.a.run.app
```

If it prints something different, use what it printed — the Shortcut has that URL in one Text action.

## Deploying is not enough: three IAM grants the function cannot make for itself

A successful `firebase deploy` does **not** mean the endpoint works. All three of these were needed
before the first capture ever landed (2026-08-21), and each fails in a way that looks like a
different bug. On a fresh project, or after the runtime service account is changed, re-check them.

**1. Allow unauthenticated invocation.** 2nd-gen functions run on Cloud Run, and new projects do not
allow unauthenticated invocations by default. Without this the request never reaches this code at
all — Google Frontend returns `403` before the handler runs, so the shared-secret check is never
even consulted and the logs stay empty.

```bash
gcloud run services add-iam-policy-binding capture \
  --region=us-central1 --project=adhdlifeos-acb49 \
  --member="allUsers" --role="roles/run.invoker"
```

`allUsers` is safe here only because the handler's own `X-LifeOS-Key` check is the actual auth.

**2 and 3. Give the runtime service account data access.** The function runs as the *compute default*
service account (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`), and Google no longer grants
that account `Editor` on new projects — here it started with nothing but
`roles/cloudbuild.builds.builder`, which is build permission, not data permission.

```bash
gcloud projects add-iam-policy-binding adhdlifeos-acb49 \
  --member="serviceAccount:651724103525-compute@developer.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud storage buckets add-iam-policy-binding gs://adhdlifeos-acb49.firebasestorage.app \
  --member="serviceAccount:651724103525-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

Without the first, every capture returns `502 could not save the capture` and the logs show
`7 PERMISSION_DENIED: Missing or insufficient permissions` from Firestore. **That message is
misleading:** the Admin SDK bypasses security rules entirely, so it is never a `firestore.rules`
problem — do not go editing rules chasing it. Without the second, text captures succeed and only
`photo`/`voice` fail, with the same `502`, because media uploads to Storage before the document is
written.

IAM changes need no redeploy, but take up to a couple of minutes to propagate — two `502`s straight
after granting, then a `201`, is normal and not a sign of a further problem.

## Rotating the secret

```bash
firebase functions:secrets:set CAPTURE_SECRET   # creates a new version
firebase deploy --only functions:capture        # REQUIRED — see below
gcloud secrets versions destroy <old> --secret=CAPTURE_SECRET --project=adhdlifeos-acb49
```

The redeploy is not optional. `defineSecret` pins the service to the secret *version* that existed at
deploy time (visible as `secretKeyRef.key` in `gcloud run services describe capture`), so a new
version is inert until the function is redeployed onto it. The CLI offers to do the redeploy and the
destroy for you; it has been observed to do the redeploy but silently skip the destroy, printing an
empty `Removing secret versions:` line — check `gcloud secrets versions list CAPTURE_SECRET` after,
and destroy the old version by hand if it is still `enabled`.

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
