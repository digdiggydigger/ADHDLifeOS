# Start here — build F-FocusCard-3, the notification-style stack

*Paste into a fresh Claude Code terminal. Written 2026-09-09 at the close of the session that
shipped **F-FocusCard-2** (PR #47 → `1f0d93a`). Block 2 is CLOSED on E's device verdict: "I've run
a short sprint, and it seems to be working correctly."*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start.

---

## Your job

**Build `F-FocusCard-3` only.** Stop at the end of it and wait for E's device verdict — do not roll
into block 4.

**Read `handoff/SESSION-OPENER-focus-card-design.md` first.** It is the design record and it is
permanent. Block 3's section of it is UNTOUCHED by everything below.

## ⚠ The record's block 1 AND block 2 halves have both been overtaken

Blocks 1 and 2 were each redesigned against the record — block 1 four times on E's device, block 2
once at build time. **Block 3 inherits what actually shipped, not what the record describes.**

| the record says | what actually shipped |
|---|---|
| collapsed card full-bleed to both screen edges | **inset 16pt** (361pt wide), 60pt tall |
| collapsed card has a chevron | **gone** collapsed; kept expanded |
| long-press opens the detail sheet | **single TAP**, in both states; long-press RETIRED |
| completion card shares the "full-bleed flush geometry" | **it floats** — inset 16, radius 24, **all four corners**, 76pt tall. "Flush" is only available to the BOTTOM-most furniture, and this card is not that: it stacks ABOVE a running sprint so that sprint stays operable. |

**Do not undo these.** `AppTabBarMetrics.floatingLift` is still deleted
(`AppTabBarCallSiteTests.testTheBarsBottomPaddingIsUnconditional` fails if it returns), and the
collapsed card is flush only because the bar stopped moving.

## What block 2 already built for you

**The service side of the stack is DONE and tested.** You are building a view.

- `FocusSessionService.unconfirmedCompletions: [CompletedFocusSession]` — **newest-first**
  (`insert(at: 0)`), so the front card is `.first` and **a card's depth in the stack IS its array
  index**. That is exactly what `FocusCompletionStackLayout` needs.
- `pushUnconfirmedCompletion` / `confirmCompletion(_:)` / `restoreUnconfirmedCompletions()` live in
  `Focus/FocusSessionService+Completions.swift`. Confirm already removes → re-persists →
  `setCardCollapsed(false)` → re-saves the confirmed copy.
- `FocusCompletionCard` renders ONE record. `RootBottomOverlay` currently shows
  `unconfirmedCompletions.first`; **your swap is `.first` → the stack.**
- Nothing is auto-confirmed and there is no data cap. Only three layers may DRAW.

## Where things stand

**`main` @ `1f0d93a`. No branch in flight. Nothing for block 3 has been started.**
Verified on main: **suite 2,619 / 0** (emulator up, 0 `9099` hits, 0 skipped), **lint 0 / 731**,
sim + device builds `** BUILD SUCCEEDED **`, **app target 26.37% (12,037/45,646)**.
**E's phone is ON MAIN at `1f0d93a`**, reinstalled after the merge.

## Read these, in this order

1. `handoff/SESSION-OPENER-focus-card-design.md` — the design record; block 3's section is the job.
2. `handoff/OPEN-ITEMS-REGISTER.md` — **seventeenth edition**. THE outstanding list. Its section A
   carries two items that become real in THIS block.
3. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual
   evidence, UI/UX §1–§7.
4. `claudecode.md` — the TDD role definition.
5. `screenshots/focus-completion-card/README.md` and `screenshots/focus-card-collapse/README.md` —
   what E settled by LOOKING, including two bugs no test could have caught.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## Two things E has been shown but has not chosen — raise them before you build

Both are in the register's section A, and **block 3 is what makes them visible**:

1. **The completion card's floating geometry was a deviation E approved by sight, not by
   choosing.** The stack's peek offsets inherit that shape, so it is cheaper to ask now than after
   three layers are tuned to it.
2. **Confirm resets collapse unconditionally.** In E's own stacking scenario — a routine
   auto-starts a sprint while an old card waits — confirming the OLD card expands the NEW sprint's
   card. That follows the letter of E's rule, but stacking and collapse-reset were answered
   separately and block 3 is where they meet on screen for the first time.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 1f0d93a or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 731 files
ls -d *.xcresult                     # expect NONE
curl -s -m 2 http://127.0.0.1:4400/emulators   # emulator; start it if quiet
```

Start the emulator first: `./scripts/emulators.sh` in a second terminal, or
`nohup ./scripts/emulators.sh > /tmp/emulators.log 2>&1 &`. With it down four suites SKIP rather
than fail, so the run stays green but the figures are not comparable.

## Traps that matter for THIS block

- **`ZStack` render order.** Get it wrong and the OLDEST card is in front — and **every layout
  test still passes**. The front card must be `unconfirmedCompletions.first`.
- **`yOffset(1) < 0` pins the peek DIRECTION** so the stack cannot ship upside-down. No other
  assertion catches a sign flip there.
- **Deeper cards need STRICT inequalities** in their tests — a constant stub passes non-strict
  ones.
- **`testConfirmingTheFrontRevealsTheNext` must assert the logger received B's confirmed copy, not
  A's** — that is what discriminates "removed the right one" from "removed one".
- **Cards behind must be `.accessibilityHidden(true)` and non-hit-testable**, or VoiceOver reads
  three Confirm buttons and a tap can hit a card the user cannot see.
- **A call-site guard that no `confirmAll` / `removeAll` exists.** E ruled confirm-all out
  explicitly, one at a time, so confirmation keeps meaning "I looked at this".
- **Keep `id: \.id` stable** so insert/remove animates rather than reshuffles.
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  tests, then reconcile — three of block 2's five red-check predictions looked wrong for only this
  reason. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`.
- **Widening a protocol tips test classes over SwiftLint's 250-line `type_body_length`**, because
  a NESTED type's body counts against its enclosing one. Hoist the `private` fake to FILE scope;
  never add a protocol-extension default, which would silence the compile break that IS the red
  step. Six fakes conform to `FocusSprintPersisting` now.
- **A SwiftUI view can be rendered to PNG from a unit test** — `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, with `overrideUserInterfaceStyle` for dark. The
  test target hosts the app, so every asset colour resolves; no swiftc probe, no signed-in
  simulator, no erase. This is how block 2's evidence was made in a minute. **A three-layer stack
  is exactly the kind of thing to LOOK at rather than assert.**
- **`layoutPriority` decides who is OFFERED space first, NOT who may shrink.** Two instances now.
  Rigid siblings need `.fixedSize()`, and the check is a look, not a green suite.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by re-running; inject
  regressions ONE AT A TIME and predict the count first.
- **Erase the sim between any UI run and the next unit run** —
  `xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`, chained unconditionally.
- **A zsh glob matching nothing aborts the whole compound command** before anything runs. Quote
  the paths in an `rm -f`.

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

A locked phone refuses the LAUNCH but not the install — read `NSLocalizedFailureReason` before
suspecting the build. The free-dev-account profile is roughly valid to **2026-09-15**; an empty
Xcode account list means E must sign in via Xcode → Settings → Accounts, never Claude Code.

**Getting a stack onto the screen to look at needs TWO unconfirmed completions**, and each needs a
sprint's countdown to actually expire (`FocusCheckpoints.minimumIntervalSeconds` floors a sprint at
30s). Render it from a unit test rather than asking E to sit through two sprints to see a layout.

**This arc is almost entirely visual. E's device verdict is the real evidence** — and E iterates
fast, so expect several passes per block. Build, install, report, and ask rather than guessing at
geometry.
