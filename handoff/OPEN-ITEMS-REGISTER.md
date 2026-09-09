# Open items register — 2026-09-09 (sixteenth edition; F-FocusCard-1 SHIPPED and CLOSED on E's device verdict, the nav bar's scroll drop RETIRED)

*This edition records a block that shipped and then was redesigned four times on E's device in the
same session. **F-FocusCard-1 is CLOSED** — E: *"That all works very nicely."* Along the way E made
a second, separate change to the **nav tab bar** (`F-TabBar-NoScrollDrop`), which was not part of
the arc and which fixed one of the card's own defects for free. The fifteenth edition (`8605e20`)
is in git history; this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the fifteen earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `89ee187`** (PR #43, seven commits) · **no branch in flight**;
`feature/focus-card-collapse` deleted both sides by the merge · every change lands through a PR ·
verified ON MAIN: **unit suite 2,585 / 0** (emulator UP, 0 `127.0.0.1:9099` hits, 0 skipped),
**SwiftLint 0 / 725**, sim + device builds `** BUILD SUCCEEDED **` · **app target
26.02% (11,802/45,364)**, up from 24.76% (11,191/45,205) at `e9fa9df` — **comparable**: the
denominator moved because the tree grew (+159 executable lines), the measurement extent is
unchanged, and the numerator grew +611, so coverage grew far faster than the code ·
`firestore.rules` untouched, nothing for E to republish · the emulator is running · every
`.xcresult` deleted after its figures were read.

**E's phone is ON MAIN at `89ee187`** — reinstalled and launched clean at close-out.

**Shipped and CLOSED this session:**

- **`F-FocusCard-1` — the collapsible focus sprint card** (PR #43). Block 1 of five. Built
  test-first against the design record, then **redesigned four times on E's device**. What
  shipped bears only partial resemblance to what the record specified, and the record's own
  "do not re-litigate" line is why each reversal is recorded here rather than silently absorbed:

  | the record said | E changed it to, on device |
  |---|---|
  | full-bleed to both screen edges | **inset 16pt** (361pt) — via 44pt, which E also rejected |
  | flush onto the tab bar | still flush, but only after the BAR stopped moving (below) |
  | chevron a real button in both states | **collapsed: gone.** expanded: kept |
  | grabber present in both states | kept, but **overlaid in the top padding** — as a stack child it cost 13pt in BOTH states |
  | long-press opens the detail sheet | **single TAP opens it, in both states.** Long-press retired |
  | tap toggles collapse | collapse is the **swipe and grabber only** |
  | — | **bottom border removed** when collapsed |
  | 73pt tall | **60pt**, the tab bar's own height |

- **`F-TabBar-NoScrollDrop` — the nav bar no longer moves vertically on scroll.** E's separate
  request, raised mid-block because E suspected the two were linked. They were. The bar never
  changed SIZE (`chipHeight` 44, `cardHeight` 60, band `rowHeight` 68 are all constant in both
  states); the only vertical difference was a conditional bottom padding lifting the card 8pt at
  rest and 4pt scrolled. Now unconditional, and `floatingLift` is **deleted** rather than left
  dead. `rowHeight` is unchanged at 68, so **no clearance anywhere in the app moved**.
  **KEPT deliberately:** the width morph (inset 4 → 8), the pill-to-chip contraction, the label
  hiding. E removed the height difference only.

- **The `next` checkpoint marker's rendering bug.** See section E — it is the most transferable
  thing this session produced.

**Evidence:** `screenshots/focus-card-collapse/` with a README, because four of the five changes
were settled by E LOOKING rather than by an assertion.

## A · Decisions only E can make — minutes each

- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** They were square
      because the card was full-bleed and flush, so the corners died into the screen edges. It is
      now inset 16pt with no bottom border, so they land on the bar's face. It reads fine in E's
      final verdict, so this is a "look again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order

**0. THE FOCUS CARD ARC — block 1 CLOSED, blocks 2-5 NOT STARTED. This is the live work.**
   The design record is **`handoff/SESSION-OPENER-focus-card-design.md`** — permanent, never
   archive it. **Read its "settled specification" with the table in this register's State section
   beside it**: block 1's half of that record has been overtaken by E's device passes, and a
   session that follows it literally will rebuild things E has already rejected. Blocks 2-5 are
   untouched by those reversals.
   - **`F-FocusCard-2`** — the provisional record + the completed-unconfirmed card. **This is the
     one that matters most**, because **block 1 alone has sticky collapse with no reset** — nothing
     clears it until block 2's Confirm. E has been told and accepted it.
   - `F-FocusCard-3` the notification-style stack · `-4` the celebration · `-5` close-out.
   - The live opener is `handoff/START-HERE-focus-card-block2.md`.

**0b. E's SECOND change — still not described.** Ask once the arc reaches a natural stopping point.
   (carried; E's *first* change was the focus card arc, now half-built.)

1. **Small defects found while building block 1, none blocking, all in the card:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs.
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** The container is never
     made an accessibility element and holds several operable Buttons. Now that a TAP opens the
     detail view this matters less than when it was a long-press, but it wants an Accessibility
     Inspector pass — this bar is the app's only door to `FocusSprintDetailView`.
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split files
     (`QuickCaptureComponents`, `CaptureRowDetailViews`).

2. **Two more dead design tokens, and two dead helpers.** `BarSurface` (a colorset, defined,
   unit-tested, used by nothing — the second after `softInkAsset`), and
   `AppTabBarPresentation.slotWidth` / `restingSlotWidth`, which have ZERO production call sites
   and **disagree about their input**: `slotWidth` takes CONTENT width, `restingSlotWidth` takes
   SCREEN width. A caller copying the test's shape gets a card 20pt too wide. (NEW)

3. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
4. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
5. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; roughly valid to **2026-09-15**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **`Color.primary` is a HIERARCHICAL style and gets VIBRANCY over a `Material`; `Color(.systemBackground)`
  is a concrete `UIColor` and does not.** This is the session's most transferable finding. The
  sprint ring's "next" marker rendered as a grey disc in a heavy black ring in dark mode:
  `.next` was the ONLY hierarchical value in `FocusCheckpointDotState`, and the only one that
  rendered wrong — `.reached` and `.pending` are concrete and were always fine. **That asymmetry
  inside one `ForEach` is the diagnostic.** The ring's premise ("a page-colour ring") was false
  twice: the marker sits on a material, which is a blur no colour can match, and
  `systemBackground` (#FFF/#000) was never this app's page colour — `PageBackground` is
  #F2F3F7/#15171C. Same family as the journal pad's `.secondary`-at-half-alpha trap, different
  branch. **Grep for a hierarchical style filling a large solid shape over a material.** (NEW)
- **Widget extensions have their OWN `Assets.xcassets`.** Tokens are consumed by NAME and are not
  shared with the app catalog — `LabelPrimary` exists in the app's and not the widget's. Check
  before reaching for an app token in widget code. Related: `FocusCheckpointDotState`'s palette is
  **deliberately duplicated** into `FocusTimerWidget/FocusActivityComponents.swift`, so any fix to
  the enum must be mirrored by hand or the Lock Screen keeps the bug. (NEW)
- **A source-reading call-site test MUST strip comment lines before any `XCTAssertFalse`.**
  These files document the anti-patterns they ban, so `FocusTimerBar.swift`'s own comment warning
  against `.gesture(DragGesture(...))` failed the guard banning it — on the first GREEN run, after
  the implementation was already correct. The fix is an `appCode()` helper beside `appSource()`.
  (NEW)
- **A metrics test cannot always guard what its name claims.** `rowHeight - cardHeight ==
  restingLift` held BEFORE the nav bar's drop was removed as well as after, because the band was
  sized off `max(restingLift, floatingLift)` and `restingLift` was already the larger. Only the
  call-site test went red. **Ask what the assertion reads on the BROKEN build** — and when the
  answer is "the same", rename the test and say so in its doc. Same lesson as
  `testEverySprintStartsExpanded`, which claimed "every sprint" while its setup could only see a
  fresh install. (NEW)
- **`UIHostingController.sizeThatFits` measures a real SwiftUI view's height in a unit test.**
  The test target hosts the app, so every dependency is present and no swiftc probe is needed. It
  is the only assertion that catches a touch target leaking into layout — which is exactly how the
  grabber cost 13pt in both card states. CLAUDE.md's rule is that a screenshot folder is earned by
  what a test CANNOT assert; this can be asserted, so it is. (NEW)
- **The tab bar's six slots are equal only while SCROLLED.** At rest the selected slot is
  `fixedSize(horizontal: true)` capped at `maximumRestingPillWidth`, so the slots are unequal and
  the outer icon centres move with the SELECTION (~34pt with a middle tab selected, ~59pt with
  Today). Any "align to the tab icons" rule holds in one state only. (NEW)
- **There is no `PreferenceKey` or width-measurement helper anywhere in the app target**, and
  `AppScrollOffsetObserver`'s comments explicitly REJECT that approach. The house idiom is an
  inline `GeometryReader` at the point of use with an explicit `.frame` outside it. (NEW)
- **The nav bar's scroll state is STICKY, not transient.** `TabBarScrollActivity` is hysteretic —
  true past 24pt, back only at <= 8pt — so a defect that appears "only while scrolled" is on screen
  continuously, not for the duration of a gesture. Do not dismiss one as momentary. (NEW)

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
- **The live opener is `START-HERE-focus-card-block2.md`.** `START-HERE-focus-card-block1.md` was consumed and archived in the same move that wrote it. `START-HERE-post-pill-retap.md` was
  consumed and archived into `handoff/archive/` in the same move that wrote it (PR #42). Exactly
  one is live — check, because two would mean one is a trap. (updated)
- **A plan written only to `~/.claude/plans/` does not survive a session boundary.** E asked for
  the focus card arc to be built in a fresh terminal; the plan lived outside the repo, so the
  design had to be written INTO `handoff/` before the session could end. Any design a future
  session must act on belongs in the repo, not the plan file. (NEW)
- **A `NavigationPath` is blind to closure-link and flag pushes.** (carried)
- **The harness's `openTab` returns early on a selected slot.** (carried)
- **A zero-height anchor view inside a padded stack costs its spacing.** (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
