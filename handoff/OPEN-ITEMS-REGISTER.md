# Open items register — 2026-09-08 night (fifteenth edition; B-2 CLOSED, the search-row spring CLOSED on E's word, E's two edits pending)

*This edition records two closures the fourteenth could not: **B-2 shipped** as
`F-HomeTasksLastKnown` (PR #39, then PR #40 marking the block complete), and the **A-list
search-row spring decision was settled by E — "Keep it"** — which no commit records, which is
exactly why it is written here. E has since asked for **two changes/edits of their own**; they
have not been described yet, so they are listed as pending rather than specified. The fourteenth
edition (`de3b3d0`) is in git history; this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the fourteen earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `e9fa9df`** (PR #40, the block's completion record; the code is `8b5f740` via PR #39)
· **no branch in flight**; `fix/home-alltasks-keep-last-known` and
`chore/f-hometaskslastknown-completed` both deleted both sides by their merges · every change
lands through a PR · verified ON MAIN: **unit suite 2,547 / 0** (emulator UP, 0 `127.0.0.1:9099`
hits, 0 skipped), **SwiftLint 0 / 720**, sim build `** BUILD SUCCEEDED **` · **app target
24.76% (11,191/45,205)** · `firestore.rules` untouched · the emulator is running · every
`.xcresult` deleted after its figures were read.

**E's phone is BEHIND main — it runs `a6b8021`, main is `e9fa9df`.** This is deliberate, not an
oversight: the merge touched Swift (`HomeService.swift`), so the reinstall recipe applies, but
E's two pending edits will almost certainly touch Swift too and one device build serves both.
**Whoever closes this session must either run the recipe or carry this line forward.**

**Shipped and CLOSED this session — F-HomeTasksLastKnown (PR #39 → `8b5f740`, PR #40 → `e9fa9df`):**

- **Register item B-2**, carried since the arrival-card arc and deferred out of PR #32 on
  purpose. Taken up on E's word: *"First do B-2."*
- **Defect:** `HomeService.load()` read `allTasks = (try? await allTasksResult) ?? []`, so a
  failed `fetchAllTasks()` published the positive claim **"there are no tasks"** rather than
  "don't know". `lifeAreas` and `openTasks` never had this problem — they throw into the `catch`,
  which leaves both holding last-known values. Only `allTasks` swallowed its error.
- **Why it reached the arrival card:** Home refreshes the card deliberately AFTER the load, and
  `ArrivalSurface.refreshed` re-checks the card it is holding against those tasks. That rule
  cannot tell "the work here closed" from "the fetch failed" — and should not have to — so the
  fix belonged upstream in the service, not in `ArrivalSurface`.
- **Blast radius was wider than the card, and was never the stated symptom:** the Momentum ring,
  `streak`/`bestStreak`, `trailingWeekClosureFlags`, `MomentumWeekCharts.closedPerDay`,
  `TaskCompletionStamp.completedTasks`, the week-review row and `MomentumTaskContext.build` all
  read `homeService.allTasks`. **A failed fetch was zeroing E's streak display.**
- **Fix:** one line, the inbox precedent (`CaptureInboxService.refresh()`) —
  `if let fetchedAllTasks = try? await allTasksResult { allTasks = fetchedAllTasks }`. Success
  still overwrites wholesale, so nothing goes stale while the network works. `HomeService` is a
  `@StateObject` on `HomeView`, inside the signed-in tree, so a last-known set cannot outlive an
  account switch.
- **Evidence:** red first (14 tests / 1 failure, the assertion `("[]") is not equal to
  ("[…Closed…]")`); scoped green 38 / 0; committed, THEN red-checked — **predicted 1 / actual 1**,
  exactly the named test, other 13 green; restore proven 14 / 0.
- **Merged WITHOUT waiting for a device verdict, and the report said so.** There is no verdict to
  be had — Firestore's default persistence serves offline reads from cache, so a failed
  `fetchAllTasks()` is not practically inducible on the phone; the unit test IS the evidence.
  This departs from #35 and #37, which both waited. E has not objected; a one-line revert exists.

## A · Decisions only E can make — minutes each

- [x] **CLOSED 2026-09-08 — keep the search row's spring on a tab SWITCH.** E's word, asked
      directly: **"Keep it."** Block 2 of the tab depth arc fades the row with the house spring
      when the tab changes, not only when a detail is pushed; it shipped that way and E's device
      checks passed on it. **No commit records this decision — this line is the record.** The
      revert (one line in `RootBottomOverlay.swift`) is not being taken.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

**0. E's two changes/edits — NOT YET DESCRIBED, and they come first.** E asked to be asked about
   them once B-2 landed ("*THEN ASK ME FOR my 2 changes/edits that Ethan has come up with*").
   The question has been put; the answer is pending. **Do not start anything below until E has
   described these and they are done.**

1. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   A fix that ARRIVES but lands outside every radius still clears the card (the app ignores
   `horizontalAccuracy`; the probe puts it at ~3% of pulls at 40 m jitter with Home alone, 27%
   at 65 m). Widening `LocationFixProviding` to carry accuracy touches every caller, which is why
   it was not bundled into the coin-flip fix. **Note B-2 has now removed one of the two ways the
   card could vanish** — if E still sees drops, this is the remaining suspect. (carried)
2. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
3. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
4. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; roughly valid to **2026-09-15**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A single-load test cannot catch a "keeps last-known" bug, and reads exactly like one that
  can.** `testLoad_scoreboardFetchFailure_stillLoadsTheScreen` fails the fetch on a FIRST load,
  where the property is `[]` before AND after — so it passed both before and after B-2's fix and
  pinned nothing. The discriminating test needs TWO loads: land a value, flip the fake to
  `.failure`, load again, assert the value survived. This is the `geometry-journey-vacuity`
  lesson in a new costume — **ask what the assertion would read on the BROKEN build**. (NEW)
- **Swallowing an error into an empty collection turns "don't know" into a positive claim**, and
  every consumer downstream believes it. `(try? …) ?? []` is the shape to grep for; the honest
  form keeps the last-known value. Worth a sweep for other instances. (NEW)
- **A programmatic scroll is invisible to a gesture-driven model.** (carried)
- **`RootView.swift` is at 399 of 400 lines.** New members go in an extension file. (carried)
- **Stacking a block on an unverified block is fine when E asks for it.** (carried)
- **A "rule right, wiring wrong" red is worth staging on purpose.** (carried)
- **Derive, then `onChange` the derived value.** (carried)
- **`xcrun xcresulttool export attachments`** pulls a journey's screenshots; **`ffmpeg -vf
  "fps=2,scale=360:-1"`** turns E's GIF into frames (no PIL or ImageMagick here). (carried)
- **A locked phone refuses the LAUNCH and not the install.** (carried)
- **`grep -c 'Test Case.*failed'` counts test NAMES containing "failed"** (eight exist); read
  the `Executed N tests, with M failures` line. **A trailing `grep -c` that finds nothing exits
  1 and makes a green run look failed** — read the `exit=` you echoed, not the task status. (updated)
- **Ask before designing when E invites it; read the user's REAL data before choosing between
  hypotheses.** (carried)
- **The resolver's tie-break was designed for different radii**; take the ordered LIST. (carried)
- **The fence ledger shows all three home fences flapping departure → arrival within 4 s.** (carried)
- **A swiftc probe of the pure files + the user's real coordinates settles a geometry question
  in a minute.** (carried)
- **A `CGContext` bitmap is TOP-DOWN**; **red-check regressions ONE AT A TIME**; **iPhone
  Mirroring cannot be started from the terminal.** (carried)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** — never scope a red-check down for speed. (carried)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is still `START-HERE-post-pill-retap.md`** — deliberately NOT rotated, because
  the session is still open and a mid-session rotation would leave a dying session with no live
  opener. Its "Where things stand" is now one arc stale (main is `e9fa9df`, not `a6b8021`); it
  still points at THIS register, which is current. Rotate it at close-out. (updated)
- **A `NavigationPath` is blind to closure-link and flag pushes.** (carried)
- **The harness's `openTab` returns early on a selected slot.** (carried)
- **A zero-height anchor view inside a padded stack costs its spacing.** (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
