# Open items register — 2026-09-08, mid-morning (eleventh edition; F-TabDepth-1-PopToRoot built, on E's phone, PR #35 awaiting E's verdict)

*This edition covers the same session's SECOND arc. After F-ArrivalCardRefresh merged
(`99d9211`), E raised two navigation asks — the bottom search row over a pushed task detail
(06:20) and "tapping the tab you are already on must return to that tab's top-level page"
(~07:00, "ask me questions") — answered four questions with the recommended option each, and
block 1 went from a simulator probe to a build on E's phone. The tenth edition (`74a55e4`) is in
git history; this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the ten earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `38b309c`** (PR #34, docs) · **branch `feature/tab-depth`, pushed, PR #35 OPEN** —
code commit `639cf24` + two journey-hardening commits · every change lands through a PR ·
verified ON THE BRANCH: **unit suite 2,540 / 0** (emulator UP, 0 `127.0.0.1:9099` hits),
**SwiftLint 0 / 717**, sim + device builds green, **`TabReselectionJourneyUITests` 3 / 0 as one
class run** (452 s) · **app target 24.76% (11,188/45,189)** — denominator +224 over `99d9211`'s
24.82% (11,162/44,965), all of it view code the journey reaches; the ratio moved because the
tree grew, and the numerator moved +26 · **E's phone runs the tab-depth BRANCH build** (code
`639cf24`, binary 09:00, installed and relaunched **09:22** after E freed space — the 09:00
install had failed, `No space left on device`) · sim `9181EBF9…` ERASED after every UI run (ten
runs, ten erases) and is signed out · `firestore.rules` untouched · the emulator was left
running · every `.xcresult` deleted after its figures were read.

**Built this session, IN PR — F-TabDepth-1-PopToRoot (PR #35, `639cf24` + `96aa629` + the
close-out commit):**

