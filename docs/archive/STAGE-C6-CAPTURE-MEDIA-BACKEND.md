# Stage C.6 (backend) — Capture media, rich fields & tags

**Executor:** E, via AWS CLI in the same continuous terminal used for Stage B (creds already
configured, `AWS_PAGER=""` set). This is AWS/Python infra work — **not** the Claude Code Swift
terminal's job, exactly like Stage B. Cowork guides step-by-step; each step's output is reviewed
before the next is given (never batched).

**Account/region:** `891943683816` / `us-east-1`. Reuses the live Stage B stack: DynamoDB table
`LifeOS`, Lambda `life-os-api`, IAM role `life-os-api-lambda-role`, HTTP API `life-os-api-gw`
(`ApiId 2pzqn8yih5`), Cognito pool `us-east-1_fOmtVlMih`.

---

## 0. Why this exists

The Swift Capture feature (Stage C.6, Swift side, in `TODO-CLAUDE-CODE.md`) is being expanded from
text-only to four real capture types — **Quick Note (text)**, **Photo**, **Voice Note**, and
**Link** — plus the full property set E defined: **Title, Tag, Life Area, Capture Date, AI
Assessment, Status, Type, Content**. Verified 2026-07-23 against both backends, a capture today is
only `content / kind / processed / createdAt` in DynamoDB (via the Lambda writer) **and** in
Supabase (`captures` table, 6 columns). Four of the eight properties, all media handling, tags on
captures, and a real status model **do not exist anywhere yet**. This doc builds the AWS side of
that. The Swift adapter/UI consume it in `TODO-CLAUDE-CODE.md`.

Locked decisions this implements (from the C.6 design session, 2026-07-23):

- Media (audio, images, link thumbnails) live in **S3**; the DynamoDB capture record stores an S3
  **key** + metadata, never the bytes. Reads return short-lived **presigned GET URLs** so the app
  never holds S3 credentials.
- Voice transcription is done **on-device by the app** and arrives as the capture's `content` — the
  backend only stores that text plus the audio file. **No Amazon Transcribe.**
- Photo thumbnails are **server-generated** (a resize Lambda on S3 upload).
- Link previews are fetched **asynchronously** — the capture saves instantly and the preview fills
  in a moment later. Save is never blocked on an outbound fetch.
- **Out of scope (parked):** AI auto-sort into a Life Area / automatic "needs-review" assignment
  (that is Poke / System-1's job), a `source` field (not in E's eight), and the future Life Area →
  Sub-area hierarchy (the tag model here must not box it out, but does not implement it).

---

## 1. What this builds (three sub-stages)

Run and verify these in order. Each is independently reviewable.

- **C.6-INFRA-a — Core.** New S3 media bucket + its IAM grants; extend `life-os-api`'s capture
  handlers (new fields, `status` enum + back-compat, `photo` kind, `POST /captures/upload-url`,
  presigned GET URLs on reads, `capture_tags` junction routes); add the new routes to
  `life-os-api-gw`. Curl-verified.
- **C.6-INFRA-b — Thumbnails.** New `life-os-thumbnailer` Lambda triggered by S3 `ObjectCreated`
  on photo originals; writes a sibling `thumb.jpg`.
- **C.6-INFRA-c — Link unfurl.** New `life-os-unfurl` Lambda, invoked asynchronously by
  `create_capture` for `kind:link`; fetches the URL, parses Open Graph tags, stores a link
  thumbnail, and PATCHes the capture's `linkPreview`.

---

## 2. Data model — capture item (DynamoDB `LifeOS`)

Single-table conventions unchanged (`PK = USER#<userId>`, `SK = CAPTURE#<id>`). New/changed
attributes on a capture item:

| Attribute | Type | Notes |
|---|---|---|
| `content` | S | Text. Voice = on-device transcription; Photo = optional caption; Link = the URL; Note = text. **Required except for `photo`** (a photo may have an empty caption). |
| `kind` | S | **Type.** One of `note`, `task`, `link`, `voice`, `photo`. Defaults `note`. |
| `createdAt` | S | **Capture Date.** `_now_iso()` bare format, unchanged. |
| `status` | S | **Status.** One of `inbox`, `needs-review`, `processed`. Defaults `inbox`. |
| `processed` | BOOL | Back-compat mirror: `processed == (status == "processed")`. Kept so the existing `?processed=false` filter and the Swift `markProcessed` path keep working unchanged. |
| `title` | S | **Title.** Optional. Stored/displayed; no server logic. |
| `lifeAreaId` | S | **Life Area.** Optional UUID string. When present, GSI1 keys are set (life-area scoping, mirrors logs/tasks). |
| `aiAssessment` | S | **AI Assessment.** Optional, nullable. Stored only — never computed here. Passively accepted on create/update, populated externally/later. |
| `mediaKey` | S | Optional. S3 key of the primary binary (voice `audio.m4a`, photo `original.<ext>`). |
| `mediaContentType` | S | Optional. e.g. `audio/m4a`, `image/jpeg`. |
| `thumbnailKey` | S | Optional. S3 key of the photo thumbnail (deterministic sibling of `mediaKey`; the object is written later by the thumbnailer). |
| `linkPreview` | M | Optional map: `{ url, title, description, thumbnailKey }`. Written by the unfurl Lambda. |

