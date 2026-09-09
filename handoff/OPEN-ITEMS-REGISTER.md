# Open items register — 2026-09-09 (eighteenth edition; F-FocusCard-3 BUILT and LANDED, awaiting E's verdict)

*Third close-out of the same day. **F-FocusCard-3 is landed but NOT closed** — it merged at
`110701a` and E's phone was reinstalled from main, but E had not given a device verdict when this
session ended. The arc is three-fifths built: blocks 1 and 2 closed, block 3 landed, 4 and 5 open.
The seventeenth edition (`9625d46`) is in git history; this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and to
update, rather than improvising a list in chat. Supersedes the seventeen earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `110701a`** (PR #49) · **no branch in flight**; `feature/focus-card-3` deleted both
sides by its merge · every change lands through a PR · verified: **unit suite 2,637 / 0**
(emulator UP, 0 `127.0.0.1:9099` hits, 0 skipped), **SwiftLint 0 / 734**, sim + device builds
`** BUILD SUCCEEDED **` · **app target 26.56% (12,161/45,782)**, up from 26.37% (12,037/45,646)
at `1f0d93a` — **comparable**: the denominator moved because the tree grew by one file (+136
executable lines), the measurement extent is unchanged, and the numerator grew +124 ·
`firestore.rules` untouched, **nothing for E to republish** · the emulator is running · every
`.xcresult` deleted after its figures were read.

**E's phone is on MAIN at `110701a`**, reinstalled and launched after the merge.

### Landed this session, and what closing it needs

- **`F-FocusCard-3` — the notification-style stack** (PR #49). Block 3 of five, built test-first.
  Newest in front, older ones peeking behind as edges, three layers drawn, one Confirm at a time,
  no "confirm all" — a call-site test guards its absence by enumerating the CLEARING forms,
  because `confirmCompletion` legitimately calls `removeAll { $0.id == record.id }`.

  What shipped: `FocusCompletionCardStack` + a pure `FocusCompletionStackLayout` that owns the
  **draw order** as well as the offsets, a blank `FocusCompletionCardEdge` for the layers behind,
  `reservedTopPadding(forCount:)` for the peeks that `.offset` hangs outside the frame, and the
  `RootBottomOverlay` swap from `.first` to the stack.

  **Verification:** five red-checks, one regression at a time, each predicted before running —
  **all five fired on exactly the predicted tests AND assertion counts**; tree restored and the
  suite re-run green. Evidence: `screenshots/focus-card-stack/`, six images with a README.

  **NOT CLOSED. It closes on E's device verdict** — the live opener
  `handoff/START-HERE-focus-card-block4.md` opens by saying so, and by saying that any change E
  asks for is a FOLLOW-UP TO BLOCK 3 on its own branch, not block 4.

## A · Decisions only E can make — minutes each

- [x] **The completion card's floating geometry — ANSWERED 2026-09-09.** E was shown three options
      and chose **keep it as shipped**: inset 16, radius 24, all four corners, 76pt. It is settled
      now rather than approved-by-sight, and the stack's peek offsets inherit a settled shape.
- [x] **Confirm resetting collapse — ANSWERED 2026-09-09, and it CHANGED SHIPPED BEHAVIOUR.** E was
      shown three candidate rules and chose **reset only if no sprint is running**. Block 2 reset
      it unconditionally, so confirming an OLD card blew open a NEW sprint's card and undid a
      collapse the user had just made by hand. Landed as its own commit with its own red-check,
      and `testConfirmResetsCollapse` now states the premise that keeps it green rather than
      assuming it.
- [ ] **The stack's LIGHT-mode peek is quieter than dark, and E has not looked at it on device.**
      `.regularMaterial` and `pageBackground` are close in value, so in light the peeking edges are
      carried almost entirely by the `StateGo` keyline. Legible, and noticeably quieter than dark.
      Levers in order of bluntness: `opacityStep` (0.15), `peekStep` (8), `scaleStep` (0.05).
      **Do not re-tune unprompted.** (NEW)
- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** (carried) A "look
      again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)

## B · Real work, ready to start — recommended order

**0. THE FOCUS CARD ARC — blocks 1 and 2 CLOSED, block 3 LANDED AWAITING VERDICT, 4–5 NOT
   STARTED.** The design record is **`handoff/SESSION-OPENER-focus-card-design.md`** — permanent,
   never archive it. **Read its "settled specification" with this register beside it**: blocks 1,
   2 and 3 each moved against it, and the live opener carries the table of what actually shipped.
   - **First: get E's verdict on block 3.** Changes are follow-ups to block 3, on a
     `feature/focus-card-3-*` branch, the way `F-PillReTap` followed the tab-depth arc.
   - **`F-FocusCard-4`** — the celebration. **iOS 16 is the floor**, which rules out
     `PhaseAnimator`, `.symbolEffect`, `.keyframeAnimator` and `.sensoryFeedback`. The haptic keys
     on `confirmableCompletionCount`, NOT `completedSprintCount` (bumped on manual stops) and NOT
     `unconfirmedCompletions.count` (changes on confirm-removal, so it would buzz on dismissal).
     Reduce Motion renders the FINAL state. **Evidence is
     `screenshots/focus-completion-celebration/` with its README, not the unit test.**
   - **`F-FocusCard-5`** — close-out, and it has picked up more since block 2:
     `FocusTimerBar.swift:8-25`'s header, `FocusSessionBackingStore.swift`'s "append-only in
     practice" comment (now FALSE — records are re-saved on confirm), `FocusSprintPersisting`'s
     protocol doc (predates both widenings). **`FocusCompletionCard.swift`'s doc comment and
     `screenshots/focus-completion-card/README.md` were corrected in this session rather than
     deferred** — both still said the floating geometry was unchosen, which is the opposite of a
     settled decision, and that is exactly how the design record's block-1 half rotted. (updated)
   - The live opener is `handoff/START-HERE-focus-card-block4.md`.

**0b. E's SECOND change — still not described.** Ask once the arc reaches a natural stopping point.
   (carried; E's *first* change was the focus card arc, now three-fifths built.)

1. **Small defects found while building blocks 1–3, none blocking, all in the card:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs. (carried)
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** Wants an Accessibility
     Inspector pass — this bar is the app's only door to `FocusSprintDetailView`. (carried)
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split
     files. (carried) `FocusCompletionCard` and `FocusCompletionCardStack` both have one.
   - **A slow location fix delays the completion CARD, not just the write.** Correct as built;
     worth knowing if E ever reports the card appearing late. (carried)
   - **The stack has no UI journey**, and probably cannot have a useful one: reaching a
     three-layer stack needs three sprints each floored at 30s with none confirmed. The evidence
     is the render and E's device verdict, which is what the design record anticipated for
     blocks 1–3. (NEW)

2. **Two more dead design tokens, and two dead helpers.** `BarSurface` (a colorset, defined,
   unit-tested, used by nothing), and `AppTabBarPresentation.slotWidth` / `restingSlotWidth`,
   which have ZERO production call sites and **disagree about their input**. (carried)

3. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
4. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
5. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of this arc explicitly. The collision is real
  and documented-not-fixed: it shares `RootBottomOverlay`'s VStack with the completion stack, so
  an old unacknowledged app-was-dead completion and a new unconfirmed sprint can be on screen
  together in two different visual languages. Two keys, two published properties, two cards, zero
  interaction — by design. `F-FocusCard-5` records it. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; roughly valid to **2026-09-15**, six days out. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A green suite cannot see a `View`'s appearance, and this arc has now proved it three times.**
  Block 1's `layoutPriority` compression reached E's device; block 2's was caught by a render;
  block 3's was the completion cards behind the front one **ghosting their ring and summary line
  through `.regularMaterial`**, which blurs what is behind it rather than hiding it. Every layout
  assertion held. **Render the view to PNG from a unit test before the device build** —
  `UIHostingController` + `UIGraphicsImageRenderer` + `drawHierarchy`, `overrideUserInterfaceStyle`
  for dark, hosted in a `UIWindow` with the run loop pumped briefly. It costs a minute and needs
  no signed-in simulator. (NEW)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Get the names with `grep -oE "Test Case .*' failed" <log> | sort -u`.
  This sits beside the older warning that `grep -c 'Test Case.*failed'` counts eight test NAMES
  containing the word — both are about reading the same output wrongly. Block 3 predicted all
  five red-checks in both units and hit all five exactly. (carried)
- **SwiftLint's 400-line file and 250-line `type_body_length` ceilings are one TEST away**, not
  just one protocol widening away: adding a single test to `FocusCompletionStackServiceTests`
  tripped both. The fix is a thematic file split with its own `private` doubles — every Focus
  test file carries its own twins under the same names, so they cannot collide. (updated)
