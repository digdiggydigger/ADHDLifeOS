# Open items register — 2026-09-11 (twentieth edition; F-FocusCard-4 BUILT and MERGED, awaiting E's device verdict)

*Written at the close of the session that answered the light-mode peek question and shipped
`F-FocusCard-3-Peek`. **Block 3 is now effectively closed** — E ran three of their four device
checks and reported nothing wrong; only the airplane-mode one is outstanding, and it is a
Home-refresh check unrelated to the focus card. Supersedes the eighteen earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and to
update, rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `3a6a574` (PR #58, `F-FocusCard-4`); the last CODE change is `d8b334b`** ·
**Block 4 is BUILT, MERGED and INSTALLED on E's phone (01:48, 2026-09-11) — it CLOSES on E's
device verdict, which has not been given.** Verified for it: suite **2,663 / 0** (emulator UP,
0 `127.0.0.1:9099`, 0 skipped), lint **0 / 738**, sim + device `** BUILD SUCCEEDED **`, app
target **26.69% (12,255/45,914)** — comparable to the 26.56% below (one file added, extent
unchanged). Evidence: `screenshots/focus-completion-celebration/`. **Nothing for E to
republish.** Earlier state, still true of everything else: **no branch in flight**; every feature and chore branch was deleted by its
own merge, so **`main` is the only branch on GitHub** · every change lands through a PR ·
verified: **unit suite 2,638 / 0** (emulator UP, **0** `127.0.0.1:9099` hits, 0 skipped),
**SwiftLint 0 / 734**, sim + device builds `** BUILD SUCCEEDED **` · `firestore.rules` untouched,
**nothing for E to republish** · every `.xcresult` deleted after its figures were read.

**E's phone is on MAIN at `298fb17`**, reinstalled and launch-verified 2026-09-10 22:5x.

**Coverage: app target 26.56% (12,161/45,782) — identical to the eighteenth edition, and that is
correct rather than a stale copy.** This session's only app change was one constant's VALUE
(`peekStep` 8 → 14) plus doc comments, so it added and removed no executable lines: the
denominator could not move and the numerator had nothing to gain. The +1 test lands in the test
target, not the app's. Full breakdown:

```
ADHD LifeOS.app              26.56%  (12161/45782)
ADHD LifeOSTests.xctest      95.40%  (41635/43641)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)     ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)   ← read the 233-line testable surface, not this
```

### Landed this session

- **`F-FocusCard-3-Peek` — the peek raised 8 → 14** (PR #56, `298fb17`). A follow-up to block 3,
  built test-first: the pinning test failed on **1 test / 2 assertions**, exactly as predicted,
  before the constant moved. `reservedTopPadding` needed no change — block 3 derived it from
  `yOffset` precisely so this could move. Evidence:
  `screenshots/focus-card-light-peek-options/` (the six options) and
  `screenshots/focus-card-stack/` `10-`–`13-` (the result on device).

- **Three doc/evidence PRs** (#53 register SHA correction, #54 E's 8pt device pair, #55 the
  rendered options).

### What the peek work established, and it is worth more than the constant

- **The lever ordering this register carried was BACKWARDS.** It named `opacityStep` the blunt
  instrument. Opacity moves the keyline **1.30:1 → 1.35:1** — invisible — because the layer behind
  already draws at 0.85. **What the eye reads is the sliver's HEIGHT**, so `peekStep` is the lever.
  `scaleStep` 0.10 actually *lowers* keyline contrast to 1.21:1, dropping more of the line onto the
  corner curve. **A contrast ratio answers whether an edge can be DISTINGUISHED, never whether
  anyone will NOTICE it** — render the options before ranking levers.
- **`peekStep = 14` is the app's ONLY sanctioned off-grid spacing value.** §2 is 4/8/16/24; E was
  offered the on-grid 16 explicitly and chose the value they had approved by sight. The waiver is
  written into **`CLAUDE.md` §2** and pinned by `testThePeekStepIsTheValueEChoseByLooking`.
  **Do not "correct" it.**

## A · Decisions only E can make — minutes each

- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** (carried) A "look
      again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)
- [ ] **E's SECOND change — still not described.** Ask once the arc reaches a natural stopping
      point. (carried; E's *first* change was the focus card arc.)

## B · Real work, ready to start — recommended order

**0. THE FOCUS CARD ARC — blocks 1–3 CLOSED, 4 BUILT AND MERGED (awaiting E's verdict), 5 NOT STARTED.** The design
   record is **`handoff/SESSION-OPENER-focus-card-design.md`** — permanent, never archive it.
   **Read its "settled specification" with this register beside it**: blocks 1, 2 and 3 each moved
   against it, and the live opener carries the table of what actually shipped.
   - **`F-FocusCard-4` — SHIPPED `3a6a574` (PR #58), verdict pending.** Ask E: does the 0.3s
     pre-beat (complete ring, no tick, while the card lands) read as anticipation or as a glitch?
     The lever is `FocusCompletionCelebrationMetrics.delay`. The tick is the ring's existing bare
     `checkmark`, not the record's `checkmark.circle.fill` — deliberate, so the resting card stays
     the one E approved. The record's constraints, all held: **iOS 16 is the floor**, which rules out
     `PhaseAnimator`, `.symbolEffect`, `.keyframeAnimator` and `.sensoryFeedback`. The haptic keys
     on `confirmableCompletionCount`, NOT `completedSprintCount` (bumped on manual stops) and NOT
     `unconfirmedCompletions.count` (changes on confirm-removal, so it would buzz on dismissal).
     Reduce Motion renders the FINAL state. **Evidence is
     `screenshots/focus-completion-celebration/` with its README, not the unit test.**
     **Only the FRONT layer draws a real card** — a celebration keyed to a layer behind would be
     invisible, and one keyed to the stack rather than the front record would fire for cards the
     user never saw.
   - **`F-FocusCard-5`** — close-out. Stale docs to fix: `FocusTimerBar.swift:8-25`'s header,
     `FocusSessionBackingStore.swift`'s "append-only in practice" comment (now FALSE — records are
     re-saved on confirm), `FocusSprintPersisting`'s protocol doc (predates both widenings).
   - The live opener is `handoff/START-HERE-focus-card-block4.md`.

1. **E's fourth device check, not yet run: airplane mode + pull-to-refresh on Home.**
   `F-HomeTasksLastKnown` (`8b5f740`) should keep the last-known task set rather than emptying it.
   Unrelated to the focus card; checks 1–3 (Confirm-doesn't-reopen-a-collapsed-card,
   tap-opens-detail, `F-TabBar-NoScrollDrop`) were run by E on 2026-09-11 with nothing reported
   wrong. (NEW)

2. **Small defects in the card, none blocking:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs. (carried)
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** Wants an Accessibility
     Inspector pass — this bar is the app's only door to `FocusSprintDetailView`. (carried)
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split
     files. (carried)
   - **A slow location fix delays the completion CARD, not just the write.** Correct as built;
     worth knowing if E ever reports the card appearing late. (carried)
   - **The stack has no UI journey** and probably cannot have a useful one. The evidence is the
     render plus E's device shots, which is what the design record anticipated. (carried)

3. **Two more dead design tokens, and two dead helpers.** `BarSurface` (a colorset, defined,
   unit-tested, used by nothing), and `AppTabBarPresentation.slotWidth` / `restingSlotWidth`,
   which have ZERO production call sites and **disagree about their input**. (carried)

4. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
5. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
6. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
7. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of this arc explicitly. The collision is real and
  documented-not-fixed: it shares `RootBottomOverlay`'s VStack with the completion stack, so an old
  unacknowledged app-was-dead completion and a new unconfirmed sprint can be on screen together in
  two different visual languages. `F-FocusCard-5` records it. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. (updated)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A green suite cannot see a `View`'s appearance, and this arc proved it four times now.**
  Block 1's `layoutPriority` compression reached E's device; block 2's was caught by a render;
  block 3's was the cards behind **ghosting through `.regularMaterial`**; and the peek's own
  quietness was invisible to every layout assertion, all of which held. **Render the view to PNG
  from a unit test before the device build** — `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, `overrideUserInterfaceStyle` for dark, hosted in a
  `UIWindow` with the run loop pumped briefly. It costs a minute and needs no signed-in simulator.
  **To vary a `static let` constant across variants, make it `var` for ONE run, then
  `git checkout --` and prove the restore with a full build.** (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`. (carried)
- **SwiftLint's 400-line file and 250-line `type_body_length` ceilings are one TEST away.** The fix
  is a thematic file split with its own `private` doubles. (carried)
- **A `devicectl` launch denied with `Security` / "invalid code signature… not explicitly trusted"
  right after a re-issued profile is TRANSIENT — retry once before escalating to E.** It reads
  exactly like the free-account provisioning blocker. Check the embedded profile's
  `ExpirationDate` against `date` and run `codesign --verify --deep --strict`: valid and freshly
  minted means retry, not E. Three species share that one error surface, separated only by the
  failure reason: `Locked` (unlock), `Security` + valid profile (retry), `Security` + expired
  profile or "No Accounts" (E signs in via Xcode → Settings → Accounts). (NEW)
