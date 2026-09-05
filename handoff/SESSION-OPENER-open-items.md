Post-location-services session. Read `claudecode.md`, `CLAUDE.md` and the memory index first,
then this brief. Location services is DONE and MERGED — do not reopen it; this opener is the
queue of everything still open, in two tiers.

## Where things stand

- **`main` at `0211d79`** (2026-08-28): the location-services merge (--no-ff, 13 commits). Field-
  tested on E's phone before merging — arrival + departure nudges, custom arrival message, the
  journal's crossing rows all confirmed live. Work on main or branch off it; nothing is frozen.
- `feature/location-services` is FULLY MERGED and safe to delete (local + origin) — E has not
  said to yet, so leave it unless told.
- Suite **1,674 tests / 0 failures**. Lint accepted debt is EXACTLY two warnings: `TaskDetailView`
  file_length (now 433 lines — it grew under the same warning when the at-place picker landed)
  and UITests `static_over_final_class`. Anything else is new — fix it BEFORE committing.
- **Emulator:** `./scripts/emulators.sh` in a spare terminal; "port taken" means ALREADY UP.
  (It is currently running detached via nohup after a tasks-panel dismissal killed its shell —
  a fresh machine boot needs it started again.) Emulator-backed tests SKIP without it, so a
  green suite with it down is quieter than it looks.
- **Device `wishwashwacky15` is current with main** (installed tree is bit-identical to
  `0211d79`). `devicectl` install works; a one-off `PackagePatchFailed` on the widget's
  Assets.car is iOS's delta installer — retry clears it.
- `firestore.rules` (places + location_events) is DEPLOYED and verified identical to the repo.
- Also check `TODO-CLAUDE-CODE.md` "Current Sprint" for any Cowork-written blocks; the items
  below came from E directly and are not tracked there.

## The still-open list — every task, complete

### Tier 1 — mechanical, no design decisions needed

1. **TaskDetail's sprint PLANNER default ignores the default-sprint-length setting.** One-tap
   starts DO use `MomentumPreferences.defaultSprintMinutes`; the detail screen's planner seeds
   from `FocusSprintConfiguration`'s hardcoded standard instead. Make the planner seed from the
   setting for tasks with no stored config (a task's own stored config always wins). Small,
   test-first.

2. **At-place picker in the task CREATE sheet.** Block 4a shipped the picker on task DETAIL
   only. Mirror it in `TaskCreateView`: same `TaskAtPlacePicker`, same only-when-places-exist
   rule, `at_place_id` rides `NormalizedCreateTaskInput` → `FirebaseTaskCreateClientAdapter`.
   Wire tests assert the snake_case spelling and the camelCase absence, per house rule.

3. **"Say this when I leave" — the departure message.** `Place.arrivalMessage` shipped
   (E's request); the departure counterpart is a mechanical mirror: `departure_message` on the
   wire, trimmed-to-nil like emoji, a field under the leaving toggle, carried through
   `AtPlaceSnapshot`, and the SAME rule change — a set message makes departure fire even with
   no open At-Place tasks (today departure is task-gated always). Copy the ArrivalMessageTests
   shape.

### Tier 2 — needs E's input before building (ASK FIRST, don't guess)

4. **Place labels on the block-3 stamps that don't display.** Journal entries, closed tasks and
   focus sprints all STORE `place_id`/`latitude`/`longitude` since block 3, but only captures
   ever SHOW their place. Candidate surfaces: the journal entry row's meta line ("9:20 · at the
   Office 💼" — this exact treatment was in E's approved design canvas, artboard C), closed-task
   timeline rows, sprint timeline cards, task detail for a closed task. Mostly mechanical
   (follow `CapturePlaceLabel`'s named-places-only rule and current-record resolution), but ASK
   E which surfaces they actually want labelled — a place line on every row risks noise, and E
   caught exactly this class of taste call on the capture surfaces.

5. **Auth screens are still V1.** Login/signup never got the Momentum v3 treatment — they
   predate the redesign entirely. This is a design block: E (and possibly a Cowork-written
   FEATURE block) should shape it before any Swift is written. Note Sign in with Apple is BUILT
   but DORMANT (free dev account) — do not remove it, do not enable it.

6. **The captures archive is still behind the interim door** (Areas tab → "Handled captures").
   Where the Captures tab permanently lives in the five-tab IA is E's call — the current door
   was explicitly an interim arrangement. Ask before moving anything; five tabs staying is a
   settled Momentum decision.

## House rules that bit recent sessions

- Per change: failing test first → `swiftlint` (exactly the two debts) → full suite with the
  emulator up → sim build → commit + push → SHA-verify against origin → device build + install.
- File budgets: 400/file, 250/type body, 50/function. House fix is a same-file extension or an
  own-file split with members made internal (`CaptureInboxService+Create`,
  `FocusSessionService+Persistence` precedents).
- Colour is lint-enforced (`raw_hue_color`); haptics via `Theme/Haptics.swift` only; steppers
  confirm once on release; `inclusive_language` rejects "master" in DECLARATIONS (use
  "killSwitch" in test names; comments are fine).
- Wire conventions: tasks/places/location_events/focus_sessions snake_case; captures camelCase
  except `created_at`/`tag_ids`. Tests assert the wrong spelling is ABSENT too.
- iOS 16.0 floor stands app-wide; the Places UI alone is 17+ by E's explicit §7 deviation.

Start with Tier 1 in order unless E says otherwise; open Tier 2 by asking E the questions, not
by building.
