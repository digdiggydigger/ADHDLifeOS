# External Captures → AWS: "E's Capture" Shortcut Dual-Write

**Status:** ✅ COMPLETE — all branches wired to authed AWS and proven live in the app Inbox (2026-07-28/29). See §6 for per-type status. Only open item: rotate the Cognito password (§7).
**Owner of execution:** E (all changes are made in the iOS Shortcuts app + optional AWS check — no Swift, no new backend).

> **Implementation note (as-built vs. this draft):**
> - **Auth (§5.0):** pure-Shortcuts Cognito auth was impossible — Shortcuts can't parse Cognito's `x-amz-json-1.1` File response. Replaced by a thin AWS proxy `POST /prod/auth` (Lambda `life-os-auth`, commit `bcfc296`) returning clean JSON `{idToken,…}`; the shortcut reads key `idToken` (lowercase) → var `idToken`, sent as `Authorization: Bearer idToken`.
> - **Dual-write → single-write:** E deleted the legacy Poke Function-URL write on every branch, so each branch now writes ONLY to authed AWS.
> - **Photo content-type:** photo is converted to PNG, so `contentType`/PUT `Content-Type`/`mediaContentType` = `image/png` (not jpeg), and the uploaded file is the `Converted Image` variable.
> - **Photo menu re-conceived:** inner Front/Back menu is now **Camera** (take photo) and **Camera Roll** (select from library); both run the full photo pipeline and are AWS-wired identically.
> - **Voice file:** PUT uses the in-memory `Recorded Audio` var (native m4a); the existing iCloud+ Drive save is left untouched.
> - **Extract before PUT:** all `Get Dictionary Value` reads (`uploadUrl`/`mediaKey`/`thumbnailKey`) must run BEFORE the PUT, or the PUT's "Get contents" hijacks the Contents-of-URL magic variable.

---

## 1. Objective

Make every capture created through the **"E's Capture" iOS Shortcut** appear inside the ADHD LifeOS app, by having the shortcut write each capture into the app's DynamoDB `LifeOS` table **in addition to** its existing POST to Poke.

This is one input path of a larger target where **DynamoDB is the single shared capture store** and all three creation methods write into it:

| # | Input method | Types | Writes to DynamoDB via | In scope here? |
|---|---|---|---|---|
| 1 | Poke (slash commands) | Note / Task / Link only | E's Poke-side wiring | ❌ E's scope |
| 2 | **E's Capture iOS Shortcut** | All 5 types | **This doc** | ✅ |
| 3 | ADHD LifeOS app | All 5 types | Already done | ✅ (shipped) |

**Poke's read side is unchanged and out of scope.** Poke keeps reading from Notion exactly as today; keeping Notion populated (or pointing Poke at DynamoDB) is E's separate piece. This doc only makes the shortcut *also* write to DynamoDB.

## 2. Design decisions (locked with E)

- **Dual-write, Poke path untouched.** Each shortcut branch keeps its current POST to Poke's `/capture` Function URL (`…lambda-url…/capture`, `X-Capture-Key` header) exactly as-is. We only *add* the AWS write alongside it.
- **Photo/Voice use the app-native media flow** — real file upload to S3 via presigned PUT, not text-only records. So they run the full `upload-url → S3 PUT → create capture` sequence, identical to what the app does.
- **Cognito auth for all types.** Because the media flow requires the Cognito-authenticated app API, and half-building a static-key path that can't serve media is wasteful, the shortcut authenticates to Cognito **once per run** and uses the existing `life-os-api` endpoints for every type. **No new backend/ingest Lambda is built** — the app API already exists and is device-verified.
- **No Swift/app change.** The app already reads `GET /captures` from DynamoDB, so any row the shortcut writes appears in the Inbox automatically.

## 3. Endpoints & constants (live, verified)

- **App API base:** `https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod`
- **Cognito app client id:** `57v25l4t62spds2qkvkhtbq0ae` (`USER_PASSWORD_AUTH` enabled, no secret)
- **Cognito region host:** `https://cognito-idp.us-east-1.amazonaws.com/`
- **Capture kinds (app):** `note`, `task`, `link`, `voice`, `photo`
- **Media content-types accepted → extension:** `image/jpeg`/`image/jpg`→jpg, `image/png`→png, `audio/m4a`/`audio/mp4`/`audio/x-m4a`→m4a, `audio/mpeg`→mp3, `audio/wav`→wav
- **Presigned upload URL TTL:** 300s (upload immediately after minting)

## 4. Field mapping (shortcut → app `POST /captures`)

| Shortcut field (current, to Poke) | App capture field | Notes |
|---|---|---|
| `type` = "Quick Note"/"Note" | `kind` = `note` | mapping table below |
| `type` = "Task" | `kind` = `task` | |
| `type` = "Link"/"URL" | `kind` = `link` | `content` = the URL; app unfurls async |
| `type` = "Photo" | `kind` = `photo` | media flow; `content` = caption (may be empty) |
| `type` = "Voice Note" | `kind` = `voice` | media flow; `content` = on-device transcription |
| `raw_text` | `content` | required for all kinds except `photo` |
| `timestamp` | — | app sets `createdAt` server-side; not sent |
| `source` = "E's Capture" | — | app has no `source` field; not sent |

