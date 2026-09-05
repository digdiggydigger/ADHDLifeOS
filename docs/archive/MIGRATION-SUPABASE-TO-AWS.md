# Migration Blueprint — Supabase → AWS (Lambda + DynamoDB)

*Status: **DRAFT — awaiting E's review.** No FEATURE blocks drafted and no code written until this document is approved.*
*Author: Cowork (design phase). Date: 2026-07-22.*
*Grounded in a live audit of the app repo, the Supabase schema source, and the real AWS console (acct `891943683816`, us-east-1) on 2026-07-22.*

---

## 0. Decisions locked (from review 2026-07-22)

| Decision | Choice | Notes |
|---|---|---|
| Integration layer | **API Gateway (HTTP API) + Lambda REST** | Extends the pattern `poke-ios-bridge` already proves. |
| Data model | **Single-table DynamoDB + GSIs** | `PK = userId`, `SK = <entity>#<id>`; GSIs for life-area and status filters. |
| Auth / identity | **AWS Cognito (User Pool) + API Gateway JWT authorizer** | Native Supabase-Auth replacement; closes the current public-endpoint hole. |
| Existing Supabase data at cutover | **Decide later** | Resolved in Stage D, not a blocker for Stages A–C. |

---

## 1. Supabase audit — what's in use, what breaks

### 1.1 The migration seam (most important finding)

The app is a thin UI + adapter layer. **Every feature reaches Supabase through a protocol** (`*ClientAdapting`) with a concrete `Supabase*ClientAdapter`, and all of them are constructed in **one file**: `ADHD LifeOS/ADHD LifeOS/ADHD_LifeOSApp.swift`.

Consequence: migrating a feature = writing a new `AWS*ClientAdapter` conforming to the **same protocol**, then swapping the one line that constructs it in `ADHD_LifeOSApp.swift`. **SwiftUI views and the `*Service` layer do not change.** This is what makes the migration tractable and low-risk.

### 1.2 Supabase surface currently in use

| Adapter (protocol) | Concrete impl | Operations | Supabase objects |
|---|---|---|---|
| `AuthClientAdapting` | `SupabaseAuthClientAdapter` | restore session, signIn(email/pw), requestOTP (magic link), completeSession(url), signOut | Supabase Auth |
| `HomeClientAdapting` | `SupabaseHomeClientAdapter` | fetchLifeAreas, fetchOpenTasks | `life_areas`, `tasks` |
| `TasksClientAdapting` | `SupabaseTasksClientAdapter` | fetchLifeAreas, fetchAllTasks | `life_areas`, `tasks` |
| `TaskCreateClientAdapting` | `SupabaseTaskCreateClientAdapter` | fetchTags, createTag, createTask, attachTags | `tasks`, `tags`, `task_tags` |
| `TaskDetailClientAdapting` | `SupabaseTaskDetailClientAdapter` | fetchTask, fetchTagsForTask, fetchAllTags, updateTask, updateStatus, createTag, add/removeTagToTask | `tasks`, `tags`, `task_tags` |
| `CaptureClientAdapting` | `SupabaseCaptureClientAdapter` | createCapture, fetchUnprocessedCaptures, fetchCapture, createTask (promote), markProcessed | `captures`, `tasks` |
| `JournalClientAdapting` | `SupabaseJournalClientAdapter` | fetchLifeAreas, fetchLogs, createLog | `logs`, `life_areas` |
| `LifeAreaDetailClientAdapting` | `SupabaseLifeAreaDetailClientAdapter` | fetchTasks(lifeAreaId), fetchLogs(lifeAreaId) | `tasks`, `logs` |
| `NudgesClientAdapting` | `SupabaseNudgesClientAdapter` | fetchNudges, createNudge, updateNudge, markFired | `nudges` |

Not Supabase (unaffected): `NotificationCenterCountdownNudgeAdapter`, `NotificationCenterNudgeAdapter` — local iOS notification scheduling.

### 1.3 Data model (schema source: `Monday 13th July/src/domain/types.ts`, verified against `supabase/migrations/*.sql`)

