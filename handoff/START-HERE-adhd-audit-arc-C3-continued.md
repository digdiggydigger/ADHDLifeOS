# START HERE — `F-C3-RecentlyDeleted`, continued. Three cycles are landed; the writes are next.

*Written 2026-09-22 by the session that paid `F-C2`'s screenshots debt, collected BOTH device
looks, and began `F-C3`. A disposable pointer: archive it when you write your successor. Its
predecessor, `archive/START-HERE-adhd-audit-arc-C3-deleted.md`, is spent — but **read it anyway**,
because its §1 and §2 (what `F-C2` shipped, and four things it learned) are still true and are not
repeated here.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."* **Every design question below is answered. Nothing is owed to E.**

## 0. Before anything else

1. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-c3-deleted`
   (the previous branch of that name was merged; make a fresh one).
2. **Read:** `CLAUDE.md` (§1–§7, especially §7.6), `claudecode.md`, the
   `### FEATURE: F-C3-RecentlyDeleted` block in `TODO-CLAUDE-CODE.md`,
   `handoff/ADHD-AUDIT-BUILD-LOG.md` **session 5**, and `OPEN-ITEMS-REGISTER.md` edition 74.
   Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`.
3. **Start the emulator** — `./scripts/emulators.sh --import scripts/audit/emulator-state` — and
   leave it running. It was UP at close-out.

### 0.1 NOTHING IS OWED TO E. Do not ask for a device look.

**Both looks were collected on 2026-09-22 and both PASSED.** `F-C1`'s shape (fully rounded, no
chip, one line, the subject reading in full) and `F-C2`'s capsule ("Kept in your inbox · ↗ Reopen",
Reopen landing on that capture, the badge ticking 24 → 25), plus E's own words on the swipe-back:
*"Also passes"*. Eleven frames are filed in `screenshots/undo-capsule-device/` and
`screenshots/drafts-to-inbox-device/`, each with a README.

**One thing is unverified ON DEVICE and NO BLOCK OWES IT: the radius cap.** E's larger-text look
was the top of the STANDARD range with "Larger Accessibility Sizes" OFF — E supplied the settings
page as its own frame so nobody could over-claim it — and the cap only differs from a plain capsule
once the layout STACKS, which needs an accessibility size. The AX3 simulator render covers it
(`screenshots/drafts-to-inbox/04-note-closed-capsule-kept-in-your-inbox-AX3.jpg`). **Do not raise
it with E as an owed item.**

## 1. What `F-C3` has ALREADY landed — do not rebuild it

Three RED→GREEN→commit cycles, each with the RED observed before any implementation:

1. **`ADHD LifeOS/RecentlyDeleted/SoftDelete.swift`** — `isLive(deletedAt:)`,
   `isPurgeable(deletedAt:asOf:)`, `retention` (30 days), and `SoftDeleteError.itemIsDeleted`.
   8 tests (`SoftDeleteTests`).
   - **`nil` means LIVE.** Every document written before this block has no key at all.
   - **A FUTURE stamp is still a delete but is NOT purgeable** — a second device with a fast clock
     must not cause an immediate purge.
   - **A deviation from the spec's signature, already made and already justified in the commit:**
     the spec proposed `isLive(deletedAt:asOf:)`; `asOf` cannot change that answer, so the clock
     belongs to the purge alone. Do not "restore" it.
2. **The stamp on four models** — `TaskItem`, `TaskDetail`, `TaskSummary` (all `deleted_at`,
   snake_case) and `Capture` (`deletedAt`, camelCase). 5 tests (`SoftDeleteCodecTests`) asserting
   the WRONG spelling is ABSENT, because a wrong key raises nothing: it writes a field nothing
   reads. `Capture`'s property is declared LAST on purpose (synthesised memberwise init).
3. **`ADHD LifeOS/Firebase/FirebaseManager+SoftDelete.swift`** — the `SoftDeletable` protocol,
   `live(_:)` for lists and `requireLive(_:)` for single-document reads, applied to **all nine**
   read paths across `+Tasks` and `+Captures`. 5 tests (`SoftDeleteCallSiteTests`).
   - **The COUNTS are the point.** That test pins `count(of: "func fetch") == 4` (tasks) and `== 5`
     (captures) alongside the number of `live(` wrappings. **A tenth read path added later fails
     it.** If you add a fetch, filter it and update the count DELIBERATELY.
   - `fetchTaskDetail(id:)` and `fetchCapture(id:)` **throw** `SoftDeleteError.itemIsDeleted`
     rather than returning nil: a stale route (widget link, nudge, a capsule held across a tab
     switch) must not open a deleted item as live and editable.

**This state is SAFE and INERT.** Nothing writes `deleted_at` yet, so `live(_:)` returns everything
and `requireLive(_:)` never throws — behaviour is unchanged, which is why it was landed on its own.

## 2. What is next, in order. Every decision is made.

### 2.1 The writes — and they go through `FirestoreFieldPayloads`, never inline

CLAUDE.md is explicit that hand-written Firestore dictionaries live in `FirestoreFieldPayloads`.
Add `softDelete(now:)` and `restore()` there, **test both with the wrong spelling asserted
absent** — the partial update is a SECOND key source that can silently diverge from the `Codable`
key, and `SoftDeleteCodecTests` does not reach it.

**Restore ERASES the field with `FieldValue.delete()`**, never writes null. The precedent is
`FirestoreFieldPayloads.captureUnprocessed()` (`["processed": false, "clearedAt": FieldValue.delete()]`),
and the reason is the same trap as everywhere else in this block: an explicit null leaves the
collection in two shapes.

**Tasks are snake_cased (`deleted_at`), captures camelCase (`deletedAt`).**

### 2.2 The manager methods, and the naming is decided

- `softDeleteTask(id:now:)` / `softDeleteCapture(id:now:)` — an `update`, not a delete.
- `restoreTask(id:)` / `restoreCapture(id:)` — the erase.
- **`deleteTask(id:)` / `deleteCapture(id:)` KEEP their names as the HARD delete**, used only by
  the purge and by "Delete forever". Re-pointing an existing method name at different behaviour is
  the silent-semantics trap; a caller who wants the irreversible thing should have to type it.
- `fetchDeletedTasks()` / `fetchDeletedCaptures()` — fetch as today, filter `!isLive` client-side.
  **Do not write a `whereField` for this either**, for the same null-matching reason.
  **These two are new `func fetch`es, so `SoftDeleteCallSiteTests`' counts MUST be updated** — 4→5
  and 5→6 — and they must NOT be wrapped in `live(`. That test will tell you.

### 2.3 Take the hard delete OUT of the UI-facing seams

Remove `deleteTask` from `TaskDetailClientAdapting` / `TaskDetailBackingStore` and `deleteCapture`
from `CaptureClientAdapting`; the only route to a real document delete becomes the new
`RecentlyDeletedBackingStore`. **End-of-block check:**
`grep -rn "deleteTask\|deleteCapture" "ADHD LifeOS/"` returns nothing outside `Firebase/` and
`RecentlyDeleted/`. Leaving a dormant hard delete on the detail seam is a loaded gun.

**The reversal surface is small and already counted** (2026-09-22): `TaskDetailServiceTests` (2),
`FirebaseTaskDetailClientAdapterTests` (2), `FirebaseCaptureClientAdapterTests` (1),
`CaptureInboxTriageActionsTests` (3), plus `FakeTaskDetailClientAdapting` and
`FakeCaptureClientAdapting`. Reverse them to assert a soft-delete write; do not delete them.

### 2.4 The capsule — two new kinds, and the exact switches that will fail the build

E's Step 0 answer 2: *"Yes, show the capsule too"* — "Task deleted · Undo" at the moment of the
delete, on top of the 30-day list. Undo = restore.

**The compile-round budget, enumerated 2026-09-22 so you do not discover it one file at a time:**
`RecentActionKind` has five switches (`verb`, `systemImage`, `glyphTint`, `actionLabel`,
`actionSystemImage`) all in `Undo/RecentAction.swift`, plus the exhaustive header-arrow switch at
`Capture/CaptureInboxUndoSections.swift:116`. **And `UndoCapsuleCallSiteTests.swift:228` pins that
line VERBATIM** — `"case .taskClosed, .nudgeDismissed, .draftKeptInInbox, nil: return false"` — so
it must be updated, which is that test working, not breaking.

**The Undo closure outlives the screen that recorded it.** `performDelete()` pops task detail, so
`TaskDetailService` is gone when Undo is tapped: capture the adapter and the id in the closure, the
`ComposerDraftFiler` shape, recorded through `\.recordAction`. **And restore must post
`DataChangeSignal.post()`** — `TaskListView` and `CaptureInboxView` both observe
`DataChangeSignal.changes`, and without the post a restored item does not come back until the next
tab visit.

### 2.5 The screen and its Tools row

**A headed SECTION, not a third bento card** — E said "row", and `ToolsRoutinesSection` is the
precedent (`ToolsView.swift:72-79`). **Do NOT copy its `@available(iOS 17.0, *)` gate**: that
exists because Places is 17+, and Recently Deleted has no such dependency and must stay reachable
on the 16.0 floor (§7.1). `ToolsCatalog` and `ToolsCatalogTests` are then **untouched** — verified
2026-09-22 by reading `ToolsCatalog.swift`, which pins the CARD count only.

**Restore is a 48pt VISIBLE button** (round 7's rule: anything that undoes is a key target), never
swipe-only — that is the GEST-2 finding this arc is fixing elsewhere. 48pt has precedent
(`PrimaryActionButtonStyle`, `LoginView`) and is on the grid, so no §2 waiver is needed. The house
row idioms are in `ToolsRoutinesSection`: `MomentumBorderedButtonStyle(minHeight:)`,
`Haptics.play(.light)`, `.bentoCard()`, and **the identifier on the headline, not the container**
(a container id renames the button out from under itself).

**Presentation as a pure enum** (the `ToolsRoutinesCatalog.content(from:)` shape) so rows, the
empty state, days-remaining and the "Delete forever" copy are all testable without a view body.

### 2.6 The purge

E's Step 0 answer 1: *"The app, when you open it"* — a `.task` after first render, clearing
anything older than 30 days, **with an injectable clock**. The accepted cost is stated in E's own
question: nothing is purged while the app is never opened. A server function stays available as
later hardening.

### 2.7 The copy that is currently FALSE — this is not optional

`TaskDetailView.swift:113-123`'s delete confirmation says **"This can't be undone."** under a
"Delete Task" button. Soft delete makes that sentence untrue, and it is the one line the user reads
to decide. **It must change in this block** (candidate: *"You can restore it from Recently Deleted
for 30 days."*), and **"This can't be undone" MOVES to the "Delete forever" confirm**, where it
becomes true — which is Q10's sanctioned friction. Check `CaptureDetailView.swift:107-119`'s
*"Discard this capture?"* for the same problem at build time. `apple-design`'s writing lens applies
(`writing.md`, `feedback.md`).

## 3. What is NOT owed, and what must NOT be re-tuned

- **No device look. No RM-on pass** unless the new screen adds a reduced site; if it draws with
  plain `List`/`Form` rows and no new animation, say none is owed and why (§7.3).
- **`firestore.rules`: verified unchanged against `:55-59`** — the owner already has full write on
  `tasks` and `captures`, so a `deleted_at` field needs no new allow rule. **The spec's optional
  hardening (`request.resource.data.deleted_at <= request.time`) was CONSIDERED AND DECLINED**
  by the build session, for a reason worth keeping: the stamp is the CLIENT's clock (`completedAt`'s
  precedent), so a phone whose clock runs a minute fast could not delete anything at all, and the
  only thing the rule prevents is a user pre-dating their own purge window — their own documents,
  their own loss. Say so in the report; E republishes to confirm nothing changed.
- **`deleteCapture` does NOT clean up Storage media** (read 2026-09-22 —
  `FirebaseManager+Captures.swift:60` is a plain document delete). So a photo or voice capture
  ALREADY orphans its media on delete today. Soft delete does not change that, and the purge will
  orphan it exactly as today's immediate delete does. **Pre-existing, out of scope, named so it is
  not mistaken for something this block introduced.**
- **Do NOT re-tune:** the capsule's radius cap, `peekStep = 14`,
  `floatingPaddingHorizontal = 12`, the tab bar, the capture disc, the appearance override, the
  Confirm celebration's RM waiver.
- **Do NOT "improve" task detail's autosave to on-blur** — saving resets the Form's scroll, which
  is why it fires on leaving.

## 4. Traps this session paid for

1. **The AX3 render set needs TWO runs.** The swipe-back test signs out of the account the composer
   test leaves behind, and at accessibility text sizes the taller Settings rows push
   `signOutButton` past the harness's eight swipe attempts — it fails with *"Settings opened but
   presented no sign-out control"*, which reads like a bug in the thing being photographed. A fresh
   erase fixes the FIRST test in a run, not the second.
2. **`UITestSession.focusAndType`'s focusing tap lands BETWEEN words at accessibility sizes.** An
   equality assertion on the resulting text reported a WORKING autosave as broken. Assert typed
   text with CONTAINS.
3. **On the Journal the capsule STANDS IN for the pencil disc**, so with any capsule pending there
   is no `journalComposeButton` to tap. Any harness that files a draft must drive the journal FIRST.
4. **A plausible mechanism is not a measured one.** A finding was reported ("the Captures tab
   truncates because the badge takes width") whose mechanism was wrong — the badge is an `.overlay`
   and consumes no width — and which E's own device frames then disproved outright. It survives as
   a simulator-only observation in register §D. Measure before explaining.

## 5. The state you inherit — VERIFIED at close-out, not assumed

*Every line below was checked with a command at 2026-09-22 close-out.*

- **`main` @ the merge of PR #184**, `git status` clean, local and `origin/main` identical.
  The session's final report pastes both SHAs.
- Suite **3,192 / 0**, SwiftLint **0 / 859**, build **SUCCEEDED**, coverage
  **29.89% (14,713/49,217)** — comparable to 2026-09-20's 29.83% (14,612/48,985), because the
  denominator moved only by the tree GROWING and both runs measured 100% of the app target.
- **The simulator (`9181EBF9-…`) was ERASED and is Shutdown.** A UI run poisons it for the next
  unit suite; the render passes this session were UI runs.
- **The Firebase emulator was UP** with the audit's imported state.
- **E's phone has `main` @ `4917955`** — `F-C1` + `F-C2`, which is what both device looks were
  taken on. Nothing since then changes app behaviour.