**Tags** are a junction, mirroring `task_tags` exactly:

- `SK = CAPTURETAG#<captureId>#<tagId>`, `entity = "CAPTURETAG"`, attrs `captureId`, `tagId`.
- Tags themselves reuse the existing `TAG#<id>` entity and `POST /tags` (server-side dedup by
  name — E's "any name, no duplicates" rule is already enforced there).

**GSI1 for captures (life-area scoping):** when `lifeAreaId` is present, set
`GSI1PK = USER#<userId>#AREA#<lifeAreaId>`, `GSI1SK = CAPTURE#<createdAt>`. This is forward-compat
with the future Life Area → Sub-area hierarchy (captures become queryable by area) without building
sub-areas now. No new GSI is created — it reuses the table's existing `GSI1`.

**Response shape (reads only):** `get_capture` / `list_captures` add ephemeral, non-stored fields
built at response time — `mediaUrl`, `thumbnailUrl`, and `linkPreview.thumbnailUrl` — each a
presigned GET URL (~15 min TTL) minted from the corresponding `*Key`. The keys stay in the item;
the URLs are never persisted. If a `thumbnailKey` object doesn't exist yet (thumbnailer hasn't
run), its presigned URL simply 404s on fetch — the app falls back to `mediaUrl`.

---

## 3. REST contract (added / changed on `life-os-api-gw`, all JWT-protected)

| Method + path | Purpose |
|---|---|
| `POST /captures/upload-url` | Mint a presigned **PUT** URL + `mediaKey` (+ deterministic `thumbnailKey` for photos). Body: `{ kind, contentType }`. Returns `{ uploadUrl, mediaKey, thumbnailKey? }`. |
| `POST /captures` | **Extended.** Accepts `content`, `kind`, `title?`, `lifeAreaId?`, `aiAssessment?`, `mediaKey?`, `mediaContentType?`, `thumbnailKey?`, `status?`. For `kind:link`, fires async unfurl. Returns the created item. |
| `GET /captures` | **Extended.** Adds presigned URLs to each item. Supports existing `?processed=false` and new `?status=<inbox\|needs-review\|processed>`. |
| `GET /captures/{id}` | **Extended.** Adds presigned URLs. |
| `PATCH /captures/{id}` | **Extended.** Accepts `status?`, `processed?` (legacy), `title?`, `lifeAreaId?`, `aiAssessment?`, `linkPreview?` (used by the unfurl callback). Keeps `processed`/`status` coupled. |
| `GET /captures/{id}/tags` | List a capture's tags (mirrors `GET /tasks/{id}/tags`). |
| `POST /captures/{id}/tags` | Attach a tag (`{ tagId }`) — mirrors `POST /tasks/{id}/tags`. |
| `DELETE /captures/{id}/tags/{tagId}` | Detach a tag. |

`GET/POST /tags` already exist (Stage B) and are reused unchanged for tag create/dedup/list.

---

## 4. C.6-INFRA-a — S3 bucket, IAM, core Lambda extension

### 4.1 S3 media bucket