Six tables + one junction:
- `tasks` — id, userId, lifeAreaId?, title, notes?, status(`open`|`done`), priority(`p1`–`p4`, default `p4`), dueDate?, source(`manual`|`capture`), createdAt, updatedAt
- `life_areas` — id, userId, name, colour, sortOrder, createdAt, updatedAt (fixed set of 9, seeded on signup)
- `captures` — id, userId, content, kind(`note`|`task`|`link`|`voice`), processed, createdAt
- `logs` — id, userId, lifeAreaId?, type(`log`|`journal`), body, entryDate, createdAt (**append-only**; no update/delete policy exists)
- `nudges` — id, userId, label, schedule(string), active, lastFiredAt?, createdAt, updatedAt
- `tags` — id, userId, name, createdAt
- `task_tags` — (task_id, tag_id) junction

Security: **Supabase Auth + RLS** (`auth.uid() = user_id` on every table). INSERTs must set `user_id` explicitly (no column default / trigger). A `SECURITY DEFINER` trigger seeds the 9 life areas on each new signup.

### 1.4 What breaks during transition

- **Auth gates everything.** RLS means no table is queryable without a session. The instant auth changes, the whole app is dark until the new auth path works — Auth must cut over first and cleanly.
- **Per-feature breakage:** each screen is non-functional until its `AWS*ClientAdapter` exists and is wired.
- **No data continuity by default:** current Supabase rows do **not** exist in DynamoDB. Cutover implies either a migration step (Stage D) or a fresh start.
- **Behavioural parity to preserve:** append-only logs (no edit/delete UI), life-area seeding on signup, device-local timezone for nudge due-ness (the app deliberately does **not** copy the web's BST nudge bug).

---

## 2. AWS audit — what actually exists (us-east-1, acct `891943683816` / reckedgelato)

### 2.1 DynamoDB
- **`PokeTasks`** — PK `task_id` (S), no GSIs, ~4 test items. Freeform item shape written by Poke:
  `task_id`, `created` (ISO), `datetime` (scheduled time), `notes`, `notification` (bool), `priority` (`low`|`medium`|`high`), `source` (`poke`), `title`, `type` (`reminder`|`calendar`|`timer`|`alarm`).
  **Single-user (no userId), no life-area link.** It is a *reminders* store, not the app's Task model.
- **`Customers`** — empty. **Ignored** per E.

### 2.2 Lambda
- **`poke-ios-bridge`** (Python 3.13, x86_64, handler `lambda_function.lambda_handler`) — fronted by the HTTP API.
  - `GET /task` → `table.scan()` → `{count, tasks:[...]}` (returns all reminders, unscoped).
  - `POST /task` → `validate_task` (type ∈ reminder/calendar/timer/alarm; reminder needs `title`; calendar needs `title`,`datetime_start`,`datetime_end`; timer needs `duration_minutes`; alarm needs `time`) → `put_item({task_id: uuid4, created: utcnow, **body})`.
  - **No auth, no per-user scoping, no update, no delete.**
- **`life-os-writer-mcp`** (Node.js 24, ~1,187 lines) — a Poke→**Notion** MCP server (JSON-RPC; tools incl. `resolve_duplicate_task`). Writes captures/tasks into Notion databases (`CAPTURE_DATABASE_ID`, `TASKS_DATABASE_ID`), reads DynamoDB via `GetItem`. Env: `NOTION_TOKEN`, `CAPTURE_DATABASE_ID`, `CAPTURE_SHARED_SECRET`, `DATABASE_ID`, `POKE_API_KEY`, `TASKS_DATABASE_ID`.
  - **This is System 1 (Poke + Notion operational).** Its data lives in **Notion**, not in a store the app can query. Out of scope for the app backend per global rules.

### 2.3 API Gateway
- HTTP API **`qxbwx2qjq7`**, stage **`prod`**, auto-deploy on.
- Invoke URL: `https://qxbwx2qjq7.execute-api.us-east-1.amazonaws.com/prod`
- Routes: `GET /task`, `POST /task` → both integrate `poke-ios-bridge`.
- **Authorizer: none attached (fully public).** Security finding — anyone with the URL can read/write all reminders.

### 2.4 Mapping existing AWS → app needs

| App need | Exists in AWS today? | Notes |
|---|---|---|
| Reminders / scheduled items | **Yes** — `PokeTasks` via `/task` | Loosely maps to a Reminders/Nudges surface. |
| `tasks` (app model) | No | `PokeTasks` ≠ app Task (diff priority enum, no `status`, no `lifeAreaId`, no tags). |
| `life_areas` | No | — |
| `captures` | No (only in Notion via Poke) | — |
| `logs` | No (only in Notion via Poke) | — |
| `nudges` | Partial | `PokeTasks` reminders are the closest analogue. |
| `tags` / `task_tags` | No | — |
| Per-user auth (RLS equiv) | No | Endpoint is public. |

**Honest reframing of the "quickest win":** the only existing *queryable* app-relevant data is the ~4-row `PokeTasks` reminders table behind a public GET/POST. It's a genuine, valuable first integration (Stage A) but **not** a shortcut to app-wide parity — the rest of the backend must be built.

---

## 3. Gaps and recommended approach

### 3.1 Gaps
- **Data stores:** no `life_areas`, `captures`, `logs`, `nudges`, `tags`, and no proper `tasks` table.
- **Identity/auth:** no Cognito; the one endpoint is public; no per-user scoping.
- **API coverage:** only `GET(scan)` + `POST` on one table. Missing update, delete, filtered queries (status, life area), and the tag join.
- **Server-side rules:** no life-areas-on-signup seed; no append-only enforcement on logs.

### 3.2 Recommended target architecture

**Integration:** API Gateway (HTTP API) + a `life-os-api` Lambda exposing per-entity REST routes. Adapters become JSON-over-HTTP clients. DB credentials stay server-side; the device never holds IAM keys.

**Auth:** Cognito User Pool + API Gateway **JWT authorizer**. App keeps email/password now; email-OTP/passwordless later to mirror the magic link. The Lambda reads the JWT `sub` claim as `userId` and scopes every DynamoDB operation to it — this is the **RLS equivalent**. v1 = one user (E).

**Data model — single-table DynamoDB (`LifeOS`):**

```
PK  = USER#<userId>
SK  = <ENTITY>#<id>          e.g. TASK#<uuid>, AREA#<uuid>, CAPTURE#<uuid>,
                                  LOG#<uuid>, NUDGE#<uuid>, TAG#<uuid>,
                                  TASKTAG#<taskId>#<tagId>
attributes: entity type + all domain fields (mirroring §1.3)

GSI1 (life-area scoping):
  GSI1PK = USER#<userId>#AREA#<lifeAreaId>
  GSI1SK = <ENTITY>#<createdAt or id>        → LifeAreaDetail tasks/logs, Home per-area counts

GSI2 (status / open-task filter):
  GSI2PK = USER#<userId>#STATUS#<status>
  GSI2SK = TASK#<dueDate or createdAt>        → Home open tasks, Tasks list filters
```

Notes: append-only logs enforced in the Lambda (no update/delete route for `LOG#`); life-area seed (9 rows) written on first Cognito sign-in or via a post-confirmation trigger; tag join modelled as `TASKTAG#` items (query by task, or by tag).

*Alternative considered:* table-per-entity — simpler mentally, more tables to manage. Single-table chosen per review.

---

## 4. Migration plan (existing first, then new)

### Stage A — Quick win (additive, non-disruptive): wire the existing reminders
- **New SwiftUI "Reminders" view** that reads `GET /task` and lists the Poke reminders (title, datetime, priority, type). Optional create form via `POST /task`.
- New protocol `RemindersClientAdapting` + `AWSRemindersClientAdapter` (URLSession JSON client to the HTTP API). Wired into `ADHD_LifeOSApp.swift` alongside the existing Supabase adapters.
- **App stays fully on Supabase for everything else — nothing breaks.** Proves the AWS↔app path against real data.
- Caveat: endpoint is public; acceptable for this read-mostly quick win, **hardened in Stage B**.

### Stage B — Build the missing AWS backend — **DONE, verified 2026-07-22**
- Provisioned **Cognito** user pool (`us-east-1_fOmtVlMih`, `adhd-lifeos-users`) + app client (`57v25l4t62spds2qkvkhtbq0ae`, `adhd-lifeos-ios`).
- Provisioned **`LifeOS`** single table + GSI1/GSI2, `ACTIVE`, all 9 life areas seeded with real Supabase-matching values.
- Built **`life-os-api`** Lambda (Python 3.13) with per-user, JWT-scoped REST routes for tasks, life_areas, captures, logs, nudges, tags, task_tags.
- **Correction from the original plan below:** rather than attaching the JWT authorizer to the *existing* `qxbwx2qjq7` HTTP API and retrofitting `/task` (which would break live Poke traffic, since Poke has no way to send a Cognito JWT), a **brand-new, separate HTTP API** was provisioned instead — `life-os-api-gw` (`ApiId 2pzqn8yih5`), JWT authorizer `ajwddr` (audience `$APP_CLIENT_ID`, issuer the Cognito pool above), all 19 routes from §3 of `STAGE-B-COGNITO-DYNAMODB-LAMBDA.md` wired to `life-os-api` via integration `ms1d6kn`, stage `prod` (auto-deploy). Invoke URL: `https://2pzqn8yih5.execute-api.us-east-1.amazonaws.com/prod`. `qxbwx2qjq7` and `poke-ios-bridge` were not touched by any of this.
- Verified live via curl: unauthenticated `/tasks` → 401; authenticated `/tasks` → 200 empty list; `/life-areas` → 9 correctly-ordered rows; `POST /tasks` → 201 with full item + correct GSI2 keys. Full command reference and rationale: `docs/STAGE-B-COGNITO-DYNAMODB-LAMBDA.md`.

### Stage C — Cut over feature-by-feature (one FEATURE block each, in dependency order)
1. **Auth** (gates everything) → `AWSAuthClientAdapter` (Cognito).
2. **Home** → life areas + open tasks.
3. **Tasks** (list) → **TaskCreate** → **TaskDetail** (incl. tags).
4. **Capture** (create/list/promote/mark-processed).
5. **Journal** (append-only logs).
6. **LifeAreaDetail** (area-scoped tasks + logs via GSI1).
7. **Nudges** (list/create/update/mark-fired) — reconcile with Stage A reminders.

Each step: new `AWS*ClientAdapter` behind the unchanged protocol, swapped at the composition root, verified, committed as its own FEATURE block.

### Stage D — Data & decommission (decision deferred)
- Decide **migrate** (export Supabase rows → import to `LifeOS`) vs **fresh start**. Then verify and retire Supabase.

### Net-new SwiftUI views
- **Reminders view** (Stage A) — the main net-new surface. All other screens reuse existing UI behind swapped adapters.

---

## 5. Planned FEATURE-block roadmap (to be drafted one at a time, on green light)

Per project rule (one FEATURE block, review, then the next):
- `FEATURE-AWS-1` — Reminders view + `AWSRemindersClientAdapter` over existing `/task` (Stage A).
- `FEATURE-AWS-2` — Cognito user pool + JWT authorizer + `LifeOS` table provisioning spec (Stage B infra; handed to Claude Code / manual AWS steps as appropriate).
- `FEATURE-AWS-3` — `life-os-api` Lambda REST contract (routes, payloads, per-user scoping).
- `FEATURE-AWS-4…N` — adapter cutovers in the Stage C order above.

*(Blocks are not written yet — awaiting approval of this blueprint.)*

---

## 6. Open items for E
1. Approve this blueprint (or request changes) before any FEATURE block is drafted.
2. Confirm start point: **Stage A Reminders quick win** first (recommended), or jump straight to Stage B backend build.
3. Stage D data decision (migrate vs fresh start) — can stay deferred.
4. Magic-link parity: keep email/password only for v1, or invest in Cognito passwordless now?
5. Manual AWS steps (Cognito setup, authorizer attach, table creation) are E-owned console/IaC actions — confirm whether you want these as click-through steps or an IaC (SAM/CDK) spec.