`status` is omitted → app defaults to `inbox`. `lifeAreaId`/`title` omitted (triage is a future, separate piece per E).

## 5. Shortcut changes, per branch

### 5.0 Shared auth step (add once, runs first)

Add near the top of the shortcut, before the per-type branching:

1. **Get Contents of URL** → `https://cognito-idp.us-east-1.amazonaws.com/`
   - Method: `POST`
   - Headers: `Content-Type: application/x-amz-json-1.1`, `X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth`
   - Request Body (JSON):
     ```json
     {
       "AuthFlow": "USER_PASSWORD_AUTH",
       "ClientId": "57v25l4t62spds2qkvkhtbq0ae",
       "AuthParameters": { "USERNAME": "ethanant@icloud.com", "PASSWORD": "<stored>" }
     }
     ```
2. **Get Dictionary Value** → key path `AuthenticationResult.IdToken` from the response. Store as variable **`IdToken`**.

All app-API calls below send header `Authorization: Bearer {IdToken}`.

### 5.1 Text branches — Note / Task / Link

After the existing Poke POST, add one action:

- **Get Contents of URL** → `{base}/captures`
  - Method: `POST`
  - Headers: `Content-Type: application/json`, `Authorization: Bearer {IdToken}`
  - Body (JSON): `{ "kind": "<note|task|link>", "content": "{raw_text}" }`

### 5.2 Media branches — Photo / Voice (app-native flow)

After the existing Poke POST, add three actions in order:

1. **Get Contents of URL** → `{base}/captures/upload-url`
   - `POST`, `Authorization: Bearer {IdToken}`, `Content-Type: application/json`
   - Body: `{ "kind": "<photo|voice>", "contentType": "<image/jpeg | audio/m4a>" }`
   - Read `uploadUrl`, `mediaKey`, and (photo only) `thumbnailKey` from the response.
2. **Get Contents of URL** → `{uploadUrl}` (the presigned URL)
   - Method: `PUT`
   - Header: `Content-Type: <same contentType as step 1>` ← **must match exactly or S3 returns 403**
   - Request Body: **File** = the photo/audio file
3. **Get Contents of URL** → `{base}/captures`
   - `POST`, `Authorization: Bearer {IdToken}`, `Content-Type: application/json`
   - Body (photo): `{ "kind": "photo", "content": "<caption or empty>", "mediaKey": "{mediaKey}", "mediaContentType": "image/jpeg", "thumbnailKey": "{thumbnailKey}" }`
   - Body (voice): `{ "kind": "voice", "content": "<transcription>", "mediaKey": "{mediaKey}", "mediaContentType": "audio/m4a" }`

> **Voice audio source (resolved 2026-07-26):** "E's Capture" already saves a copy of the recorded audio file to E's iCloud+ Drive, so the audio file is available for upload. The Voice branch takes that saved file, PUTs it to the presigned URL (step 2, `Content-Type: audio/m4a`), and sends the on-device transcription as `content` in step 3. No extra recording action needed.

## 6. Build & verify order (one type at a time)

Prove the mechanism on the simplest type first, then widen. **All steps below are DONE & proven live in the app Inbox (2026-07-28/29):**

1. ✅ **Quick Note** — auth proxy (`/prod/auth`) + text write (5.1). Validated Cognito auth + write end-to-end (real DynamoDB row).
2. ✅ **Task** — `kind: task`.
3. ✅ **Link** — `kind: link`; async unfurl fills the preview after. (`content` = the branch's formatted Text block, E's "ALWAYS option A".)
4. ✅ **Camera** (photo, take-photo path) — media flow (5.2), `image/png` + thumbnailKey; Inbox row renders a real server thumbnail.
5. ✅ **Voice** — media flow, `audio/m4a`, no thumbnailKey; PUT uses in-memory `Recorded Audio` (iCloud save untouched), on-device transcription inside the formatted `content` block.
6. ✅ **Camera Roll** (photo, select-from-library path) — same full photo shape as Camera; wired identically.

`content` = the branch's formatted **Text block** for every type (not caption/transcription-only). Only remaining item: rotate the Cognito password (§7).

## 7. Security

- The shortcut will hold E's **Cognito username + password** to mint tokens. Store the password in a way you're comfortable with (Shortcut text/Data Jar/keychain prompt). Tokens are short-lived (~1h) and minted fresh each run — nothing long-lived is stored server-side.
- The existing `X-Capture-Key` (Poke intake) stays as-is; it was exposed in screenshots during this design — rotate it if you consider that a risk (would require updating the shortcut).

## 8. Explicitly out of scope

- Poke → DynamoDB writes (method 1) and Poke's read side — **E's**.
- Keeping Notion populated for Poke's reads — **E's**.
- Any Swift/app change — none needed.
- Capture triage (Life Area/tags on ingest) — deferred by E to a future block.
- A new backend ingest Lambda — not built; existing `life-os-api` endpoints are reused.