```
# Private bucket — Block Public Access ON, default SSE-S3 encryption.
aws s3api create-bucket --bucket adhd-lifeos-media-891943683816 --region us-east-1
aws s3api put-public-access-block --bucket adhd-lifeos-media-891943683816 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket adhd-lifeos-media-891943683816 --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

No CORS is needed: the iOS app uploads via native `URLSession` (presigned PUT), not a browser.
(If the web app ever uploads directly, add a CORS rule then — noted, not built.)

Key layout (all private):

```
captures/{userId}/{uploadId}/original.<ext>   # photo original
captures/{userId}/{uploadId}/thumb.jpg        # photo thumbnail (written by thumbnailer)
captures/{userId}/{uploadId}/audio.m4a        # voice audio
captures/{userId}/{captureId}/link-thumb.jpg  # link preview image (written by unfurl)
```

`uploadId` is a fresh UUID minted by `POST /captures/upload-url` (the capture doesn't exist yet at
upload time). The link thumbnail uses `captureId` because unfurl runs after the capture exists.

### 4.2 IAM — extend the existing API Lambda role

Add an inline policy `LifeOSMediaAccess` to `life-os-api-lambda-role` granting **only** what the API
Lambda needs to presign and to async-invoke the unfurl function:

```
# s3:PutObject + s3:GetObject on the media bucket (presigned PUT/GET inherit the signer's grant);
# lambda:InvokeFunction on the unfurl function (ARN wired in C.6-INFRA-c).
aws iam put-role-policy --role-name life-os-api-lambda-role --policy-name LifeOSMediaAccess --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:PutObject", "s3:GetObject"], "Resource": "arn:aws:s3:::adhd-lifeos-media-891943683816/*" },
    { "Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": "arn:aws:lambda:us-east-1:891943683816:function:life-os-unfurl" }
  ]
}'
```

### 4.3 Lambda source changes (`aws-backend/life-os-api/lambda_function.py`)

Cowork drafts the exact Python for these when E reaches this step; the contract is fixed above.
Summary of the edits:

- Add a module-level `s3 = boto3.client("s3")` and `MEDIA_BUCKET = os.environ["MEDIA_BUCKET"]`,
  plus `lambda_client = boto3.client("lambda")` and `UNFURL_FN = os.environ.get("UNFURL_FN")`.
- `VALID_CAPTURE_KINDS = {"note", "task", "link", "voice", "photo"}` — reject unknown kinds (400).
- New `create_upload_url(user_id, body)`: validate `kind`/`contentType`; mint
  `uploadId = uuid4()`; build `mediaKey` (`original.<ext>` for photo, `audio.m4a` for voice) and,
  for photo, a sibling `thumbnailKey`; return
  `{ uploadUrl: s3.generate_presigned_url("put_object", ..., ExpiresIn=300), mediaKey, thumbnailKey? }`.
- Extend `create_capture`:
  - Content required unless `kind == "photo"`.
  - Accept and store `title`, `lifeAreaId`, `aiAssessment`, `mediaKey`, `mediaContentType`,
    `thumbnailKey`.
  - Set `status = body.get("status", "inbox")` (validate against the three values); set
    `processed = (status == "processed")`.
  - Apply GSI1 keys when `lifeAreaId` present (reuse a small helper like `_apply_task_gsi_keys`'s
    life-area branch).
  - If `kind == "link"` and `UNFURL_FN` is set, `lambda_client.invoke(InvocationType="Event",
    FunctionName=UNFURL_FN, Payload=json.dumps({"userId": user_id, "captureId": capture_id,
    "url": content}))` — best-effort, wrapped so an invoke failure never fails the create.
- Add `_present_capture(item)` used by `get_capture`/`list_captures`: copies the item and adds
  `mediaUrl`/`thumbnailUrl`/`linkPreview.thumbnailUrl` presigned GETs (`ExpiresIn=900`) for any
  key present. Never mutates the stored item.
- Extend `update_capture` to accept `status` (keep `processed` coupled), `title`, `lifeAreaId`,
  `aiAssessment`, `linkPreview`.
- Add capture-tag handlers mirroring the task-tag ones: `list_capture_tags`, `attach_capture_tag`,
  `remove_capture_tag` (SK prefix `CAPTURETAG#<captureId>#`).
- Register the new routes in the `routes` dict.

Set the new env vars on deploy:

```
aws lambda update-function-configuration --function-name life-os-api --environment "Variables={TABLE_NAME=LifeOS,MEDIA_BUCKET=adhd-lifeos-media-891943683816,UNFURL_FN=life-os-unfurl}"
# then package + update-function-code as in STAGE-B §6.
```

### 4.4 API Gateway routes

Add each new route to `life-os-api-gw` (`ApiId 2pzqn8yih5`), JWT-protected, pointing at the same
`life-os-api` integration (`ms1d6kn`) — same pattern as STAGE-B §7:

```
POST   /captures/upload-url
GET    /captures/{id}/tags
POST   /captures/{id}/tags
DELETE /captures/{id}/tags/{tagId}
```

(`POST/GET/PATCH /captures` and `GET/POST /tags` already exist from Stage B.)

### 4.5 Back-compat migration for existing capture rows

Existing capture items have `processed` but no `status`. One-off backfill (safe, idempotent):

```
# For each capture item: status = "processed" if processed else "inbox".
# Cowork provides a short boto3 script E runs once; it scans SK begins_with CAPTURE# and
# PutItem/UpdateItem sets status. Re-runnable with no ill effect.
```

### 4.6 Verification (before calling INFRA-a done)

With a valid `$TOKEN` (from the Stage B sign-in still exported in the terminal):

```
# upload-url → 200 with uploadUrl + mediaKey (+ thumbnailKey for photo)
curl -s -X POST "$GW/captures/upload-url" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"kind":"photo","contentType":"image/jpeg"}'
# PUT a small test file to the returned uploadUrl → expect HTTP 200 from S3
# POST a photo capture referencing the mediaKey → 201, status "inbox", processed false
# GET /captures/{id} → item includes mediaUrl (presigned), decodes; thumbnailUrl 404s until INFRA-b
# POST /tags then POST /captures/{id}/tags → 201; GET /captures/{id}/tags → the tag back
# PATCH /captures/{id} {"status":"needs-review"} → 200, processed still false
# PATCH /captures/{id} {"status":"processed"} → 200, processed true
# GET /captures?status=inbox and ?processed=false → filter correctly
```

---

## 5. C.6-INFRA-b — thumbnailer Lambda

New function `life-os-thumbnailer` (Python 3.13), triggered by S3 `ObjectCreated` on the media
bucket, **suffix-filtered to `/original.jpg`, `/original.jpeg`, `/original.png`** (so it never
recurses on `thumb.jpg` or touches audio). It reads the original, resizes to a max ~400px
thumbnail with Pillow, and writes the sibling `thumb.jpg`.

- **Dependency:** Pillow via a Lambda layer (AWS-provided or built once) — keeps the deploy package
  small. Cowork provides the exact layer/packaging step when E reaches it.
- **IAM:** its own role `life-os-thumbnailer-role` with basic execution (CloudWatch logs) +
  `s3:GetObject`/`s3:PutObject` on `arn:aws:s3:::adhd-lifeos-media-891943683816/*`.
- **S3 trigger:** `aws s3api put-bucket-notification-configuration` with a `LambdaFunctionConfiguration`
  for `s3:ObjectCreated:*` + the suffix filters, plus `aws lambda add-permission` granting S3
  invoke.
- **It never touches DynamoDB** — `thumbnailKey` is already stored deterministically at capture
  create, so there's nothing to PATCH. This is deliberate (avoids a race where the capture doesn't
  exist yet when the thumbnail is written).

**Verify:** upload a real JPEG via a fresh `upload-url`; within a second or two, `thumb.jpg` exists
at the sibling key (`aws s3 ls`); re-fetch the capture and confirm `thumbnailUrl` now resolves.

---

## 6. C.6-INFRA-c — unfurl Lambda

New function `life-os-unfurl` (Python 3.13), invoked **asynchronously** by `create_capture` for
`kind:link` (see §4.3). Payload `{ userId, captureId, url }`.

- Fetches the URL (stdlib `urllib.request`, short timeout, a normal User-Agent, size-capped read).
- Parses `og:title` / `og:description` / `og:image` (and `<title>` fallback) with the stdlib
  `html.parser` — **no external HTML library**, to keep the package dependency-free.
- If an `og:image` exists, downloads it (size-capped) and stores it at
  `captures/{userId}/{captureId}/link-thumb.jpg`.
- PATCHes the capture item: `linkPreview = { url, title, description, thumbnailKey? }` (direct
  `table.update_item`/`put_item`, same scoping as the API Lambda).
- **Fully best-effort:** any fetch/parse failure logs and exits cleanly, leaving the capture as a
  bare URL (the app degrades to showing the plain link). The capture create already succeeded.
- **IAM:** its own role `life-os-unfurl-role` with basic execution + `s3:PutObject` on the media
  bucket + `dynamodb:GetItem`/`UpdateItem` (or `PutItem`) on the `LifeOS` table. Outbound internet
  is on by default (no VPC).
- **Wire-up:** the API Lambda's `LifeOSMediaAccess` policy (§4.2) already grants
  `lambda:InvokeFunction` on this ARN, and `UNFURL_FN=life-os-unfurl` is set (§4.3).

**Verify:** `POST /captures {"kind":"link","content":"https://<a real OG-rich page>"}` → 201
immediately (no preview yet); a moment later `GET /captures/{id}` shows a populated `linkPreview`
with a resolving `thumbnailUrl`. Then `POST` a link to a deliberately unreachable URL → capture
still saves, `linkPreview` stays absent, no error surfaced.

---

## 7. What's explicitly NOT in this backend block

- No AI auto-sort / auto "needs-review" — status defaults to `inbox`; `needs-review` and
  `processed` are only ever set by an explicit client `PATCH`. AI assessment is a passive stored
  field.
- No `source` field on captures (not in E's eight).
- No sub-areas — only the forward-compatible `lifeAreaId` + GSI1 hook.
- No Supabase changes — the web `captures` table stays as-is; AWS becomes the richer source of
  truth for captures, reconciled at the Stage D migrate-vs-fresh-start decision.
- No delete route for captures (matches the no-delete precedent for tasks/captures today).

---

## 8. Handoff

Once all three sub-stages are verified, the Swift side (`TODO-CLAUDE-CODE.md`: C.6a adapter, then
C.6b-photo / -voice / -link / -triage) can device-verify against these live routes. C.6a's unit
tests use `MockURLProtocol` and don't need the backend live — only E's on-device verification steps
do.
