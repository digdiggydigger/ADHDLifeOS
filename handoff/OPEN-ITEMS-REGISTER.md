# Open items register — 2026-09-08, mid-morning (ninth edition; F-ArrivalCardRefresh built, in PR #32, awaiting E's device verdict)

*This edition covers the session that took E's authorised item — the "You're at home" card
vanishing on drag-reload — from "investigate first, then ask" to a fix on E's phone. E's one
answer (**"Still open"**, 06:12) and four screenshots settled which case; the investigation found
a THIRD mechanism the opener had not listed and it was the main one. The eighth edition's tab-bar
narrative is in git history (`2672be6`); this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the eight earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `e8d1605`** (docs-only since the code at `76a4f47`) · **branch
`feature/arrival-card-refresh` @ `4d8de11` + this docs commit, pushed, PR #32 OPEN** ·
every change lands through a PR · verified ON THE BRANCH: **unit suite 2,526 / 0** (emulator
UP, 0 `127.0.0.1:9099` hits, 3 skips as designed), **SwiftLint 0 / 712**, sim build green,
device build green · **app target 24.82% (11,162/44,965)** — denominator +25 (the new rules),
numerator +29 over `76a4f47`'s 24.77% (11,133/44,940); both measured the whole target, so the
ratios are comparable · **E's phone is on the BRANCH at `4d8de11`**, installed and relaunched
06:38 (binary mtime 06:37) — NOT on main until PR #32 merges · `firestore.rules` untouched · the
emulator was left running · the one `TestResults.xcresult` this session wrote was deleted after
its figures were read (E's standing word) · sim `9181EBF9…` is SIGNED OUT.

**Built this session — F-ArrivalCardRefresh (PR #32, one code commit `4d8de11`):**

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
  actual 1 (three assertions); restore proven 39 / 0. Design record:
  `handoff/SESSION-OPENER-arrival-card-refresh-design.md`.

## A · Decisions only E can make — minutes each

- [ ] **Does the card stay now?** Pull Today repeatedly on the phone (it is on the branch build,
      relaunched 06:38; an open task At Place = Home is needed — `test quick` is one). "Yes" →
      merge PR #32, file the after-shot as `04-`, close out. "Still goes sometimes" → the
      deferred accuracy lever in B is next, and the register says so. **NEW, blocking the merge.**
- [ ] **Keep or delete the two test places at home?** `Action Test 01/09/2026` and `routines
      test` are left over from the place-actions and routines arcs. The code now handles
      overlapping places properly (a public-launch user will have them legitimately), so this
      is hygiene, not a fix. Deleting them from the Places screen is E's call. **NEW.**
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

1. **Remove the Tasks tab's bottom "Search tasks" row from a pushed task detail** — E, 06:20:
   *"we need to remove the 'search tasks' search bar from a full view task screen such as the
   one shown in one of the screenshots."* `screenshots/arrival-card-refresh/02-` shows it: the
   bottom-search arc's row is a `safeAreaInset` on the Tasks tab and stays on screen with a
   task's detail pushed on the `NavigationStack`. Untouched this session — E's rule is one block,
   then review. Start at `TaskListView.swift` and the bottom-search design record. **NEW,
   E's ask.**
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
- **The live opener is STILL `START-HERE-home-arrival-card.md`** — consumed but NOT yet
  archived, because the block it opened is awaiting E's verdict. The close-out that merges
  PR #32 archives it in the same move that writes its successor (CLAUDE.md, "Session handoff").
  Exactly one is live. (updated)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
