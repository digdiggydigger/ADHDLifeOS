# START HERE — two device looks are owed to E; `screenshots/drafts-to-inbox/`; then `F-C3-RecentlyDeleted`

*Written 2026-09-20 by the session that built `F-C1`'s shape round and `F-C2-DraftsToInbox`.
A disposable pointer: archive it when you write your successor. Its predecessor,
`archive/START-HERE-adhd-audit-arc-C2-drafts.md`, is spent.*

**E's standing instruction:** *"You must ensure to maintain seamless continuity in context and
memory into the new session."* **Every design question below is answered.**

## 0. Before anything else

1. **Branch:** `git checkout main && git pull --ff-only && git checkout -b feature/adhd-c3-deleted`.
2. **Read:** `CLAUDE.md` (§1–§7, especially §7.6), `claudecode.md`, the
   `### FEATURE: F-C3-RecentlyDeleted` block in `TODO-CLAUDE-CODE.md`,
   `handoff/ADHD-AUDIT-BUILD-LOG.md` **session 4**, and `OPEN-ITEMS-REGISTER.md` edition 72.
   Memory: `adhd-audit-build-progress`, `adhd-ux-audit-arc`, `device-build-lag`.

### 0.1 TWO DEVICE LOOKS ARE OWED, BOTH REDUCE MOTION **OFF** — do these first

E has seen neither the reshaped capsule nor anything from `F-C2`.

- **Probe before asking for a cable:** `xcrun devicectl device info details --device 00008130-000268DE3C98001C`.
  It answering at all is the proof the phone is reachable **wirelessly**; it has never needed a cable.
- **Install BEFORE asking for a verdict**, then **force-quit the app** before E judges anything
  ([[ask-for-device-checks-on-a-build-e-has]], [[relaunch-before-judging-device]]).
- **Ask for all of it in ONE message:**
  1. **`F-C1`'s shape round** — close a task on Tasks: fully rounded card, no blue chip behind
     Undo, one line, titles reading much further before truncating.
  2. **The same with Larger Text turned up** (Settings → Accessibility → Display & Text Size) —
     the ONLY look that can say anything about the radius cap, since at default size the capped
     shape and a true capsule render byte-identically.
  3. **`F-C2`** — type into a composer and close it: the capsule should read *"Kept in your inbox ·
     Reopen"*, and Reopen should land on that capture in the inbox. Then open a task, edit a field,
     and **swipe back from the left edge** — the gesture is restored and the edit saves silently.
- **NO Reduce-Motion-ON pass is owed** for either block. Do not ask for one: `F-C1`'s RM-on pass
  PASSED on 2026-09-20, and `F-C2` added no reduced site.
- **The profile expires 2026-09-24T19:49:37Z.**

### 0.2 `screenshots/drafts-to-inbox/` is OWED — the one acceptance criterion `F-C2` did not meet

The spec asks for it: each composer typed-then-closed, the inbox afterwards, and task detail's
swipe-back working. `ADHD LifeOSUITests/UndoCapsuleRenderUITests.swift` is the harness to copy —
it already signs in against the emulator, drives real screens and attaches frames. **Read
`screenshots/undo-capsule/README.md` for the standard the README must meet.**

**Two harness facts that cost this session time:**
- **The AX3 pass needs a FRESHLY ERASED simulator** — the harness signs out first, and at
  accessibility text sizes the taller Settings rows put `signOutButton` past its 8 swipe attempts.
  It fails with *"Settings opened but presented no sign-out control"*, which reads like a bug in
  the thing being photographed.
- **Never pipe `xcodebuild` through `| head -N`** — `head` closes the pipe before `** TEST FAILED **`,
  so the run's own result is never seen.

## 1. What `F-C2` shipped, so you do not re-litigate it

- All three composers file unsent text on `.onDisappear`; `didSubmit` stops a successful submit
  double-filing. **`QuickCaptureView` is presented TWICE** — a `.fullScreenCover` from the disc and
  a `.sheet` from the Capture Inbox.
- **"Close", not "Cancel"**, on all three, each now carrying an accessibility identifier it did not
  have before (`quickCaptureCloseButton`, `taskCreateCloseButton`, `logComposerCloseButton`).
- **Task detail autosaves on LEAVING**, not on field change — saving resets the Form's scroll to
  the top, so a per-blur save would yank the user's position. The explicit Save button stays.
- `RecentActionKind.draftKeptInInbox` with `actionLabel`/`actionSystemImage`. **The five existing
  kinds still answer "Undo" verbatim** — `SignedInJourneyUITests` addresses the control by that
  exact word and UI tests are skipped in the standard run.
- The Reopen door is a `\.openCapture` environment value → `RootView+Doors.openCaptureDoor` →
  `CaptureInboxView.drainReopenDoor()`.

## 2. Four things this session learned the hard way

1. **A `let` with a default value is EXCLUDED from a struct's synthesised memberwise init.** A
   defaulted dependency on a view with no hand-written `init` must be a `var`, declared BEFORE any
   trailing-closure member, because that init takes parameters in declaration order. Three compile
   rounds.
2. **Budget for SwiftLint ceilings.** Four files needed splitting in one block. `RootView.swift`
   was at **400/400** and gave up `capturesTab` to `RootView+Doors`; it is at 393 now.
3. **Moving a call site breaks call-site tests, and that is them working.** Re-point them at the
   new file; never widen to "any file", which stops them catching a real drop.
4. **An exhaustive `switch` earns itself.** A sixth `RecentActionKind` failed the BUILD rather than
   silently inheriting a branch.

## 3. What is NOT owed

- No RM-on pass (§0.1). No `firestore.rules` change — drafts are ordinary `.note` captures through
  the existing seam.
- **Do not fix contrast** (Undo label 3.93:1 light / 4.47:1 dark) — the HELD colour arc's.
- **Do not re-tune** the tab bar, `peekStep = 14`, `floatingPaddingHorizontal = 12`, the capture
  disc, the appearance override, the Confirm celebration's RM waiver, **or the capsule's radius
  cap** (E's call, 2026-09-20).

## 4. The state you inherit

- **`main` @ PR #180's merge.** Suite **3,174 / 0**, SwiftLint **0 / 853**, build green.
- **The simulator (`9181EBF9-…`) was ERASED at close-out** after the UI journeys.
- **The Firebase emulator was left RUNNING** with the audit's imported state —
  `./scripts/emulators.sh --import scripts/audit/emulator-state` if it is down.
- **E's phone already has `main` @ `4917955`** — BOTH blocks, installed wirelessly at close-out.
  Confirm it is still there and **force-quit the app**, but do not rebuild before asking for the
  looks in §0.1.
