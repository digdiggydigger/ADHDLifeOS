# Open items register — 2026-09-08, evening (thirteenth edition; the tab depth arc MERGED on E's verdict, nothing in flight)

*This edition closes the arc the twelfth opened. E ran the four checks on the phone — three from
block 1, one from block 2 — and came back with *"All 4 checks were successful"* and two
screenshots; PR #35 merged on that, the phone was reinstalled from `main`, and the suite was
re-run ON main. The twelfth edition (`aecf82c`) is in git history; this one carries only what
is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the twelve earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `1100a01`** (PR #35, the tab depth arc — both blocks) · **no branch in flight**;
`feature/tab-depth` deleted both sides by the merge · every change lands through a PR ·
verified ON MAIN at `1100a01`: **unit suite 2,543 / 0** (emulator UP, 0 `127.0.0.1:9099` hits,
0 skipped), **SwiftLint 0 / 719**, device build green · **app target 24.76% (11,189/45,196)**,
identical to the branch figure because the merged tree IS the branch tree ·
`SearchRowDepthJourneyUITests` 1 / 0 and `TabReselectionJourneyUITests` 3 / 0 (carried from the
branch; the tree is unchanged) · **E's phone runs `main` @ `1100a01`** (binary 19:50, `App
installed`, `Launched`, no provisioning trouble) · sim `9181EBF9…` ERASED after both of the
day's UI runs and is signed out · `firestore.rules` untouched · the emulator was left running ·
every `.xcresult` deleted after its figures were read.

**Shipped and CLOSED this session — F-TabDepth, blocks 1 + 2 (PR #35 → `1100a01`):**

- **E's asks:** (06:20, with a screenshot) *"remove the 'search tasks' search bar from a full
  view task screen"*; (~07:00) a re-tap on the selected tab must return to that tab's top-level
  page, and Today → Nudges had *"no way to get back"*. E's four answers: scroll to top at the
  top level; Nudges gets a Back control; sheets untouched; one arc, pop-to-root first.
- **Block 1 (`639cf24`):** the bar routes a repeat tap through `AppTabBarPresentation.tapOutcome`
  into `TabNavigationCoordinator`; each of the six roots pops its own pushes or scrolls to its
  anchor (`.tabRoot(_:isAtRoot:onPopToRoot:)`), because the simulator probe showed a
  `NavigationPath` reset pops neither flag nor closure pushes; Nudges keeps its bar with Task
  detail's Back chevron. Design record: `handoff/SESSION-OPENER-tab-depth-design.md`.
- **Block 2 (`c4fba78`):** `AppSearchScope.scope(for:isAtRoot:)` (`.none` below the top-level
  page, `isAtRoot` with NO default); `RootView.searchScope` masks the tab's scope by the depth
  the roots report; `RootBottomOverlay` animates the row on the house spring keyed on the scope.
  Built on the same branch because E deferred block 1's checks to block 2's sitting.
- **Evidence:** tests first, watched red (block 2 three ways — compile, the call-site guard on
  its own assertions with the rule in and the root still ignoring it, and the UI journey against
  that same build); red-checked one at a time after each commit (block 1: 1/1, 1/1, restore
  14/0; block 2: 2/2, 1/1, restore 13/0); **E's device verdict in words: *"All 4 checks were
  successful"***, with E's two screenshots filed at `screenshots/tab-depth/` (00 the Nudges
  Back chevron, 01 a task detail with only the disc beside the bar) and README rows.

## A · Decisions only E can make — minutes each

- [ ] **Keep the row's spring on a tab SWITCH?** Block 2's one judgment call: the row now fades
      in/out with the house spring when the tab changes, not only when a detail is pushed. E's
      four checks passed on the build that has it and E raised nothing; this stays listed only
      because it was never one of the checks. One line in `RootBottomOverlay.swift` to revert
      if it ever reads as lag over a hard-cut page. (carried, now low)
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order (nothing is in flight; ask E)

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
  profile is roughly valid to **2026-09-15**. Neither of today's later device builds (12:06,
  19:50) needed a provisioning update. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Stacking a block on an unverified block is fine when E asks for it, and the PR should say
  so.** E deferred block 1's checks; block 2 went on the same branch, the PR body grew to cover
  both, and E verified all four in one sitting. What made it safe: separate commits per block
  (a revert stays one commit), and the merge waited for the verdict. (NEW)
- **A "rule right, wiring wrong" red is worth staging on purpose.** With the pure rule in and the
  root deliberately still ignoring the depth, the call-site guard AND the UI journey both went
  red on their own assertions — proof that each catches exactly the defect this repo ships most
  (a correct helper nothing feeds), not merely a missing symbol. (carried from the twelfth)
- **Derive, then `onChange` the derived value.** One `.onChange(of: searchScope)` over a computed
  property covers the tab switch, the push and the pop. (carried)
- **`xcrun xcresulttool export attachments --path <bundle> --output-path <dir>`** pulls a
  journey's screenshots out of the result bundle. (carried)
- **A locked phone refuses the LAUNCH and not the install**; the same phone launched cleanly at
  19:50 once unlocked. (carried, confirmed twice today)
- **`grep -c 'Test Case.*failed'` counts test NAMES containing "failed"** (eight of them exist);
  read the `Executed N tests, with M failures` line, never the grep. (NEW, caught twice today)
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
- **The live opener is `START-HERE-post-tab-depth.md`** — `START-HERE-tab-depth-verdict.md`
  consumed and archived in the same move. Exactly one is live. (updated)
- **A `NavigationPath` is blind to closure-link and flag pushes, and a path reset pops neither**
  — the design record has the table. (carried)
- **The harness's `openTab` returns early on a selected slot**; the late "Save Password?" sheet
  swallows swipes as well as taps — wait for HITTABLE. (carried)
- **A zero-height anchor view inside a padded stack costs its spacing** — put the `id` on the
  padded root. (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. `screenshots/tab-depth/`
  has one: E's own screenshots ARE the device half of the verdict. (carried, applied)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
