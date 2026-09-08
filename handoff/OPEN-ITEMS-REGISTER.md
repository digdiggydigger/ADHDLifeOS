# Open items register — 2026-09-08, midday (twelfth edition; F-TabDepth-2-SearchRowAtRoot built on top of block 1, both on E's phone, PR #35 carries both and awaits E's verdict)

*This edition covers the fresh session E ordered for block 2. E opened it with the three block-1
checks still undone — *"Can I complete them after you've built block 2?"* — so block 2 was built
on `feature/tab-depth` on top of block 1 rather than after a merge, and the phone now carries
both. The eleventh edition (`bab1681`) is in git history; this one carries only what is still
true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the eleven earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `38b309c`** (PR #34, docs) · **branch `feature/tab-depth`, pushed, PR #35 OPEN with
BOTH blocks** — block 1 `639cf24` + `96aa629` + `bab1681`, block 2 `c4fba78`, plus this
close-out · every change lands through a PR · verified ON THE BRANCH at `c4fba78`: **unit suite
2,543 / 0** (emulator UP, 0 `127.0.0.1:9099` hits, 0 skipped), **SwiftLint 0 / 719**, sim +
device builds green, **`SearchRowDepthJourneyUITests` 1 / 0 (132 s)**,
`TabReselectionJourneyUITests` 3 / 0 (carried, block 1's run) · **app target 24.76%
(11,189/45,196)** — denominator +7 over block 1's 45,189 (the guard, the computed scope, the
animation), numerator +1 · **E's phone runs the BRANCH build at `c4fba78`** (binary 12:06,
`App installed` 12:07; the launch was refused — the phone was LOCKED — so E opens it, force-quit
first) · sim `9181EBF9…` ERASED after both UI runs and is signed out · `firestore.rules`
untouched · the emulator was left running · every `.xcresult` deleted after its figures were
read.

**Built this session, IN PR — F-TabDepth-2-SearchRowAtRoot (`c4fba78`):**

- **E's ask (06:20, with a screenshot):** *"we need to remove the 'search tasks' search bar from
  a full view task screen."* The row is mounted once at the root and `RootView` derived its
  scope from `selectedTab` ALONE, so the root never learned the tab had gone deeper.
- **What shipped:** `AppSearchScope.scope(for:isAtRoot:)` (`.none` below the top-level page,
  `isAtRoot` with NO default, the one-argument form gone); `RootView.searchScope` masks the
  tab's scope by `tabNavigation.isAtRoot(selectedTab)` and `.onChange(of: searchScope)` feeds
  the model — so a push, a pop and a tab switch all move it, and switching back to Tasks with
  its detail still pushed keeps the row hidden; `RootBottomOverlay` animates the row on the
  house spring keyed on the scope. **Judgment call E can veto:** the same spring now fades the
  row on a tab SWITCH too, where it used to pop with the hard-cut tab content.
- **Evidence:** tests first, watched red THREE ways — the rule at compile (`extra argument
  'isAtRoot'` ×5); then, with the rule in and the root deliberately still feeding `isAtRoot:
  true`, the call-site guard on its own assertions (3 across 2 tests); then the UI journey
  against that same build at *"E's screenshot, unchanged"* (162 s). Green: scoped 34 / 0,
  journey 1 / 0, full suite 2,543 / 0. Red-checked one at a time after the commit:
  rule-ignores-depth predicted 2 / actual 2; root-ignores-depth predicted 1 / actual 1;
  restore proven 13 / 0. `seedTask` hoisted to `UITestSession` (`UITestFixtures.swift`).

**Built last session, IN THE SAME PR — F-TabDepth-1-PopToRoot** (re-tap pops to root or
scrolls to top; Nudges gets a Back control; the probe table is in
`handoff/SESSION-OPENER-tab-depth-design.md`). (carried; nothing about it changed)

## A · Decisions only E can make — minutes each

- [ ] **Do both blocks behave on the phone?** Four checks in one sitting: Today → Nudges → tap
      Today; the Nudges Back chevron; scroll any tab down and re-tap it; **Tasks → open a task's
      detail: the "Search tasks" row is gone beside the disc, and back on the list after the
      re-tap.** "Yes" → merge PR #35, reinstall from main. **Blocking the merge.** (updated —
      was block 1's three checks; E deferred them to this sitting)
- [ ] **Keep the row's spring on a tab SWITCH?** Block 2's one judgment call: the row now fades
      in/out with the house spring when the tab changes, not only when a detail is pushed. One
      line to revert if it reads as lag over a hard-cut page. **NEW.**
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

1. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   A fix that ARRIVES but lands outside every radius still clears the card (the app ignores
   `horizontalAccuracy`; the probe puts it at ~3% of pulls at 40 m jitter with Home alone, 27%
   at 65 m). Widening `LocationFixProviding` to carry accuracy touches every caller, which is why
   it was not bundled into the coin-flip fix. (carried, deferred on purpose)
2. **`HomeService.load()` empties `allTasks` on a failed fetch**, which would drop the card
   through the re-check; the inbox precedent keeps last-known on failure. One line + one test.
   (carried, small)
3. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
4. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
5. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with the 06:37 device build, so the
  profile is roughly valid to **2026-09-15**. This session's 12:06 device build needed no
  provisioning update. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A "rule right, wiring wrong" red is worth staging on purpose.** With the pure rule in and the
  root deliberately still ignoring the depth, the call-site guard AND the UI journey both went
  red on their own assertions — proof that each catches exactly the defect this repo ships
  most (a correct helper nothing feeds), not merely a missing symbol. (NEW)
- **Derive, then `onChange` the derived value.** One `.onChange(of: searchScope)` over a computed
  property covers the tab switch, the push and the pop; two handlers keyed on the inputs would
  have raced each other's `activate`. (NEW)
- **`xcrun xcresulttool export attachments --path <bundle> --output-path <dir>`** pulls a
  journey's `XCTAttachment` screenshots straight out of the result bundle — the two frames that
  settled block 2 by eye came from there, no device or mirroring needed. (NEW)
- **A locked phone refuses the LAUNCH and not the install** — `App installed:` then
  `NSLocalizedFailureReason … Locked`. Confirmed again; read the reason before suspecting the
  build. (carried, confirmed)
- **Ask before designing when E invites it; read the user's REAL data before choosing between
  hypotheses.** (carried)
- **The resolver's tie-break was designed for different radii**; any future "which place"
  caller should take the ordered LIST, not the head. (carried)
- **The fence ledger shows all three home fences flapping departure → arrival within 4 s.**
  (carried)
- **A swiftc probe of the pure files + the user's real coordinates settles a geometry question
  in a minute.** (carried)
- **A `CGContext` bitmap is TOP-DOWN**; **red-check regressions ONE AT A TIME**; **iPhone
  Mirroring cannot be started from the terminal.** (carried)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** — never scope a red-check down for speed.
  (carried)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is `START-HERE-tab-depth-verdict.md`** — `START-HERE-tab-depth-arc.md`
  consumed and archived in the same move. Exactly one is live. (updated)
- **A `NavigationPath` is blind to closure-link and flag pushes, and a path reset pops neither**
  — the design record has the table. (carried)
- **The harness's `openTab` returns early on a selected slot**; the late "Save Password?" sheet
  swallows swipes as well as taps — wait for HITTABLE. (carried)
- **A zero-height anchor view inside a padded stack costs its spacing** — put the `id` on the
  padded root. (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. No folder for block 2:
  the journey asserts what the frames show, so a folder would be weight without evidence.
  (carried, applied)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