- **E's asks and answers:** re-tap at the top level → **scroll to top**; Nudges → **a visible
  Back control** (Task detail's chevron); sheets → **untouched**; the search-row ask → **same
  arc, block 2, after this**.
- **Cause:** the bar's button only set the selection (a re-tap was a no-op by construction);
  no tab held a path the root could reset; Nudges hid the navigation bar and drew nothing.
- **The probe (iOS 26.5 sim, photographed; design record has the table):** closure-link and
  flag pushes are invisible to `NavigationPath` and survive a path reset; clearing a flag pops;
  a value push counts and a reset pops it; a closure push nested above either collapses with
  it. Hence: the root cannot pop a tab from outside — each root pops itself; Tools' closure
  links became one flag push.
- **What shipped:** `TabNavigation.swift` (the rule, `TabNavigationCoordinator`, `.tabRoot`,
  `.tabRootScrollAnchor()`), `AppTabBarPresentation.tapOutcome`, `AppTabBar.onReselect`,
  `RootView` owns/injects the coordinator, six roots wired (Today's list in
  `HomeView+TabRoot.swift`; Today and Areas gain a path), `NudgesView`'s Back chevron.
- **Evidence:** tests first, watched red; +8 unit, +6 call-site, +3 journey; red-checked one at
  a time (1/1, 1/1, restore 14/0); the journey's ten runs found five harness/journey defects and
  zero app defects (TODO block has the list). Design record:
  `handoff/SESSION-OPENER-tab-depth-design.md`.

**Shipped and CLOSED this session — F-ArrivalCardRefresh (PR #32 → `99d9211`, one code commit `4d8de11`):**

- **What E saw:** card *"YOU'RE AT HOME 🏠 · test quick"* at 06:14, one drag-reload, no card,
  `test quick` still open (`screenshots/arrival-card-refresh/00–03`, README rows).
- **Cause (live Firestore via the Firebase MCP + a swiftc probe over the real geometry files):**
  E's home holds **three saved places at the 100 m floor radius** — `Home`, `Action Test
  01/09/2026` (centre **1.2 m** from Home's), `routines test` (34.5 m) — and only Home has
  at-place tasks. The resolver picked ONE by smallest radius then nearest centre: a coin flip
  per fix. **Home won 50% at 10 m jitter, 40% at 20 m, 31% at 40 m** (100 / 100 / 96% with Home
  alone). Every fix succeeded; the pull re-tossed the coin and overwrote the card. A fix that
  never arrived (8 s timeout, a request already pending) overwrote it with nil too.
- **Fix, two pure rules, no visual change:** (1) "here" is EVERY place the fix fell inside,
  tightest first — `PlaceResolution.places(containing:in:)`, `ArrivalSurface.make(
  currentPlaces:)`; (2) a refresh replaces the card only when a fix positively says otherwise —
  `CurrentPlaceFix` (`.off` / `.noFix` / `.inside`) and `ArrivalSurface.refreshed(previous:fix:
  tasks:)`; the fix provider is injectable.
- **Evidence:** tests first, watched red (the missing members by name); +3 / +4 / 15-new tests;
  red-checked ONE regression at a time after the commit — predicted 2 / actual 2, predicted 1 /
  actual 1 (three assertions); restore proven 39 / 0. **E's device verdict, in words: *"the
  card does stay across repeated pulls."*** Design record:
  `handoff/SESSION-OPENER-arrival-card-refresh-design.md`; evidence
  `screenshots/arrival-card-refresh/` (00–03 + README; no after-shot, the verdict is the record).

## A · Decisions only E can make — minutes each

- [ ] **Does the tab re-tap behave on the phone?** Today → Nudges → tap Today; the Nudges Back
      chevron; scroll any tab down and re-tap it. "Yes" → merge PR #35, reinstall from main,
      then block 2. **NEW, blocking the merge.**
- [x] **Does the card stay now?** — **E: *"the card does stay across repeated pulls."*** PR #32
      merged on that verdict. RESOLVED. (carried)
- [x] **Keep or delete the two test places at home?** — **E: *"leave them, I'll deal with
      those two test places."*** `Action Test 01/09/2026` and `routines test` stay; E handles
      them from the Places screen. **Claude Code must not delete them** — and the code no longer
      needs them gone. RESOLVED.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

1. **F-TabDepth-2-SearchRowAtRoot — the bottom "Search tasks" row hides while a task detail is
   pushed — NEXT, after PR #35 merges.** Block 1 built the seam it needs: `RootView` derives
   `AppSearchScope` from `selectedTab` alone; with `tabNavigation.isAtRoot(tab)` it becomes
   `scope(for:isAtRoot:)` and the row leaves with the overlay's spring. Pure rule in
   `AppSearchScopeTests`, a call-site test that `RootView` reads the depth, and E's screenshot
   `screenshots/arrival-card-refresh/02-` as the before. — E, 06:20:
   *"we need to remove the 'search tasks' search bar from a full view task screen such as the
   one shown in one of the screenshots."* `screenshots/arrival-card-refresh/02-` shows it: the
   bottom-search arc's row is a `safeAreaInset` on the Tasks tab and stays on screen with a
   task's detail pushed on the `NavigationStack`. The depth signal now exists (block 1). **E's
   ask; opener `START-HERE-tab-depth-arc.md`.**
2. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   A fix that ARRIVES but lands outside every radius still clears the card (the app ignores
   `horizontalAccuracy`; the probe puts it at ~3% of pulls at 40 m jitter with Home alone, 27%
   at 65 m). Widening `LocationFixProviding` to carry accuracy touches every caller, which is why
   it was not bundled into the coin-flip fix. **NEW, deferred on purpose.**
3. **`HomeService.load()` empties `allTasks` on a failed fetch**, which would drop the card
   through the re-check; the inbox precedent keeps last-known on failure. One line + one test.
   **NEW, small.**
4. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
5. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with this morning's device build
  (06:37), so the profile is roughly valid to **2026-09-15**. (updated)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A two-hypothesis opener can miss the third, and the third can be the bug.** (carried)
- **Ask before designing when E invites it; four questions settled the arc in one round.** The opener listed
  "fix fails" and "task closed"; the live data showed three co-located places and a coin-flip
  resolver. Read the user's REAL data (the Firebase MCP reads live Firestore) before choosing
  between the hypotheses you already have. (NEW)
- **The resolver's tie-break was designed for different radii.** "Office inside town centre"
  ranks by radius; equal-radius places at the floor rank by nearest centre, which is jitter.
  Any future "which place" caller should take the ordered LIST, not the head. (NEW)
- **The fence ledger shows all three home fences flapping departure → arrival within 4 s** at
  23:50 BST on 09-07 — boundary jitter at home is real on E's device, not a theory. (NEW)
- **A swiftc probe of the pure files + the user's real coordinates settles a geometry question
  in a minute** — second use of the technique (tab bar first). `scratchpad/probe/main.swift`
  this session; not in the tree. (NEW)
- **A `CGContext` bitmap is TOP-DOWN**; **red-check regressions ONE AT A TIME**; **iPhone
  Mirroring cannot be started from the terminal** — E's own screenshots, filed with README
  rows, worked again as the evidence route. (carried, all three confirmed again)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** (2.457 s on the first failure this session,
  then 0.006 s) — never scope a red-check down for speed. (carried, confirmed)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is `START-HERE-tab-depth-arc.md`** — `START-HERE-tasks-search-row.md`
  RENAMED and rewritten, never consumed (the same move as the eighth edition's), because the
  search-row block became block 2 of an arc whose block 1 is now in PR. Exactly one is live.
  (updated)
- **A `NavigationPath` is blind to closure-link and flag pushes, and a path reset pops neither**
  (probed 2026-09-08; the design record has the table). Any future "pop from outside" idea
  starts from that table, not from theory. (NEW)
- **The harness's `openTab` returns early on a selected slot** — right for every journey but a
  re-tap one. And **the late "Save Password?" sheet swallows swipes as well as taps**; a journey
  that depends on a tap or a swipe after a fresh sign-in must wait for HITTABLE, not for
  EXISTS (`settleSystemSurfaces` in the re-tap journey is the pattern). (NEW)
- **A zero-height anchor view inside a padded stack costs its spacing** — 16 pt of dead space at
  the top of every tab, caught only because the journey measured a frame. Put an `id` on the
  padded root instead. (NEW)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
