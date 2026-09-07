# Open items register — 2026-09-07, second edition (the queue-clear close-out, then E ruled on and got the Routines permission footer: built, landed #18, on device awaiting E's look)

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `a3e4bde`** (PR #18's merge; this edition lands on top), local = remote, tree
clean, only `main` exists · every change lands through a PR (#13–#18 this session, none needed
a bypass) · last full verification: unit suite **2,469 / 0** with the emulator UP and
SwiftLint **0 / 706** at the `5acc054` tree, `ToolsRoutinesJourneyUITests` 3 / 0 post-change · **the full UI target ran class-batched on main
(`fe980d4`), all 29 tests: 28 green + `testRenderSignUpForm`, which the run HARDENED to 3/3
reproducible, root-caused, and #15 fixed with three consecutive greens (78.6s / 79.9s / 79.6s)**
— 30 → 29 because `HitTestProbeUITests` was deleted with #5 · the sim was erased after every UI
sequence (three erases; the poison rule held) · **E's phone TRACKS MAIN**: reinstalled twice on E's word
(2026-09-07 03:24 from `d700646`, then 04:28 from `a3e4bde` so the permission footer is on
device; both `devicectl` + `--terminate-existing`, zero "No Accounts") · `firestore.rules`
untouched this session · the emulator was left running.

**Shipped and CLOSED this session (PRs #13–#15):**
- **F-DailySummarySweep** (#13, `f3673e7`) — register B1, E's queued instruction: the
  daily-summary blob (`home.dailySummary.snapshot`, quotes task titles and journal reflections)
  now cleared by `AuthService`'s session-ending hook — the leak family's last member, at-rest
  half closed (`belongs(to:)` already blocked display). Nil-safe `clear()` on
  `UserDefaultsDailySummaryStore`, source pin extended, TDD staged, red-check 2 + 1.
- **F-WidgetCopyLifeOS** (#14, `98f2dce`) — register B2, the word picked by E in chat
  2026-09-07: **"Open LifeOS once and your areas will appear here."** The Life Areas widget's
  signed-out empty state was the last surface calling the app Momentum. Copy pinned from source
  (`LifeAreasWidgetCopyTests` — the widget view compiles only into the extension); red watched,
  red-check 1 test / 2 assertions.
- **The post-fix full-UI-target baseline (register B3)** — run class-batched FOREGROUND-safe
  (six batches, one xcodebuild at a time; the 2026-09-06 watchdog never struck). **Both
  clearance tests green on main. `LandscapeLoginUITests` did NOT recur — that watch-list flake
  is closed. The Save-Password `[AUTOFILL]` sweep fired 8 times across passing runs — live
  proof #5's fix earns its keep.** Evidence: `UIBaseline-*.xcresult` in the repo root
  (gitignored).
- **F-SignupRenderInputSurface** (#15, `bb70144`) — the baseline's one failure, hardened from
  "sim keyboard flake" to 3/3 reproducible on an erased sim and root-caused from the failures'
  own hierarchy attachments: **iOS 26.5 deterministically interposes its Automatic Strong
  Password pane** (`PMSafariStreamlinedStrongPasswordViewController` in
  `UIRemoteKeyboardWindow`) over a Create-account password field — no Keyboard element exists
  while it is up. The AutoFill family's SECOND costume. Three routes back to the visible
  keyboard falsified in runs (re-tap: pane stands; the pane's ✕: drops field focus; typing:
  latches no-software-keyboard). The test now asserts the INVARIANT — an input surface rises
  and the form renders above it — still proving E's two marked items; shot eyeballed (cards
  even, no Done bar, pane below). Harness-only.

## A · Decisions only E can make — minutes each

- [x] **Reinstall E's phone from main** — DONE on E's word (2026-09-07 03:24): built at
      `d700646`, binary stamped 03:24, `devicectl` install + `--terminate-existing` launch
      verified on `wishwashwacky15`. #13's privacy sweep and #14's LifeOS widget copy are on
      device; the profile clock restarts from today's build.
- [ ] **Re-measure coverage?** CLAUDE.md records 23.62% at `b1f4b6f`, stale — the suite is now
      2,465. (carried)
- [x] **The permission-banner footer** on the Routines section — E ruled "build it"
      (2026-09-07) and **F-RoutinesPermissionFooter shipped, PR #18 (`5acc054`)**: the
      Arrival-nudges card (inline fix mirroring the Settings toggle — store write + haptic +
      immediate fence refresh) plus the existing `LocationPermissionBanner(wantsTriggering:
      true)` reused, under LISTED routines only. TDD staged, red-check 2, journeys 3/0.
      **On device at `a3e4bde` — E's device look is the one open check**: flip Settings →
      Arrival nudges off, visit Tools with a routine listed.

## B · Real work, ready to start — recommended order

1. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
2. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
3. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles (valid to 2026-09-10 — three days out). (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **The watch-list is EMPTY.** `testRenderSignUpForm` was never a flake — root-caused and
  fixed (#15). `LandscapeLoginUITests` passed in the baseline — one sighting total, closed.
- **`UIFullRun.xcresult`'s retention condition is met** (the baseline confirmed both #5 and #7
  hold) — deletable at E's word; `UIBaseline-1..9-*.xcresult` are this session's evidence,
  all gitignored in the repo root.
- **The strong-password pane is environmental**: it first interposed 2026-09-06 (the F-
  LandscapeFix-era runs never saw it) and now reproduces on a freshly erased sim — something
  in the runtime/host state changed, not this repo. #15's invariant assertion passes in both
  worlds if an update takes the pane away again.
- **The memory watchdog never struck today** — six class-batched UI runs, one xcodebuild at a
  time; the 2026-09-06 rule (foreground, scoped, erase chained) stands.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in routine-record block 1's red-check — failure-path only,
  unexplained. (carried)
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the
  repo root is the truth for a silently failed write. (carried)
- **The review-session journal rows** from the swipe-path experiment — E's own data. (carried)
