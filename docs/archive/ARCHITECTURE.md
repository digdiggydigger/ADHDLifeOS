# System Architecture — ADHD LifeOS (Es_Life_OS mobile)

*This document is written in Cowork during the design phase.*
*Project: **ADHD LifeOS** — iOS client for the existing **Es_Life_OS** Supabase backend (project `iuhmgpedtyikakppokwk`) — last designed: 2026-07-17*

---

## 1. System Overview

**Purpose:** A native SwiftUI iOS client for Es_Life_OS — the same ADHD-safe Life-OS (capture, tasks, logs, life areas, nudges) already live as a Next.js web app, reusing its Supabase backend as-is. No new backend, no new schema decisions — mobile is a second client on data that already exists.

**Users:** v1 — E (single account, same Supabase Auth user as the web app).

**What this is NOT (non-goals):**
- ❌ Not a new backend. Zero new tables/columns unless a mobile-only need is explicitly identified and approved — check `DATABASE_SCHEMA.md`-equivalent (the live schema, read from migrations) before ever proposing one.
- ❌ Not a Core Data / offline-first app in v1. No local persistence layer — Supabase is the source of truth, same convention as web.
- ❌ Not a reimplementation of business rules already enforced by Postgres (RLS) or the web's domain layer — mobile is a UI + thin Supabase-adapter layer, same shape as the web project's F1/F2 split.

---

## 2. High-Level Flow

```
[Supabase Auth session] ─→ gates everything below
        │
        ▼
[Quick Capture] ─┐
[Task action]    ─┼─→ [supabase-swift client] ─→ [Postgres state — SAME tables as web]
[Log / Journal]  ─┘                                        │
                                                            ▼
                          [SwiftUI TabView] ←── reads (RLS-scoped) ──┘
                       (Home, Tasks, Journal, Nudges + floating Capture)
```

The web app and mobile app are two independent clients over one Supabase project. A task created on mobile appears on web on next load and vice versa — no sync layer, because Postgres already is the shared state.

---

## 3. Screens & Navigation

**Navigation shell:** `TabView`, 4 tabs, chosen deliberately small to keep the ADHD-safe "reduce startup friction" constraint — every screen is at most one tap from launch.

| Tab | Screen | Purpose |
|-----|--------|---------|
| **Home** | Dashboard | Life-area cards (9 areas) with open-task counts; due nudges surfaced at the top, above the fold. Gear icon (top-right) → Settings. |
| **Tasks** | Task List | All open tasks, filterable by life area and status. Tap a row → Task Detail. "+" → Task Create. |
| **Journal** | Logs/Journal Feed | Append-only feed of logs + journal entries, newest first, filterable by life area. "+" → new entry composer. |
| **Nudges** | Nudges | Due nudges at top (dismiss action), full nudge list below with active/inactive toggle. |

> **TEMPORARY TAB SWAP — E's decision 2026-07-22 (reversible, nothing deleted).** For the
> duration of the Supabase→AWS migration's Stage A, the **Nudges tab is removed from the tab bar
> and replaced by a Reminders tab** (see "FEATURE: AWS Reminders View" in `TODO-CLAUDE-CODE.md`),
> so the Reminders feature can be built out while E decides the future of the Nudges feature.
> The shell stays at 4 tabs: Home, Tasks, Journal, **Reminders**.
>
> This row is **deliberately left in place**, not deleted — the Nudges feature itself is fully
> intact (all source, adapters, notification scheduling, and tests), the Home due-nudges strip
> still renders, and scheduled nudge notifications still fire. Only the tab-bar entry is hidden,
> and restoring it is a one-line revert. Accepted temporary consequence: with the tab hidden
> there is no UI route to *create or edit* a nudge; existing nudges keep firing.

**Not a tab — global overlay:** a floating capture button, visible on all 4 tabs (bottom-trailing corner, above the tab bar), opens a Quick Capture sheet: a single text field + kind picker (note/task/link/voice), submit, done. This mirrors the web's "one capture surface" pattern and is deliberately never buried inside a tab, since capture friction is the single highest-leverage ADHD fix per the product's core problem statement.

