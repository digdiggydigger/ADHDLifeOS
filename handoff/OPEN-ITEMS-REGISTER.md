# Open items register — 2026-09-09 (seventeenth edition; F-FocusCard-2 SHIPPED and CLOSED on E's device verdict)

*Second close-out of the same day. **F-FocusCard-2 is CLOSED** — E: *"I've run a short sprint, and
it seems to be working correctly."* The arc is now half built: blocks 1 and 2 merged, 3–5 open.
The sixteenth edition (`adda07b`) is in git history; this one carries only what is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and to
update, rather than improvising a list in chat. Supersedes the sixteen earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `1f0d93a`** (PR #47) · **no branch in flight**; `feature/focus-card-2` deleted both
sides by its merge · every change lands through a PR · verified: **unit suite 2,619 / 0**
(emulator UP, 0 `127.0.0.1:9099` hits, 0 skipped), **SwiftLint 0 / 731**, sim + device builds
`** BUILD SUCCEEDED **` · **app target 26.37% (12,037/45,646)**, up from 26.02% (11,802/45,364)
at `59fcf20` — **comparable**: the denominator moved because the tree grew (+282 executable
lines, two new files), the measurement extent is unchanged, and the numerator grew +235 ·
`firestore.rules` untouched, **nothing for E to republish** · the emulator is running · every
`.xcresult` deleted after its figures were read.

**E's phone is on MAIN at `1f0d93a`**, reinstalled after the merge.

### Shipped and CLOSED this session

- **`F-FocusCard-2` — the provisional record and the completed-unconfirmed card** (PR #47).
  Block 2 of five, built test-first. A sprint that runs its countdown out now raises a card the
  user must Confirm, and **Confirm is what finally releases the collapse block 1 shipped
  deliberately sticky** — that reset is the whole reason the two blocks are adjacent.

  What shipped: `CompletedFocusSession.confirmedAt` (`confirmed_at`, optional),
  `FocusSessionService.unconfirmedCompletions` (newest-first) with push / confirm / restore in a
  new `FocusSessionService+Completions.swift`, `FocusCompletionCard` above the timer bar in
  `RootBottomOverlay`, and a new persistence key `focus.sprint.unconfirmedCompletions` that never
  touches the offline flow's.

  **One deviation from the design record, approved by sight rather than in words** — see item A1.

  **Verification:** five red-checks, one regression at a time, each predicted before running and
  each firing on exactly the predicted tests; tree restored and the suite re-run green.
  Evidence: `screenshots/focus-completion-card/` with a README.

## A · Decisions only E can make — minutes each

- [ ] **The completion card's geometry was a deviation, and E approved it by looking, not by
      choosing.** The design record said this card shares the collapsed running card's
      *"full-bleed flush geometry"*. That was written before block 1, where E reversed full-bleed
      — and "flush" is only available to the BOTTOM-most piece of bottom furniture, which this
      card deliberately is not (it stacks **above** a running sprint so that sprint stays
      operable). So it floats at the expanded card's geometry: inset 16, radius 24, all four
      corners, 76pt tall. E ran it and said it works. **Worth one explicit look before block 3
      builds the stack on top of it**, because the stack's peek offsets inherit this shape.
- [ ] **Confirm resets collapse unconditionally, and stacking makes that visible.** In E's own
      scenario — a routine auto-starts a new sprint while an old card still waits — confirming the
      *old* card expands the *new* sprint's card. That is the letter of E's rule (*"collapsed
      until the user has tapped Confirm"*), but stacking and collapse-reset were answered
      separately and this is where they meet. **Flagged, not changed. Becomes real in block 3**,
      which is what puts two cards on screen at once.
- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** (carried) A "look
      again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)

## B · Real work, ready to start — recommended order

**0. THE FOCUS CARD ARC — blocks 1 and 2 CLOSED, blocks 3–5 NOT STARTED. This is the live work.**
   The design record is **`handoff/SESSION-OPENER-focus-card-design.md`** — permanent, never
   archive it. **Read its "settled specification" with this register beside it**: block 1's half of
   that record was overtaken by E's device passes, and block 2's half carried one stale line into
   this session (the "full-bleed flush geometry" above). **Blocks 3–5 are untouched by those
   reversals**, but block 3 inherits block 2's actual shape, not the record's.
   - **`F-FocusCard-3`** — the notification-style stack. Newest in front, older peeking behind as
     edges, **three layers drawn, no data cap, no "confirm all"** (E ruled it out and a call-site
     test must guard its absence). The service side already exists and is tested: the array is
     newest-first, so a card's depth IS its index. This block is `FocusCompletionCardStack` +
     `FocusCompletionStackLayout` and the `RootBottomOverlay` swap from `.first` to the stack.
   - `F-FocusCard-4` the celebration · `-5` close-out.
   - **`F-FocusCard-5` has picked up two more items**: `FocusSessionBackingStore.swift`'s
     "append-only in practice" comment is now FALSE (records are re-saved on confirm), and
     `FocusSprintPersisting`'s protocol doc predates both widenings.
   - The live opener is `handoff/START-HERE-focus-card-block3.md`.

**0b. E's SECOND change — still not described.** Ask once the arc reaches a natural stopping point.
   (carried; E's *first* change was the focus card arc, now half-built.)

1. **Small defects found while building blocks 1–2, none blocking, all in the card:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs. (carried)
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** Wants an Accessibility
     Inspector pass — this bar is the app's only door to `FocusSprintDetailView`. (carried)
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split
     files. (carried) `FocusCompletionCard` does have one.
   - **A slow location fix delays the completion CARD, not just the write.** The push in `stop()`
     sits after `await locationStamp()` deliberately — Confirm re-saves from the pushed copy
     through `setData` with no merge, so an unstamped card would ERASE `place_id`/lat/long on
     confirm. `CoreLocationFixProvider.fixTimeout` bounds it at 8s. Correct as built; worth
     knowing if E ever reports the card appearing late. (NEW)

2. **Two more dead design tokens, and two dead helpers.** `BarSurface` (a colorset, defined,
   unit-tested, used by nothing), and `AppTabBarPresentation.slotWidth` / `restingSlotWidth`,
   which have ZERO production call sites and **disagree about their input**: `slotWidth` takes
   CONTENT width, `restingSlotWidth` takes SCREEN width. (carried)

3. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
4. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
5. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of this arc explicitly. **The collision is now
  real and is documented-not-fixed**: it shares `RootBottomOverlay`'s VStack with the new
  completion card, so an old unacknowledged app-was-dead completion and a new unconfirmed sprint
  can be on screen together in two different visual languages. Two keys, two published
  properties, two cards, zero interaction — by design, and a migration between them is the
  refactor E ruled out. `F-FocusCard-5` records it. (updated)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; roughly valid to **2026-09-15**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** A
  red-check prediction made in tests will read low — three of block 2's five predictions were
  "wrong" only because one failing test contributed two or three failed assertions. Get the names
  with `grep -oE "Test Case .*' failed" <log> | sort -u`, and predict TESTS, then reconcile.
  This sits directly beside the older warning that `grep -c 'Test Case.*failed'` counts eight
  test NAMES containing the word — both are about reading the same output wrongly. (NEW)
- **Widening a protocol tips test classes over SwiftLint's 250-line `type_body_length`, because a
  NESTED type's body counts against its enclosing one.** Two `FocusSprintPersisting` widenings in
  one day did it twice. The fix is to hoist the `private` fake to FILE scope — still visible to
  exactly that file, no cross-file collision, and the enclosing class loses the whole body. Do
  NOT reach for a protocol-extension default instead: that silences the compile break which is
  the block's red step. (NEW)
- **An optional `var` gets an implicit `nil` default in the memberwise init**, so adding
  `confirmedAt` broke no call site. Making it non-optional would have thrown `keyNotFound` on
  **every record already in Firestore** and emptied the analytics. Note the guard that catches
  this (`testLegacyRecordDecodesAsProvisional`) does NOT fail if you merely drop the `CodingKeys`
  line — that is a different test's job, and the two are easy to conflate. (NEW)
- **`save(_:id:in:)` is `setData` with NO merge, so any re-save is a full upsert and a dropped
  field is an ERASED field.** This is why block 2 pushes the *stamped* record rather than the bare
  one. Grep for anywhere a record is rebuilt rather than copied before re-saving. (NEW)
- **A shared teardown is the wrong place for a side effect that belongs to ONE of its callers.**
  `finishCurrentSprint` serves the manual stop, `start`'s replacement path and the app-was-dead
  settle. Pushing the completion card there would have raised a card for all three — and TWO for
  the offline sprint, which has its own card. Neither the manual-stop test nor the replacement
  test catches it; `testTheOfflineRestorePathPushesNothingToTheNewStack` does. **Count a
  function's callers before putting a side effect in it.** (NEW)
- **`layoutPriority` decides who is OFFERED space first, NOT who is allowed to shrink.** Putting
  it on a flexible `Text` to beat a `Spacer` makes SwiftUI compress that `Text`'s priority-0
  siblings to zero width. Short, fixed content needs `.fixedSize()`. **`UIHostingController`'s
  `sizeThatFits` cannot catch this** — it reaches a view's total height, not the rendered width of
  a `Text` inside an `HStack` — so a `layoutPriority` change wants a LOOK, not a green suite.
  (updated: this is now a two-instance rule, and block 2's look is
  `screenshots/focus-completion-card/`)
- **A SwiftUI view can be rendered to PNG from a unit test** — `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, with `overrideUserInterfaceStyle` for the dark
  variant. The test target hosts the app, so every asset colour and type resolves and no swiftc
  probe and no signed-in simulator are needed (so no `9099` poison and no erase). This is how
  block 2's evidence was made in about a minute; the probe was deleted in the same commit and
  only the measurement was kept. **Better than the swiftc probe for anything that needs the asset
  catalog.** (NEW)
- **`Color.primary` is a HIERARCHICAL style and gets VIBRANCY over a `Material`;
  `Color(.systemBackground)` is a concrete `UIColor` and does not.** The sprint ring's "next"
  marker rendered as a grey disc in a heavy black ring in dark mode. **The asymmetry inside one
  `ForEach` is the diagnostic.** Grep for a hierarchical style filling a large solid shape over a
  material. (carried)
- **Widget extensions have their OWN `Assets.xcassets`.** Tokens are consumed by NAME and are not
  shared with the app catalog. `FocusCheckpointDotState`'s palette is **deliberately duplicated**
  into `FocusTimerWidget/FocusActivityComponents.swift`. (carried)
- **A source-reading call-site test MUST strip comment lines before any `XCTAssertFalse`.** These
  files document the anti-patterns they ban. The fix is an `appCode()` helper beside
  `appSource()`. (carried) **A call-site test can also read ORDER**, not just presence — block 2
  guards that the push is written before `await log(` and that `finishCurrentSprint` does not
  push, both by comparing `range(of:)` bounds. (updated)
- **A metrics test cannot always guard what its name claims. Ask what the assertion reads on the
  BROKEN build** — and when the answer is "the same", rename the test and say so in its doc.
  (carried)
- **`UIHostingController.sizeThatFits` measures a real SwiftUI view's HEIGHT in a unit test.** It
  is the only assertion that catches a touch target leaking into layout. CLAUDE.md's rule is that
  a screenshot folder is earned by what a test CANNOT assert; height can be asserted, so it is —
  the completion card is pinned at 76pt against its own metrics, not a literal. (carried)
- **The tab bar's six slots are equal only while SCROLLED.** Any "align to the tab icons" rule
  holds in one state only. (carried)
- **There is no `PreferenceKey` or width-measurement helper anywhere in the app target.** (carried)
- **The nav bar's scroll state is STICKY, not transient** — hysteretic, true past 24pt, back only
  at <= 8pt. Do not dismiss a "only while scrolled" defect as momentary. (carried)
- **A single-load test cannot catch a "keeps last-known" bug, and reads exactly like one that
  can.** The discriminating test needs TWO loads. (carried)
- **Swallowing an error into an empty collection turns "don't know" into a positive claim.**
  `(try? …) ?? []` is the shape to grep for. (carried)
- **A programmatic scroll is invisible to a gesture-driven model.** (carried)
- **`RootView.swift` is at 399 of 400 lines.** New members go in an extension file — and a
  `private(set)` published property cannot be written from one, which is why `session`,
  `logErrorMessage`, `offlineCompletionSummary` and now `unconfirmedCompletions` all lack it.
  (updated)
- **Stacking a block on an unverified block is fine when E asks for it.** (carried)
- **A "rule right, wiring wrong" red is worth staging on purpose.** (carried)
- **Derive, then `onChange` the derived value.** (carried)
- **`xcrun xcresulttool export attachments`** pulls a journey's screenshots; **`ffmpeg -vf
  "fps=2,scale=360:-1"`** turns E's GIF into frames. (carried)
- **A locked phone refuses the LAUNCH and not the install.** (carried)
- **A trailing `grep -c` that finds nothing exits 1 and makes a green run look failed** — read the
  `exit=` you echoed, not the task status. **And a zsh glob that matches nothing aborts the whole
  compound command before anything runs** — quote the paths in an `rm -f`. (updated)
- **Ask before designing when E invites it; read the user's REAL data before choosing between
  hypotheses.** (carried)
- **The resolver's tie-break was designed for different radii**; take the ordered LIST. (carried)
- **The fence ledger shows all three home fences flapping departure → arrival within 4 s.**
  (carried)
- **A swiftc probe of the pure files settles a geometry question in a minute** — but see the
  render-from-a-unit-test note above, which is better whenever the asset catalog is involved.
  (updated)
- **A `CGContext` bitmap is TOP-DOWN**; **red-check regressions ONE AT A TIME**; **iPhone
  Mirroring cannot be started from the terminal.** (carried)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** — never scope a red-check down for speed.
  (carried)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried) **Block 2
  shipped no UI journey deliberately**: a natural completion needs a real countdown to expire and
  `FocusCheckpoints.minimumIntervalSeconds` floors a sprint at 30s, so a journey would either
  sleep 30 seconds or assert against a state it faked. Said in the report rather than shipped
  vacuous. (NEW)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is `START-HERE-focus-card-block3.md`.** `START-HERE-focus-card-block2.md` was
  consumed and archived into `handoff/archive/` in the same move that wrote it. Exactly one is
  live — check, because two would mean one is a trap. (updated)
- **A plan written only to `~/.claude/plans/` does not survive a session boundary.** Any design a
  future session must act on belongs in the repo. (carried)
- **A `NavigationPath` is blind to closure-link and flag pushes.** (carried)
- **The harness's `openTab` returns early on a selected slot.** (carried)
- **A zero-height anchor view inside a padded stack costs its spacing.** (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried) **`TODO-CLAUDE-CODE.md`'s
  F-FocusCard-1 and -2 headings were both still `[ ] NOT STARTED` after shipping** — ticked this
  session, with the overtaken descriptions annotated rather than rewritten. (NEW)
