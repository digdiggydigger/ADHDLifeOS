# Open items register — 2026-09-08, session close-out (tenth edition; F-ArrivalCardRefresh MERGED on E's device verdict)

*This edition closes the session that took E's authorised item — the "You're at home" card
vanishing on drag-reload — from "investigate first, then ask" to merged. E's one answer
(**"Still open"**, 06:12) and four screenshots settled which case; the investigation found a
THIRD mechanism the opener had not listed and it was the main one; E's verdict on the phone
(**"the card does stay across repeated pulls"**) landed PR #32. The ninth edition, minutes
earlier, is in git history (`e225564`); this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the nine earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `99d9211`** (PR #32, merge commit) · local = remote, tree clean, **only `main`
exists** (the feature branch was deleted by the merge; `git fetch --prune` cleared the ref) ·
every change lands through a PR · re-verified ON MAIN: **unit suite 2,526 / 0** (emulator UP,
0 `127.0.0.1:9099` hits, 3 skips as designed), **SwiftLint 0 / 712**, sim + device builds green
(on the branch at the same Swift) · **app target 24.82% (11,162/44,965)** — denominator +25 (the
new rules), numerator +29 over `76a4f47`'s 24.77% (11,133/44,940); both measured the whole
target, so the ratios are comparable and the change is real · **E's phone runs the `4d8de11`
build** (installed and relaunched 06:38); the merge touched no further Swift, so it is
functionally main — the NEXT Swift merge needs a reinstall · `firestore.rules` untouched · the
emulator was left running · both `TestResults.xcresult` bundles this session wrote were deleted
after their figures were read (E's standing word) · sim `9181EBF9…` is SIGNED OUT.

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

- [x] **Does the card stay now?** — **E: *"the card does stay across repeated pulls."*** PR #32
      merged on that verdict. RESOLVED the same morning it was raised.
- [ ] **Keep or delete the two test places at home?** `Action Test 01/09/2026` and `routines
      test` are left over from the place-actions and routines arcs. The code now handles
      overlapping places properly (a public-launch user will have them legitimately), so this
      is hygiene, not a fix. Deleting them from the Places screen is E's call. **NEW.**
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

1. **Remove the Tasks tab's bottom "Search tasks" row from a pushed task detail — NEXT, opener written** — E, 06:20:
   *"we need to remove the 'search tasks' search bar from a full view task screen such as the
   one shown in one of the screenshots."* `screenshots/arrival-card-refresh/02-` shows it: the
   bottom-search arc's row is a `safeAreaInset` on the Tasks tab and stays on screen with a
   task's detail pushed on the `NavigationStack`. Read at this close-out: the row is mounted
   ONCE in `RootBottomOverlay`, its scope derived in `RootView` from `selectedTab` alone, so the
   root never learns the tab has left its root screen — the fix is a depth SIGNAL from
   `TaskListView` (`inspectingTask != nil`) and a pure `AppSearchScope` rule, not a layout
   change. Untouched this session — E's rule is one block, then review. **E's ask; opener
   `START-HERE-tasks-search-row.md`.**
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

- **A two-hypothesis opener can miss the third, and the third can be the bug.** The opener listed
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
- **The live opener is `START-HERE-tasks-search-row.md`** (E's search-row ask, B1, with the
  seam read first-hand: the row is root-mounted and its scope follows `selectedTab` alone).
  `START-HERE-home-arrival-card.md` was consumed and archived in the same commit that wrote the
  successor, at this close-out. Exactly one is live. (updated)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