**Screens reached by drill-down, not tabs:**
- **Login** — root screen when no session exists; replaces the TabView entirely (not a tab, not dismissible).
- **Life Area Detail** — tapping a Home dashboard card; shows Tasks (all statuses, with its
  own Open/Done/All filter, tap-through to existing Task Detail) and Journal/Log entries
  (newest-first, read-only) scoped to that one area via `tasks.life_area_id`/`logs.life_area_id`.
  **Nudges excluded from this screen** — `nudges` has no `life_area_id` column in the live
  schema (confirmed 2026-07-21), so there's no reliable way to scope them; revisit only if a
  real link is added later (would need its own schema/design decision, not assumed here).
- **Task Detail** — tap a task row; view/edit all fields (title, life area, priority, status, due date, notes, tags, created date). Mirrors web's F11E.
- **Task Create** — title field, collapsed "Add More Info" (due date, notes, tag picker with inline create). Mirrors web's F11C.
- **Capture Inbox** — unprocessed captures list, reachable from Home or the capture sheet's confirmation state; "promote to task" action per row.
- **Settings** — reached via Home's gear icon, presented as a sheet. **Settings is the designated
  home for all management features** (E's decision, 2026-07-30): the rationale is that management
  surfaces should be "out of the way but easily accessible" rather than cluttering the daily-use
  tabs. Grouped, sectioned screen with **five** sections:
  1. **Notifications** — displays the live iOS authorization state read from
     `UNUserNotificationCenter.notificationSettings` plus a button opening iOS Settings.
     Read-only status; no toggles and no per-nudge-type preferences (there is no persistence
     layer for such preferences anywhere in the app, so adding them would need its own design).
     This closes a real gap: the app schedules genuine OS notifications for task countdown,
     due-moment, and recurring nudges with **zero** visibility into whether permission was granted.
  2. **Life Areas** — management for the 9 seeded areas (rename, re-emoji, reorder the Home grid).
     No management UI exists today. Not yet built.
  3. **Account** — takes over Sign Out, which currently floats unattached in the screen body.
  4. **About & Diagnostics** — version, environment, last-refresh. Genuinely useful because
     neither Home nor Inbox auto-refreshes. Not yet built.
  5. **Tag Editor** — usage counts per tag, rename (with merge), delete (with cascade). Not yet
     built; needs new backend routes first (see §8).

  Sections that are not yet built render as **visible but disabled/greyed rows** (E's decision,
  2026-07-30) so the finished shape of the screen is legible without creating dead-end navigation.

---

## 4. Data Model — Swift ↔ Supabase Mapping

Source of truth for shape: `Monday 13th July/src/domain/types.ts` (verified 2026-07-17 against the live migrations, not assumed). Mobile does not own this schema — it's a read/write client against tables the web project already created and migrated. Swift structs below are the **spec** Claude Code implements as `Codable` models; this is documentation, not production code.

### Task ↔ `public.tasks`

```swift
struct Task: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let lifeAreaId: UUID?
    var title: String
    var notes: String?
    var status: TaskStatus       // "open" | "done"
    var priority: TaskPriority   // "p1"..."p4", default "p4"
    var dueDate: Date?
    let source: TaskSource       // "manual" | "capture"
    let createdAt: Date
    let updatedAt: Date
}
```

### LifeArea ↔ `public.life_areas`

```swift
struct LifeArea: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var colour: String
    var sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}
```
Fixed v1 set of 9, seeded server-side (Work, Personal, Family, Health, Projects, Hobbies, Admin, Journals, Home). No create/edit UI on mobile in v1 — matches web (LifeArea CRUD is web's F10, not yet built there either).

### Capture ↔ `public.captures`

```swift
struct Capture: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var content: String
    var kind: CaptureKind   // "note" | "task" | "link" | "voice"
    var processed: Bool
    let createdAt: Date
}
```

### Log ↔ `public.logs`

```swift
struct Log: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let lifeAreaId: UUID?
    let type: LogType   // "log" | "journal"
    let body: String
    let entryDate: Date
    let createdAt: Date
}
```
Append-only — no update/delete method on the client, and none possible server-side (no UPDATE/DELETE RLS policy exists on `logs`). Mobile must not attempt edit/delete UI for log rows.

### Nudge ↔ `public.nudges`

```swift
struct Nudge: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var label: String
    var schedule: String
    var active: Bool
    var lastFiredAt: Date?
    let createdAt: Date
    let updatedAt: Date
}
```

### Tag / TaskTag ↔ `public.tags` / `public.task_tags`

```swift
struct Tag: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    let createdAt: Date
}
// task_tags is a pure junction table (task_id, tag_id) — no Swift domain
// representation needed beyond the join query itself, same as web.
```

**Row-Level Security:** already fully active server-side (migration `0006_f7_auth_rls.sql`) — every table requires `auth.uid() = user_id`.

**Reads (SELECT) and mutations of existing rows (UPDATE/DELETE):** never filter by `userId` manually. RLS's `USING` clause auto-scopes these — an authenticated `supabase-swift` client only ever sees/touches the signed-in user's rows. No query should ever construct a `.eq("user_id", ...)` filter here; doing so would be redundant.

**Creates (INSERT) — explicit carve-out:** the rule above does NOT apply. RLS's `WITH CHECK (auth.uid() = user_id)` clause validates a row's `user_id` against the session — it does not populate the column. No table has a `user_id` column default, and no `BEFORE INSERT` trigger exists to fill it in. Every insert payload (`LogInsertPayload`, `CaptureInsertPayload`, `NudgeInsertPayload`, task/tag/task_tags inserts) **must** set `user_id` explicitly, sourced from `authClient.session.user.id`, or the insert is silently rejected with a 403 RLS violation. Confirmed live via Supabase MCP 2026-07-18: `information_schema.columns` shows `column_default IS NULL` on all six `user_id` columns; `pg_trigger` shows no relevant `BEFORE INSERT` trigger; `pg_policies` confirms `WITH CHECK` on every INSERT policy.

**Why this exists:** FEATURE-M1 through Nudges all omitted `user_id` on insert under the wrong assumption that this general RLS rule covered creates too. It doesn't — this carve-out corrects that for all future FEATURE blocks. Any future acceptance criterion reading "No `user_id` is ever manually constructed client-side" must be understood as scoped to SELECT/UPDATE/DELETE only.

---

## 5. Auth Flow (Supabase Auth via `supabase-swift`)

Mirrors the web app's already-shipped pattern (`web/src/app/login/actions.ts`): email/password as the default method, magic link (OTP) as the secondary method. Mobile is a **new client against an existing auth backend** — no new auth logic server-side, no new provider config.

1. **App launch:** check `supabase.auth.session` (SDK restores from Keychain automatically, refreshes if expired).
2. **No session →** show `LoginView` as app root (replaces the TabView, not a sheet/modal — you cannot "dismiss" your way past auth).
3. **Password sign-in:** email + password fields → `supabase.auth.signIn(email:password:)` → on success, session updates, root view switches to `TabView`.
4. **Magic link:** "Email me a link" secondary button → `supabase.auth.signInWithOTP(email:, redirectTo: <app URL scheme>)` → show a "check your email" confirmation state (no polling).
5. **Magic link return:** tapping the emailed link opens the app via a custom URL scheme (`adhdlifeos://auth-callback`, registered in `Info.plist` — a file edit, not an Xcode-GUI-only step, so Claude Code can do this itself). App's `.onOpenURL` passes the URL to `supabase.auth.session(from:)` to complete sign-in.
6. **Sign out:** Settings → Sign Out → `supabase.auth.signOut()` → root view switches back to `LoginView`.

**Session persistence:** entirely handled by `supabase-swift`'s built-in Keychain-backed storage — no custom token handling, no manual refresh logic.

**Manual step (E, not Claude Code):** registering the custom URL scheme's associated redirect URL in the Supabase Dashboard's Auth → URL Configuration allow-list, same category as the Supabase Dashboard steps already called out for the web project's F7.

---

## 6. Components

| Component | Purpose | Status |
|-----------|---------|--------|
| **SwiftUI app (this project)** | Native iOS client — TabView shell, capture overlay, all 5 pillars' UI. | Planning |
| **supabase-swift** | Auth + Postgrest client — same Supabase project as web, no new backend. | Planning (first dependency, added in FEATURE-M1) |
| **Supabase (Postgres + Auth)** | Single shared source of truth — already live, already schema-complete for v1's five pillars. | **Existing — do not modify without a dedicated migration decision.** |
| **Local persistence** | None in v1. No Core Data, no offline queue. | Explicit non-goal |

---

## 7. Deployment

**Distribution:** TestFlight (E's own device first), App Store later — both are Xcode-GUI/App-Store-Connect steps and are explicitly E's job per `CLAUDE.md`'s manual-step convention, never attempted by Claude Code.

**Environments:** one Supabase project, shared with web — no separate mobile dev/prod split in v1 (matches web's own single-environment v1 scope).

**Minimum iOS version:** `supabase-swift` (2.52.0) resolves to **iOS 16** — reported back by Claude Code after FEATURE-M1. **Resolved 2026-07-17 as part of FEATURE-M2:** E approved lowering `IPHONEOS_DEPLOYMENT_TARGET` from the unedited Xcode-default `26.5` to `16.0` for broader device support. Confirmed live in `ADHD LifeOS.xcodeproj/project.pbxproj` across all build configurations.

---

## 8. Phasing

- **v1 — mobile MVP:** Auth, then read/write parity with the web app's own v1 scope (tasks, capture, logs, life-area dashboards, nudges) — single-user, no offline mode, no mobile-only features.
- **v2+:** only after v1 parity ships — anything mobile-specific (widgets, Shortcuts
  integration) is out of scope until explicitly requested and designed as its own FEATURE
  block. ~~notifications for due nudges~~ was pulled forward from this deferral 2026-07-21 at
  E's explicit request — see "FEATURE: Nudges Push Notifications" in `TODO-CLAUDE-CODE.md`,
  same category as Task Due-Time Nudges' earlier pull-forward from this same list.

### Post-v1 — Settings & Tag Editor (agreed build order, 2026-07-30)

v1 (§8 above) is fully shipped. The current phase is app-level bug-fixing from E's real on-device
usage, and the next three blocks run **strictly in this order**, one review gate each:

1. **Settings rebuild** — the five-section screen described in §3. Pure Swift; no backend work.
   Notifications is real (read-only status), Account is real (Sign Out), and Life Areas,
   About & Diagnostics, and Tag Editor render as visible-but-disabled rows.
2. **Tag Editor backend** — split from the UI deliberately, following the Stage C.6
   INFRA-then-Swift precedent, so route behaviour is proven by smoke test before any SwiftUI
   touches it. **Confirmed live in `aws-backend/life-os-api/lambda_function.py`'s route table:
   only `GET /tags` and `POST /tags` exist today.** This phase adds:
   - usage counts on `GET /tags`
   - `PATCH /tags/{id}` — rename, including merge
   - `DELETE /tags/{id}` — cascade
   Tags join to items via separate `TASKTAG#<taskId>#<tagId>` and
   `CAPTURETAG#<captureId>#<tagId>` items which do **not** cascade on their own, so the cascade
   and merge logic is real server-side work, not a single-row operation.
3. **Tag Editor UI** — the Settings section goes from disabled to live.

**All three shipped and reviewed 2026-07-30** (`3f94eff`, `b47f157`/`c2a70c0`/`18a069b`, `6977cba`).
This sub-phase is complete.

### Post-v1 — Life Areas management (agreed 2026-07-30)

The next workstream. Chosen from four candidates; the agreed queue after it is **Task Detail
staged-vs-immediate-apply clarity → About & Diagnostics → Inbox `primaryText` header**.

**What the backend constrains today (verified in `aws-backend/life-os-api/lambda_function.py`):**
only `GET /life-areas` exists (route table, line 157), and the module docstring states the
read-only-ness as a deliberate v1 choice inherited from Supabase. Every write path below is new
work.

**Field-naming fact, deliberately NOT changed:** the attribute called `colour` **stores the
emoji**, not a colour — `HomeView.swift:201` renders `lifeArea.colour` as a `Text` at a computed
size. There is no colour anywhere in the app. Renaming the field would churn four adapters for
zero behaviour change, so the name stays and this note exists so nobody "corrects" it later.

**Shared-type constraint:** `LifeArea` (`Home/HomeModels.swift`) is decoded by the Home, Tasks,
Journal and LifeAreaDetail adapters. Editor-only fields must live on a separate DTO — the same
trap `Tag` posed in the Tag Editor UI block.

**Latent decode trap to fix in passing:** `LifeArea.CodingKeys` maps `sortOrder` → `"sort_order"`
(a Supabase leftover), but every AWS adapter bypasses `Codable` and constructs `LifeArea` manually
from a camelCase `sortOrder` DTO. Any write path that naively *encodes* a `LifeArea` would send
`sort_order` and silently no-op against a backend reading `sortOrder`.

**E's product decisions, 2026-07-30 — binding:**

- **Editable:** name (rename) and emoji (`colour`). **Creating** new life areas is in scope — this
  supersedes the backend docstring's "fixed 9-row set" assumption. The signup seed trigger is
  unchanged; it seeds the starting 9, it does not cap them.
- **Reorder does NOT live in Settings.** It is a **subtly-presented toggle on the Home screen**
  that puts the life-area grid into drag-and-drop reorder mode, writing `sortOrder`.
- **No delete. Archive instead.** Archiving greys a life area out and removes it from the Home
  grid. Deletion was rejected: this app has no DELETE route for tasks or captures either, and
  nothing here has undo.
- **Archived areas' existing items fall into "Unassigned."** Tasks/captures/logs keep their
  `lifeAreaId` in the database — only the *display* grouping changes, so they surface under the
  existing trailing "Unassigned" group rather than becoming unreachable. Archiving is therefore
  fully reversible with no data migration.
- **Archived areas stay visible in all five life-area pickers, greyed and unselectable**
  (Task Create, Task Detail, Capture triage, Journal filter, Log composer). Chosen over hiding
  them so a task that already carries an archived area never renders blank or silently reassigns.

- **Archived areas still reserve their names** (E's decision, 2026-07-30, taken while reviewing the
  backend diff). A name clash against an archived area returns `409` like any other, because that
  reservation is what guarantees unarchiving can never produce two areas sharing a name — and with
  no merge concept for life areas, such a duplicate would be unresolvable. The `409`'s `conflict`
  object therefore carries an `archived` boolean, so the UI can offer "you have an archived life
  area called X — unarchive it instead?" rather than an unexplained wall.

**Agreed build order — three blocks, one review gate each:**

1. **Life Areas backend** — `PATCH /life-areas/{id}` (name, colour, archived), `POST /life-areas`,
   and the `sortOrder` write path. Python only, proven by smoke test before any SwiftUI touches
   it, per the Stage C.6 / Tag Editor precedent.
2. **Settings → Life Areas UI** — the disabled `settingsLifeAreasRow` goes live: list, rename,
   emoji, create, archive/unarchive. **E's UI decisions, 2026-07-30:**
   - **Emoji input = a curated tap-grid PLUS a free-type field.** iOS 16 has no native SwiftUI
     emoji picker (the "emoji keyboard" is just the system keyboard's globe key), so this had to be
     designed rather than assumed. The grid covers the common case in one tap; the field covers
     anything not shipped in the grid.
   - **Archived areas live in their own "Archived" section** at the bottom of the list, greyed,
     each carrying a badge. Chosen over inline-greyed (archived rows would clutter the list E scans
     most) and over a show/hide toggle (unarchiving would depend on discovering the toggle).
   - **The `409`'s `archived` flag is only actionable on CREATE.** Creating a name held by an
     archived area offers "Unarchive it instead?"; *renaming* onto an archived area's name cannot
     offer that, because unarchiving the other area does not resolve the rename. The rename path
     states the clash and offers Cancel only.
3. **Home reorder toggle + archived-aware display** — the drag-and-drop toggle on Home, plus
   greying archived areas in the five pickers and routing their items to "Unassigned".

**One further decision recorded here, from the Settings rebuild's open items:** **Sign Out gets a
confirmation dialog** (E's call, 2026-07-30). It was consciously not built in the Settings rebuild
because it is a behaviour change. It will be folded into the **About & Diagnostics** block, since
that is the next block that touches `SettingsView`.

**Two locked product rules for the Tag Editor (E's decisions, 2026-07-30):**
- **Delete** shows a usage count on the row, requires an explicit confirm naming that count, then
  cascades (deletes the tag *and* its junction rows). "Block deletion while in use" was rejected
  because it creates a dead end with no in-app way to find where the tag is used. No-confirm
  delete was rejected because this app has no undo and no soft-delete anywhere.
- **Rename clash** always presents a definitive choice — *Merge into &lt;existing&gt;* or *Choose a
  different name* — and **never** a silent rejection. This is what puts merge in scope: every
  `CAPTURETAG#`/`TASKTAG#` row must be re-pointed from the old tag to the survivor, deduped where
  an item already carries both, then the old tag deleted.

### Post-v1 — Task Detail: staged-vs-immediate-apply clarity (agreed 2026-07-31)

Logged by E on 2026-07-19, deliberately left unscoped twice, scoped on 2026-07-31. Task Detail has
two kinds of control and communicates nothing about which is which:

- **Staged behind Save:** title, notes, life area, priority, due date.
- **Immediate-apply:** Mark Done/Reopen, tag add/remove, the countdown-nudge selection, the
  "Notify me when this is due" toggle.

**E's decisions, binding:**

- **Save reflects state, and a save is confirmed.** Save is disabled when there is nothing to save
  and re-enables on the next edit; a successful save shows a brief inline "Saved" confirmation
  (icon + text, never colour alone) plus a haptic. Nothing on failure — failure is already carried
  by the error message.
- **Backing out with unsaved changes confirms before discarding** — *Discard Changes* /
  *Keep Editing*. Auto-save-on-leave was rejected: it would remove the ability to abandon an edit,
  and this app has no undo and no soft-delete anywhere (same reasoning as the Tag Editor delete
  confirm and the Sign Out dialog above). With no unsaved changes, back-out is unchanged — the
  dialog must never appear for a user who only looked at the task.
- **The immediate-apply groups are labelled as immediate** with static section footers. No control
  moves, is restyled, or is reordered — labelling only. Layout decisions stay E's.

**The correctness defect this exposed, and its fix (Cowork's recommendation, invited by E and
adopted 2026-07-31).** The nudge and due-moment controls are immediate-apply but act on the view's
*staged* due date, so scheduling a notification against an unsaved date arms a real OS notification
for a time the stored task does not have. Reverting them to read the saved snapshot is not an
option — that is the original bug found on E's iPhone 15 Pro and fixed in `f5926da`. **Neither value
is correct while the two buckets coexist**, so instead: **both notification controls are disabled
while the due date has unsaved changes**, with a plain line saying to save the due date first, and
re-enable the moment it is saved or reverted.

Rationale for gating over the two alternatives: making the notification controls staged too does not
actually achieve one bucket (tags and the status toggle remain immediate) and adds a parallel
pending-notification system to reconcile against `UNUserNotificationCenter`, which deliberately is
not treated as a source of truth for prior selections. Making the due date immediate-apply would
break the staged model chosen in M5 and would fire the existing "a due-date change cancels scheduled
nudges" rule on every picker adjustment. Gating is the smallest change, it states the real
constraint rather than hiding it, and the dirty-state tracking it needs is already required by the
Save and discard-confirmation decisions above.

**Queue after this block:** About & Diagnostics (which carries the Sign Out confirmation dialog
above) → Inbox `primaryText` header.

---

## Notes

- **Resolved 2026-07-18:** new signups used to land on an empty Home Dashboard (no
  `life_areas` rows existed until a one-off manual seed). Fixed via a `SECURITY DEFINER`
  trigger on `auth.users` (`Monday 13th July/supabase/migrations/0009_seed_life_areas_on_signup.sql`)
  that seeds the fixed 9-row set on every new signup, idempotent against the `0008`
  `(user_id, name)` unique constraint. A follow-up migration (`0010_revoke_execute_seed_life_areas_fn.sql`)
  revoked the function's PostgREST `EXECUTE` grant from `anon`/`authenticated` per Supabase's
  security advisor — the trigger itself is unaffected since Postgres invokes trigger functions
  internally, not through the exposed API.
- **Resolved 2026-07-18:** the due-nudges strip on Home, deferred out of FEATURE-M2, is now
  designed as part of the Nudges FEATURE block (drafted 2026-07-18, awaiting Claude Code
  build). Mobile computes due-ness using the device's local timezone, not hardcoded UTC — the
  web app's `isNudgeDue` has a live, unfixed bug there (`QA_AUDIT.md` FIX-005: nudges fire an
  hour late during BST) — mobile does not copy it.
- **SUPERSEDED 2026-07-18 — see "FEATURE: Flexible Nudge Schedules" in `TODO-CLAUDE-CODE.md`:**
  the line below describing mobile as limited to 3 fixed 9am-only presets is no longer
  accurate as a forward-looking rule; it's kept here for history only. E found the 3-preset
  restriction too narrow in practice (no way to set e.g. 8am) and asked for real flexibility:
  any time-of-day, any weekday combination. The redesign still deliberately avoids general
  cron parsing and avoids a third-party cron library (same reasoning as originally stated
  below — sidesteps the UTC-bug risk class) by parsing only the specific fields needed
  (minute, hour, day-of-week list) rather than full cron syntax. "Multiple times per nudge"
  was considered and explicitly rejected — users create multiple nudges instead. ~~Mobile also
  does not implement general cron parsing (no Swift stdlib equivalent, no external dependency
  added): schedules are limited to the same 3 fixed presets web's create/edit UI already
  defaults to (Daily 9am, Weekdays 9am, Every Monday 9am); web's free-text "Custom…" cron
  option has no mobile equivalent.~~ A nudge with a schedule outside the newly-supported
  subset (day-of-month/month constraints, step values, etc.) still displays on mobile but is
  never computed as due — same asymmetry as before, just a wider supported range now.
- **Resolved 2026-07-18 (doc drift):** §4's RLS rule was a blanket "never construct `user_id`
  client-side" statement that didn't distinguish INSERT from SELECT/UPDATE/DELETE. Corrected
  with an explicit INSERT carve-out after Claude Code found every insert across the app (Task
  Create, Capture, Nudges, Journal) was failing RLS with a 403 because `user_id` was never set
  — confirmed live via Supabase MCP (no column default, no `BEFORE INSERT` trigger on any
  table). See §4 for the corrected rule.
- **Drafted 2026-07-18:** Journal (Logs/Journal Feed tab) FEATURE block written to
  `TODO-CLAUDE-CODE.md`, awaiting Claude Code build. `TabView` order corrects to the
  documented Home/Tasks/Journal/Nudges sequence (Nudges was temporarily 3rd since Journal
  didn't exist yet). Life-area filtering on the feed is a mobile-only addition — web's
  `LogService` supports the filter but no web screen currently wires it up.
- Every screen/feature below F-Mobile-1 (Auth) is blocked until Auth ships and is reviewed — RLS means no other table is queryable without a session.
- Design decisions here defer to the web project's own precedent wherever one exists (e.g. auth methods, no-delete conventions, append-only logs) rather than inventing new mobile-specific rules — the two clients should feel like the same product.
- One feature at a time: this doc will grow section-by-section as each FEATURE block is designed and reviewed, per the project's workflow rule.
