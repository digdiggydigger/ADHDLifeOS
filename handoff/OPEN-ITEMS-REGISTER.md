# Open items register — 2026-09-07, FINAL close-out (third edition today: the whole session end to end — E's queue cleared, the baseline green, the AutoFill family's second costume killed, the phone twice reinstalled, and the permission footer ruled on, built, and device-confirmed)

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes today's two earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `dfb1d10`** (PR #20's merge; this edition lands as the session's ninth PR on top),
local = remote, tree clean, only `main` exists · every change lands through a PR (#13–#20 this
session, none needed a bypass) · last full verification: unit suite **2,469 / 0** with the
emulator UP and SwiftLint **0 / 706** at the `5acc054` tree — no Swift has changed since
(PRs #19–#20 touched `handoff/` and `screenshots/` only) · **the full UI target is effectively
GREEN**: 28/29 in the class-batched baseline at `fe980d4` + the 29th root-caused and fixed
(#15, three consecutive greens), and `ToolsRoutinesJourneyUITests` re-ran 3 / 0 after the
footer change · the sim was erased after every UI sequence (the poison rule held all day) ·
**E's phone TRACKS MAIN at `a3e4bde`** (2026-09-07 04:28, `devicectl`; the two merges since
touched no Swift, so the device build is functionally current — no reinstall owed) ·
`firestore.rules` untouched · the emulator was left running.

**Shipped and CLOSED this session (PRs #13–#20):**
- **F-DailySummarySweep** (#13, `f3673e7`) — the daily-summary blob (quotes task titles and
  journal reflections) cleared by the session-ending hook; the leak family's LAST member,
  at-rest half closed. TDD staged, red-check 2 + 1.
- **F-WidgetCopyLifeOS** (#14, `98f2dce`) — E's word: "Open LifeOS once and your areas will
  appear here." The last surface calling the app Momentum; copy source-pinned.
- **The post-fix full-UI-target baseline** — six class batches, one xcodebuild at a time (the
  memory watchdog never struck): both clearance tests green on main, `LandscapeLoginUITests`
  did NOT recur, the Save-Password `[AUTOFILL]` sweep fired 8× live. 30 → 29 tests because
  `HitTestProbeUITests` was deleted with #5. Evidence: `UIBaseline-*.xcresult`, repo root,
  gitignored.
- **F-SignupRenderInputSurface** (#15, `bb70144`) — the baseline's one failure, hardened to
  3/3 and root-caused from its own hierarchy attachments: **iOS 26.5 deterministically
  interposes its Automatic Strong Password pane** over a Create-account password field — no
  Keyboard element exists while it is up (the AutoFill family's SECOND costume). Three routes
  back to the visible keyboard falsified (re-tap; the pane's ✕ drops focus; typing latches
  no-software-keyboard); the test now asserts the INPUT SURFACE. Three consecutive greens.
- **E's phone reinstalled from main TWICE on E's word** (#17 ticked the first; 03:24 from
  `d700646`, then 04:28 from `a3e4bde`) — the `-allowProvisioningUpdates` builds restart the
  7-day profile clock from today.
- **F-RoutinesPermissionFooter** (#18, `5acc054`) — E ruled "build it" on the item carried
  since the register's FIRST edition. Two independent footer cards under LISTED routines:
  the Arrival-nudges card with an inline fix mirroring the Settings toggle exactly (store
  write + haptic + immediate fence refresh), and the existing self-hiding
  `LocationPermissionBanner(wantsTriggering: true)` reused for the Always grant. TDD staged,
  red-check 2, journeys 3/0. **DEVICE-CONFIRMED by E: "the footer works"** — evidence + the
  test-fire clarification in `screenshots/routines-permission-footer/` (#20). The
  notifications E saw with the switch off were the DEBUG test-fire's designed bypass
  (`isEnabled: { true }`, stated by its own dialog), NOT the gate failing.
- The handoff chores: #16 (queue-clear close-out + opener succession), #19 (footer landed),
  #20 (device evidence), and this edition.

## A · Decisions only E can make — minutes each

- [ ] **Re-measure coverage?** CLAUDE.md records 23.62% at `b1f4b6f`, stale — the suite is
      now 2,469. (carried; the last A-item standing)

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

- **Free dev account** → 7-day profiles; the clock restarted with today's 04:28 build, so
  roughly valid to **2026-09-14**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **The watch-list is EMPTY.** `testRenderSignUpForm` was never a flake — root-caused and
  fixed (#15). `LandscapeLoginUITests` passed in the baseline — one lifetime sighting, closed.
- **The strong-password pane is environmental**: first interposed 2026-09-06, reproduces on a
  freshly erased sim — the runtime/host changed, not this repo. #15's invariant assertion
  passes in both worlds. If any other test ever waits on `app.keyboards` after focusing a
  password field, it has met this pane — the full story is in `UITestAutofill.swift`.
- **`UIFullRun.xcresult`'s retention condition is met** (the baseline confirmed #5 and #7
  hold) — deletable at E's word; `UIBaseline-1..9-*.xcresult` are this session's evidence,
  all gitignored in the repo root.
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN** — its dialog says
  so, and `screenshots/routines-permission-footer/README.md` records the confusion it can
  cause so nobody re-investigates the gate for it.
- **The memory watchdog never struck today** — six class-batched UI runs, one xcodebuild at a
  time; the 2026-09-06 rule (foreground/scoped, erase chained) stands.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in routine-record block 1's red-check — failure-path only,
  unexplained. (carried)
- **The emulator was left running** (`scripts/emulators.sh`); `firestore-debug.log` in the
  repo root is the truth for a silently failed write. (carried)
- **The review-session journal rows** and today's 3:43–4:30 test rows — E's own data,
  deliberate, nothing to clean up.
