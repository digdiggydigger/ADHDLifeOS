# TODO-CLAUDE-CODE.md

*Handoff document: Cowork → Claude Code*
*Project: **ADHD LifeOS (Es_Life_OS mobile)***

**Created:** 2026-07-17
**Status:** Xcode project scaffolded (SwiftUI, XCTest). SwiftLint + 70% coverage bar decided. No architecture doc or FEATURE blocks yet — first Cowork design session pending.

---

## How Claude Code Uses This File

See `WORKFLOW.md` for the full cycle and FEATURE block template. Quick version:

1. Before each work session: read this file top-to-bottom.
2. Pick the next `[ ] UNCHECKED` item under **Current Sprint**.
3. Read the associated docs in `/docs/`.
4. Execute the task step-by-step (TDD, per `claudecode.md`).
5. Mark as `[x] COMPLETED` when done.
6. Commit: `[Feature/Fix] Brief description`.
7. **Stop after one FEATURE block and wait for review** (one clear next action, no batching).

---

## Current Sprint

**Queued 2026-08-28 from E's on-device review**, in the order E asked for. Five device screenshots
of `22dba79` covered three of the four things that had shipped unseen; the fourth (the journal
pad's NIGHT face) is still unconfirmed, which is what block 4 exists to fix. Two of the four blocks
are defects the screenshots exposed, one is a gap they explained, one is taste.

**Ownership note:** these blocks were written by Claude Code, not Cowork, on E's direct instruction
("draft all of them up in a block starting with both the capture bugs"). That crosses the usual
line in `WORKFLOW.md` the same way the 2026-08-23 archive split did, and for the same reason — E is
directing this queue in chat. Cowork should feel free to rewrite or replace any of it.

---

### FEATURE: F-PillStay — the pill stays until you scroll back up  [x] COMPLETED

**E's direction (2026-08-31), changing the settled motion model:** *"currently, the pill button
returns back to its normal size — I want this to stay in pill form until the page is scrolled
upwards again."*

So the pill goes DIRECTIONAL and STICKY, the classic FAB pattern: scrolling down (finger moving
up) collapses the disc and it STAYS collapsed — through the stop, through momentum, through
reading; scrolling up (finger moving down) restores the disc immediately. The 1.2s settle timer
and its debounce machinery are REMOVED, not parked — dead code is this repo's most repeated
defect. The shrink spring and the expanding-fade regrow animations are untouched; only the
trigger changes.

**Mechanics:** the window-level pan observer now forwards `.changed` translation; the model
keeps a directional anchor and flips on ±12pt of travel in the new direction, so jitter can't
flap it and a mid-drag reversal switches state without a new touch. One judgment call beyond
E's words: a TAB CHANGE resets to the disc — a sticky pill on a fresh tab reads as a bug, and
E can veto this.

**Acceptance criteria:**

- [x] `CaptureDiscScrollActivity` rewritten: `prefersPill`, ±12pt directional latch with a
      re-basing anchor, no timers — 8 synchronous tests.
- [x] `CaptureDiscPanObserver.react(to:translationY:)` forwards began + changed; terminal
      states silent by design — 4 tests.
- [x] Call-site guards moved to `.prefersPill`; wiring chain asserted end to end.
- [x] SwiftLint 0 violations, suite 1,886 / 0 (settle-timer tests removed with the timer),
      build green (2026-08-31).
- [x] Discriminator rendered on the simulator (`screenshots/pill-stay/`): the pill still
      standing FIVE seconds after the down-scroll ended — the old build regrows at 1.2s — then
      the disc back after one up-scroll.
- [x] **APPROVED BY E ON DEVICE, 2026-08-31: "looks good."** The tab-change reset was offered
      for veto and not vetoed — it stands.

---

### FEATURE: F-FabDeepField — the FAB gets an identity, and the fan stops shouting  [x] COMPLETED

**E's verdict on device (2026-08-30):** the FAB's colour is wrong — *"the colors when the FAB is
extended… altogether it just doesn't look right."* Diagnosis, confirmed in source: the FAB wore
plain `AccentColor` (the same blue as the tab tint, "Clear the deck", Arrange and the Work bars),
the fan was five full-saturation solids borrowed from tile/bar tokens, and the Note disc's fill
literally WAS `AccentColor` — a second FAB inside the fan.

**Process: a real A/B, rendered before choosing.** Two directions E picked from four were built
and screenshotted on the simulator (rest / pill / fan-open, archived in
`screenshots/fab-colour-variants/`): **A** ink FAB (inverted neutral surface) + glass fan, **B**
deep-field gradient FAB + the same glass fan. **E chose B, explicitly.**

**What shipped:**

- **Deep-field disc**: `CaptureDeep` (new colorset, light `#4C3FE0` / dark `#5246E8`) → accent
  blue in a top-to-bottom `LinearGradient` on the one `Capsule`. Both hues live in the asset
  catalog — no raw colour in Swift (§4). Accent glow retained.
- **Glass fan**: each disc is its kind colour at 18% over `.ultraThinMaterial`, glyph + label in
  the full kind colour, hairline ring at 40% — the same tinted-tile language as the app's 44pt
  card icon tiles, so the open fan matches the app instead of fighting it. The Note disc no
  longer twins the FAB.
- The unused ink-variant colorsets were DELETED, not left behind (this repo's dead-component
  rule); variant A survives only as its archived renders.

**Verified:** SwiftLint 0, suite 1,887 / 0, build green, simulator renders of both variants.

- [x] **APPROVED BY E ON DEVICE, 2026-08-31** — six screenshots (IMG_8124–8130, light AND
      dark): *"variant B looks very nice."* The glass fan and gradient disc hold up in both
      appearances in the field.

**Addendum — E's margin pass (2026-08-31):** *"ADD more spacing/padding to the top and bottom of
the capture button when it is in pill form. ALSO the WHOLE capture icon location needs more
Margin applied to the bottom and right-hand side."* Shipped as: pill 52×32 → **52×40**; trailing
margin 16 → **24** (now `CaptureDiscMetrics.edgeMargin`, read by RootView); the overlay stack
lifted 52 → **60** off the tab bar — the SAME 8pt delta on both axes, which is what lets
`clearance` stay one number (84 → **92**) for the bottom inset and the trailing clearance alike.
All eleven `.captureDiscClearance()` call sites inherit 92 automatically; the freeze test moved
with the derivation. Suite 1,887 / 0.

**SETTLED BY E ON DEVICE, 2026-08-31** — after two more dials (pill height 40 → 48, then width
52 → 60, i.e. "goto 4pt" per side): *"those proportions look much better on the app."* The
capture-disc arc is closed end to end: F-DiscPill → F-PillTune (0.68 glass) → F-FabDeepField
(gradient + glass fan + margins + 60×48 pill). Do not reopen any of these numbers without a new
E verdict.

---

### FEATURE: F-PillTune — the pill grows up, and the disc comes back like a sunrise  [x] COMPLETED

**E's device verdict on F-DiscPill (2026-08-30, five stills):** the mechanism works everywhere,
and two things need retuning: *"the pill button is too small and needs to regrow EVEN slower, a
slow gradual expanding fade effect would look good."*

**The three turns of the dial:**

1. **Bigger pill** — 40×24 reads as a sliver on device. Goes to **52×32, glyph scale 0.8**:
   unmistakably a button, still clearly smaller than the 60pt disc it stands in for.
2. **Longer settle** — `settleDelay` 0.7s → **1.2s**. The finger has to be up for a beat longer
   before the disc starts coming back.
3. **The regrow becomes an expanding fade** — the shrink stays a snappy spring (it must feel tied
   to the finger), but the regrow drops the spring for a **slow `easeOut` (0.9s)**, and the pill
   state carries slight translucency so the expansion visibly *fades in* to the full disc. One
   asymmetric-animation ternary; `reduceMotion` still snaps both ways.

**Acceptance criteria:**

- [x] `CaptureDiscMetrics` 52×32, glyph 0.8; the relative guard now bounds height by the full
      diameter — its point (strictly smaller than the disc) intact.
- [x] Settle delay 1.2s; the 0.3–1.5s deliberate-beat bounds test holds unchanged.
- [x] Asymmetric: shrink keeps the finger-tied spring, regrow is `easeOut(0.9)` + a pill-state
      opacity of 0.85 so the expansion fades in. Reasons in comments at the site.
- [x] SwiftLint 0 violations, suite 1,886 / 0 (+1: `testRootViewRendersTheDiscLabel`, added
      because the face moved to `Theme/CaptureDiscLabel.swift` for the 400-line file limit and
      the wiring chain needed the new link asserted), build green (2026-08-30).
- [x] Re-rendered on the simulator against the emulator account: `screenshots/disc-pill-tune/`
      — bigger pill mid-drag, a frame mid-regrow, settled disc. Feel verdict stays E's, on
      device.

**Addendum, same evening — the pill goes glass (E's GIF verdict).** E recorded the tuned build
(`Capture PillButton preview.gif`, 85 frames analysed via an ImageIO frame dump) and dialled the
pill's translucency himself: *"try .68 — just below the 0.7 sweet spot."* Shipped as
`CaptureDiscMetrics.pillOpacity = 0.68` (one spelling; the label reads the metric), guarded by
`testPillOpacityStaysInTheReadableGlassBand` — bounds 0.5…<1 because at 1.0 the trailing corner
swallows content again (the GIF showed the opaque pill covering a nudges chip and a capture
row's edge) and below ~0.5 a blue control reads as disabled. Suite 1,887 / 0.
`screenshots/disc-pill-tune/4-glass-pill-068.png` shows the Money row's progress bar reading
through the pill. The GIF also confirmed the design's known boundary: stop mid-page and the disc
regrows over content after the settle — flagged to E as a decision, not changed.

---

### FEATURE: F-DiscPill — the capture disc gets out of the way while you scroll  [x] COMPLETED

**Queued 2026-08-30 via the post-nudges session opener; E's report, made twice:** the capture disc
sits over real content throughout the app — over a nudge row's time, over a capture's subtitle,
over the "Week review" card. E's words: *"the FAB sits over multiple places throughout the app at
different stages."* Evidence in-repo: `screenshots/nudges-door-device/*` and
`screenshots/first-nudge-reachable/*`.

**E's design call, already made — do not re-ask:** *shrink the disc to a small pill while
scrolling.* (Offered and NOT chosen: hide-on-scroll, move into the tab bar, fixed disc + more
clearance.)

**What this is NOT:** F-DiscClearance (`b62aea4`) already fixed the END of every scroll with the
84pt `safeAreaInset`. This block is about the disc parking over content MID-scroll.

**Design (Claude Code's execution of E's call):**

- While a drag is in progress anywhere in the signed-in UI, the 60pt disc shrinks to a small
  pill; when the finger lifts, it grows back after a short settle delay so stop-and-go scrolling
  doesn't flap. Scroll detection is a window-level `UIPanGestureRecognizer` — the exact
  `KeyboardTapAway` shape: `cancelsTouchesInView = false`, always-simultaneous, zero per-screen
  wiring, covers every screen added later.
- The morph is visual-only: the button's OUTER frame stays 60×60, so the ≥44pt hit target (§3),
  the timer-bar stack layout, and every UI-test frame assertion are untouched. `Circle` becomes
  `Capsule` for free — a 60×60 capsule IS a circle — so one shape animates both states.
- Geometry lives in `CaptureDiscMetrics` beside `clearance`, which does NOT change: the rest
  state is still a 60pt disc, so the 84pt clearance the eleven call sites depend on holds.
- The fan overrides the pill: `isFabOpen` forces the full disc (the scrim blocks scrolling
  anyway, and the ✕ rotation needs the disc).
- Springs per §5; `reduceMotion` collapses the morph to a snap.

**Acceptance criteria:**

- [x] `CaptureDiscScrollActivity` (ObservableObject): `dragBegan()` shrinks immediately,
      `dragEnded()` restores after a settle delay (0.7s), a new drag inside the window cancels
      the restore. Deterministic tests via an injected delay — 8 tests.
- [x] `CaptureDiscPanObserver`: window-level pan → activity model, state mapping unit-tested via
      a `react(to:)` seam (`.began` → began; `.ended/.cancelled/.failed` → ended; nothing else)
      — 5 tests.
- [x] Call-site guards in the `CaptureDiscClearanceCallSiteTests` mould — 5 tests. Red-checked
      before wiring: all three RootView guards failed at their own assertions on the unwired
      tree (18-test run: 15 pass / 3 fail), then 18/18 after wiring. Not vacuous.
- [x] SwiftLint 0 violations, unit suite 1,885 / 0, build green (2026-08-30).
- [x] SIMULATOR verification, stronger than the block dared ask for: a fresh emulator account
      driven through the real signup (`SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST` + idb), then
      a 2s background drag with a screenshot MID-GESTURE. `screenshots/disc-pill/`: full disc at
      rest → pill mid-drag with the Relationships row readable past it → full disc again 1.5s
      after the lift. The discriminator is real: absent the fix, the mid-drag still shows the
      60pt disc, as the other two stills do.
- [ ] OUTSTANDING — E has not seen it on device. The morph's FEEL (spring, settle beat) is a
      device judgement; the simulator proves the mechanism only. Side-finding for the register:
      the fresh-account signup on the emulator DID seed — six life areas, 5-item today, nudges
      section present — which answers half of the opener's "did seeding land?" for the code
      path; E's device run still answers it for production.

---

### FEATURE: F-SignUpPolish — two things E marked on the signup screen  [x] COMPLETED

**From E's fresh-account signup on device, 2026-08-30** — the first time anyone has walked the
new-user path end to end.

**1. The Done bar floating above the keyboard: "it's clogging the screen up."**

This is BUG-b5 from E's own 2026-08-26 checklist ("the keyboard must never be a trap"), so it was
NOT deleted. `.keyboardDismissal()` was applied to the `Group` wrapping BOTH auth branches, so the
login screen inherited a bar meant for the tabs. It now sits on the tabs only.

**That does not reopen b5.** `KeyboardTapAway` is installed window-level and already covers login —
its own note says tapping away is *"the gesture people actually reach for"*. The bar was redundant
there, not load-bearing. Verified by reading the install site, not assumed.

**2. The password field's uneven top/bottom spacing** (E marked the gaps on the screenshot).

The reveal button was an `HStack` sibling at `.frame(width: 44, height: 44)`. §3 requires that
44×44 target — and in a row, its HEIGHT drove the whole card: **Password ≈ 76pt against Email and
Name at ≈ 53pt**, since `fieldCard` adds 16pt padding all round to a ~21pt text row. The button is
now an `.overlay`, which keeps the full target and contributes nothing to layout height. All three
cards match.

**Acceptance criteria**
- [x] Login no longer shows the keyboard Done bar; the tabs and modal composers still do.
- [x] Password, Email and Name cards are the same height, verified in a render.
- [x] The reveal button keeps its 44×44 target (§3) — an overlay, not a shrunken frame.

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 558 files
xcodebuild test (unit)  → Executed 1867 tests, with 0 failures (0 unexpected)
render (signup form)    → dark EXIT=0, light EXIT=0 — the three cards visibly match
```

**The Done bar removal is NOT visually verified, and that is stated rather than glossed.** The
render harness could not show it: the simulator runs with a hardware keyboard attached, so no
software keyboard appears and a `ToolbarItemGroup(placement: .keyboard)` has nothing to attach to.
`defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false` plus a sim restart
did not take for the headless test runner.

**No assertion was added for it either**, deliberately: with no software keyboard there is no
toolbar, so `XCTAssertFalse(app.buttons["Done"].exists)` would pass whether or not the fix existed
— a vacuous guard, worse than none. See [[geometry-journey-vacuity]]. E reported it from the
device and confirms it there.

**A near-miss worth recording.** The first signup render was named `5-signup-keyboard-up`, its
`app.keyboards.element` assertion passed, and the image contained no keyboard — `app.keyboards`
was satisfied by the hardware keyboard's accessory state. Had it shipped as evidence it would have
proved nothing. Third time this session a picture nearly passed for proof of something it could not
show: **an assertion going green is not the same as the screen showing the thing.**

---

### FEATURE: F-FirstNudgeReachable — a new account can actually make its first nudge  [x] COMPLETED

**A brand-new user could not create a nudge by any action available to them.** Three true things
that only add up to a dead end when you put them together:

1. `loadedNudgesSection` was gated on `!due.isEmpty || scheduled > 0` — no nudges, no section.
2. First-run seeding creates six life areas, five tags, three tasks and a journal entry, and
   **never a nudge**.
3. The **only** route to the Nudges screen is the door inside that section.

So the feature was unreachable until a nudge already existed, and nothing the user could do would
produce one.

**Found by accident, and the accident is the interesting part.** `RenderHarnessUITests` failed on a
fresh account with "Today never rendered the nudges door" while being pointed at something else
entirely. The message was true; the assumption that a signed-in account can see the door was not.

**This is [[dead-shared-component-pattern]] for the SIXTH time, and the most clear-cut yet.** The
empty-state copy for this exact card already existed AND was already unit-tested:

```
doorSubtitle(0, 0) → "Recurring reminders you set for yourself."   HomeNudgesDoorTests:61
chipText(0, 0)     → "None yet"                                     HomeNudgesDoorTests:79
countLine(0, 0)    → "No nudges yet"                                HomeNudgesSectionTests:86
```

Its own doc comment says *"The empty case describes what nudges ARE, because someone with none has
no idea."* Someone designed this screen, wrote down why it mattered, and unit-tested every string —
and the gate meant no user could ever see a word of it.

**The gate was DELIBERATE, and is preserved rather than reversed.** Its doc comment read *"Silent
when there is nothing due AND nothing scheduled: an empty schedule is not news, and Today does not
need a card to say so."* That reasoning is right about a STATUS card and only wrong about a
feature's sole entrance. E's call was the third option offered: **show it empty only until the
first nudge exists.** So `shouldRenderSection(hasAny:hasEverHadAny:)` has three states, not two,
and silence returns the moment the user has ever had a nudge.

**E's design call on the empty face, 2026-08-30:** *"show the nudges door with something such as a
grayed out effect over the nudges section with a clear direction to 'Add your first nudge'."*
Muted context, one lit action.

**Acceptance criteria**
- [x] `HomeNudgesSection.shouldRenderSection(hasAny:hasEverHadAny:)` — pure, three tests written
      first, covering all three states including the preserved silence.
- [x] `NudgeFirstRunMarker`, keyed **per account** by uid. Latched by `.task` (arriving with
      content) AND `.onChange` (the list arriving later, or the user creating their first) —
      never written during body evaluation.

**A defect I shipped inside this block, and the correction.** The flag was first written as a
plain `@AppStorage("nudges.hasEverHadAny")` — which is UserDefaults, and therefore **per DEVICE**.
A second account signed into one phone would inherit the first account's answer, so a genuinely
new user would never see their first-run door: **the exact dead end this block exists to remove,
reintroduced one layer up.**

Worse, it shipped with a comment asserting the failure was harmless — *"the worst case is the
empty door appears once more than it needed to, which is the harmless direction"*. That is
backwards. This flag can only ever SUPPRESS the door, never add a spare one, so **every error it
makes is in the harmful direction.** The reasoning was done once, written down confidently, and
not checked.

No test caught it. It surfaced because E asked to SEE the first-run door on the device, which
forced the question of what would actually happen — and the answer was "nothing, because your
phone's flag is already set". `NudgeFirstRunMarker` is keyed by uid, and
`testTwoAccountsOnOneDevice_doNotShareAnAnswer` is the guard that exists so this cannot come back.
- [x] The first-run face: ⏰ desaturated with **`.grayscale`, not `.opacity`** — an emoji cannot be
      de-emphasised with `foregroundStyle`, and a translucent glyph reads as broken rather than
      quiet. §4 bans opacity as a substitute for semantic colour; desaturating a picture is a
      different operation.
- [x] "Add your first nudge" is a **real 44pt Button**, not styled text — it has to be pressable to
      mean what it says.
- [x] `FirstRunJourneyUITests` — seeds NOTHING on purpose. The moment it arranges a nudge it stops
      testing the thing it exists for.

**Red-checked, and it failed at its own assertion rather than incidentally:**
```
RED    FirstRunJourneyUITests.swift:51: XCTAssertTrue failed - A brand-new account cannot see
       the nudges door, so it can never create a first nudge. The section is gated on already
       having one, and nothing else routes there.
       Executed 1 test, with 1 failure (0 unexpected)

GREEN  Executed 1 test, with 0 failures (0 unexpected)   EXIT=0
```

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 558 files
xcodebuild test (unit)  → Executed 1867 tests, with 0 failures (0 unexpected)
                          ** TEST SUCCEEDED **   (1859 + 3 predicate + 5 marker, all first)
render harness          → first-run door, dark and light, both EXIT=0
```

---

### FEATURE: F-NudgePresets — the New nudge sheet stops charging five taps for "weekdays"  [x] COMPLETED

**E's verdict, from the device, 2026-08-30: "THIS NEEDS RE-DESIGNING! Its very ugly and awkward to
use."** The still is `screenshots/nudges-door-device/new-nudge-sheet-BEFORE.jpeg`. Six defects, and
the ugly one was a genuine layout failure rather than taste:

1. **Every weekday label wrapped mid-word** — "S/un", "M/on", "Tu/e", "W/ed", "Th/u", "Fr/i",
   "Sa/t". Seven `.bordered` buttons in a bare `HStack` inside a `Form` inset get ~40pt each,
   narrower than the label needs. §1 forbids exactly this ("must never clip or truncate
   unexpectedly").
2. **Sub-44pt hit targets** at ~40pt wide (§3), and a stock `.bordered` where §3 requires an
   explicit primitive press style.
3. **One action wearing three labels** — nav title "New nudge", section header "Add Nudge",
   submit row "Add Nudge".
4. **The submit read as disabled placeholder text**, not a button, and sat at the bottom of the
   form instead of the nav bar where iOS puts a confirming action.
5. **A full-height sheet** holding roughly a third of a screen of content.
6. **The header `+` was 40×40**, under the same 44pt floor.

**The root cause is this repo's most-repeated defect, for the fifth time.** `ChoiceChipButtonStyle`
is the house chip — **13 call sites across 8 files**, and `FocusCadenceEditorCard` already uses it
for preset chips in this exact shape. The New nudge sheet was the ONLY place using stock
`.bordered`. It never adopted the app's own vocabulary, which is why it read as foreign.
See [[dead-shared-component-pattern]].

**E's design call, asked before building** (the F-NudgesDoor precedent): *presets first.*

**Acceptance criteria**
- [x] `NudgeSchedulePreset` — Daily / Weekdays / Weekends / Custom, with the weekday sets, the
      chip titles and the summary line. **Pure logic, tested first, 13 tests.**
- [x] Chips laid out 2×2, not 4-across: "Weekends" and "Custom" do not fit four-across at
      accessibility text sizes, and cramming is what wrapped the labels in the first place.
- [x] The Custom day row uses **single letters** (S M T W T F S, Sun-first like the Clock app's
      alarm repeat) at `maxWidth: .infinity, minHeight: 44`, so a label *cannot* wrap and the
      target meets §3. VoiceOver still reads the full day name via `accessibilityLabel`.
- [x] **Custom is a disclosure, not a reset** — it reveals the day row and KEEPS the current
      selection. Clearing would throw away days the user just chose.
- [x] Editing a nudge that already has a custom pattern **opens with its days showing**, rather
      than hiding them behind a chip the user would have to guess at.
- [x] Save in the nav bar (`.confirmationAction`), one title, `.presentationDetents([.medium, .large])`.
- [x] `ChoiceChipButtonStyle`, `Haptics`, `.bentoCard()`, `.sectionLabel()` reused — no new chip
      style, no new colour, no new haptic vocabulary.
- [x] The header `+` raised 40 → 44pt.
- [x] `NudgesView` hit 481/400, so the standing rule fired: the feature touching an over-budget
      file splits it. `NudgeScheduleEditor` moved to its own file — **338 / 155**.

**The cron off-by-one is the reason this got unit tests rather than eyeballs.** Sunday is `0`, so
"weekdays" is `1...5`; the obvious-looking `0...4` schedules Sunday–Thursday and still reads
correct in review. The red-check planted exactly that:

```
RED    (weekdays returning [0,1,2,3,4])
       testWeekdays_isMondayToFriday_notSundayToThursday   failed
       testMatching_recognisesEachNamedPreset              failed
       testDaySummary_namedPresets_readAsWords             failed
       Executed 13 tests, with 4 failures (0 unexpected)

GREEN  (restored to [1,2,3,4,5])
       Executed 13 tests, with 0 failures (0 unexpected)   ** TEST SUCCEEDED **
```

The empty set is covered too: it resolves to `.custom`, never `.daily`. Promoting it would light a
Daily chip for a schedule `NudgeValidation` rejects and `NudgeSchedule.parse` treats as
never-computably-due.

**E's three calls on the first render, all applied and re-rendered:**
1. **`.large` when the day row opens.** At `.medium` the day row pushed the time picker below the
   fold, and setting a time is half the point of the sheet. It GROWS and never shrinks — snapping
   back on close would yank the sheet out from under the thumb for no gain. The cost is empty
   space below Time when Custom is open, and that is the right way round.
2. **"Nudge name"**, replacing a seven-word question that `sectionLabel()` rendered in caps.
3. **The summary line follows what it describes** — under the chips when the day row is closed,
   under the DAYS when it is open. The wording was never wrong; the position was. Above the days,
   a lit "Custom" chip over the words "Every day" read as a contradiction when it was in fact
   describing the seven days Custom had preserved.

**The harness caught its own bad evidence, which is the reason it is being kept.** The first
Weekdays still was shot immediately after the tap and caught the spring mid-flight: the day row
ghosting as it collapsed, the chip half-filled, its label washed out. The state was right and the
picture was a lie — worse than no picture. It now settles on a real CONDITION, not a sleep:
choosing Weekdays closes the day row, so `tap(_:untilGone:)` on that row IS the animation-finished
signal. `RenderHarnessUITests` is committed deliberately (E's call), not deleted — the
F-PadNightRender rule is satisfied by choosing, not by deleting.

**A separate finding, logged not actioned.** The harness failed on its first run with "Today never
rendered the nudges door", and it was telling the truth: `loadedNudgesSection` is gated on
`!due.isEmpty || scheduled > 0`, so on an account with no nudges the whole section — door
included — does not render. First-run seeding creates life areas, tags, tasks and a journal entry
but **never a nudge**, and the only route to the Nudges screen is through that hidden door. **A
brand-new user therefore has no way to create their first nudge.** Not this block's scope; needs
E's call on the fix (an empty-state door, or a route from Settings).

**Verified 2026-08-30:**
```
swiftlint lint          → Found 0 violations, 0 serious in 555 files
xcodebuild test (unit)  → Executed 1859 tests, with 0 failures (0 unexpected)
                          ** TEST SUCCEEDED **   EXIT=0   (1846 + the 13 written first here)
render harness          → dark EXIT=0, light EXIT=0, settled
```
Six stills in `screenshots/nudge-presets-block/`, both appearances × three states, all at rest.

---

### FEATURE: F-PortraitArrival — the journeys stop inheriting the last test's orientation  [x] COMPLETED

**Found by F-LoginTestIsolation's own verification, and it is the same defect one layer down.**
Fixing the login tests meant running the WHOLE UI target for the first time. It came back
**17 tests, 10 failures** — and all ten were one cause, at one line, with one message:

```
UITestSession.swift:318: "loginPasswordField" SecureTextField never became hittable
```

**`ADHD_LifeOSUITestsLaunchTests` sets `runsForEachTargetApplicationUIConfiguration`,** so XCTest
runs `testLaunch` once per UI configuration. Two of the four are landscape, and the LAST one
leaves the simulator in **Landscape Left**. Orientation, exactly like the keychain, outlives the
app process — so every test scheduled after it launched into landscape, where the login form's
password field never becomes hittable.

```
1203  testLaunch (4th config) started
1206     Interface orientation changed to Landscape Left
1381  testLaunch passed                                    ← and the device stays there
1385  AccountNameJourney            → Landscape Left → FAILED
1991  CaptureDiscClearance/nudges   → Landscape Left → FAILED
2594  CaptureDiscClearance/today    → Landscape Left → FAILED
      … JournalJourney, SignedInJourney ×5, SignedOutLaunch — all of them, all identical
```

**Why nobody had seen it.** The whole UI target had never been run in one go. The run recorded as
"9/9 journeys" totalled twelve tests, which only adds up as **three plus nine** — so it cannot have
included `testLaunch`. Every previous run was scoped, and the scope excluded the one test that
poisons the rest. `JournalJourneyUITests` proves the ordering-dependence directly: it passed alone
in 150s at 04:39 and failed in-suite at 05:31.

**Not introduced by F-LoginTestIsolation.** That block changed `testLaunch`'s BODY; the
configuration sweep comes from `runsForEachTargetApplicationUIConfiguration`, which it did not
touch, and a test body cannot change how many configurations XCTest requests.

**Acceptance criteria**
- [x] `UITestSession.resetToPortrait()`, called from `launchSignedIn` (every journey) and by
      default from `launchSignedOut`.
- [x] **`testLaunch` is the one deliberate exemption** (`resettingOrientation: false`). Forcing
      portrait there would collapse the four-configuration sweep into four identical portrait
      screenshots — fixing the suite by silently deleting the capability that exposed the bug.
      The sweep keeps rotating; `resetToPortrait` absorbs what it leaves.
- [x] `swiftlint lint` → 0 violations, 0 serious in 551 files.
- [x] **Full UI target green** — and it is the first time the whole target has ever been green:

```
BEFORE   Executed 17 tests, with 10 failures (0 unexpected) in 1847.015 seconds
         ** TEST EXECUTE FAILED **      EXIT=65

AFTER    Executed 17 tests, with  0 failures (0 unexpected) in 1893.673 seconds
         ** TEST EXECUTE SUCCEEDED **   EXIT=0
         passed: 17   failed: 0
```

The fix is visible in the trace rather than merely inferred — `testLaunch`'s last configuration
still ends in Landscape Left, and the very next line of the following test is
`Interface orientation changed to Portrait`. The sweep keeps rotating; the next arrival rights
itself. Each previously-failing test is individually accounted for: AccountName 140.5s,
CaptureDisc 109.7s / 97.9s, Journal 113.4s, SignedInJourney 5/5, SignedOutLaunch 1/1.

**Open question for E, NOT actioned.** The app declares landscape support on iPhone
(`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone`, the Xcode template default). If the
login screen genuinely cannot reach its password field in landscape, that is a real usability
defect on a supported orientation — but "not hittable inside 45s" is evidence, not proof, and
nothing here changes app behaviour. A landscape still of the login screen would settle it.

---

### FEATURE: F-LoginTestIsolation — the login tests stop inheriting the last run's session  [x] COMPLETED

**Two failures on every full UI-target run, and the harness caused both.**
`testLoginForm_rendersFieldsAndValidatesInput` and
`testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm` only called `app.launch()`.
Firebase Auth persists its session in the simulator keychain; the keychain outlives the app
process **and the whole test run**; so the app restored into the tab bar and `loginEmailField`
never appeared.

**Why those two tests could not be their own guard — this is the part that was not yet written
down.** XCTest orders classes by name and `ADHD_LifeOSUITests` sorts ahead of every journey, so
within a single run they execute BEFORE anything signs in, and pass. The session that breaks them
is left by the PREVIOUS run. That is why `xcrun simctl keychain booted reset` made them pass, and
why it was never a fix: a person has to remember it, every time, forever.

**And that is the real cost.** Two failures that must be manually discounted on every run is
exactly how a genuine failure eventually gets waved through.

**Acceptance criteria**
- [x] `UITestSession.launchSignedOut()` — one entry point, reusing the harness's own
      `signOutIfSignedIn` rather than a second copy of the sign-out walk.
- [x] The emulator host is set **only when the emulator answers**. A keychain session can only
      have come from a journey, and journeys only run against the emulator — so this signs out of
      the same backend that signed in. With no emulator there is nothing to point at, and
      `ADHD_LifeOSUITests`' own header promise (fresh clone, zero local setup) still holds.
- [x] Applied to every member of the class, not just the two that were reported:
      `testLaunchPerformance` (it was timing whichever state got restored) and
      `ADHD_LifeOSUITestsLaunchTests.testLaunch` (it was photographing one).
- [x] `UITestEmulator.isRunning` exposed — a test can now ADAPT to the emulator, not only skip.
- [x] `SignedOutLaunchUITests`, the guard neither existing test can be: it signs in, then asserts
      a relaunch still reaches the login form.
- [x] Red-checked before the fix, and deliberately regressed after it.

**The deliberate regression, run 2026-08-30 after the block was committed and pushed.** The guard
had only ever gone red for the ORIENTATION reason (F-PortraitArrival), never for the reason it
exists — and [[geometry-journey-vacuity]] is this repo's standing proof that a test can pass
against a build with its fix removed. So `signOutIfSignedIn(app)` was removed from
`launchSignedOut`, the tree REBUILT, and the guard run against it:

```
BROKEN    SignedOutLaunchUITests.swift:40: error: XCTAssertTrue failed - A relaunch after
          signing in restored the session instead of reaching the login form.
          Executed 1 test, with 1 failure (0 unexpected) in 143.062s   EXIT=65

RESTORED  git checkout -- ; REBUILT (exit 0); signOutIfSignedIn(app) back at lines 61 and 95
          Executed 1 test, with 0 failures (0 unexpected) in 166.768s  EXIT=0
          ** TEST EXECUTE SUCCEEDED **       working tree clean
```

Two things make that a real check rather than a ritual. It failed at **line 40 — its own
assertion, in its own words** — not incidentally at an earlier step, which is how a vacuous test
fakes a red. And `resetToPortrait` was left in place throughout, so orientation is excluded and
the missing sign-out was the only variable. Restoration was proven by REBUILDING, not assumed.

**A second change, deliberate and worth flagging.** `ADHD_LifeOSUITests` carried its own
`focusAndType`, a drifted copy of `UITestSession.focusAndType`. The shared one is strictly better
— it retries on FOCUS rather than on the keyboard existing, which is the distinction that made the
password field type into nowhere — and the local copy had none of that. Deleted in favour of the
shared one. This is [[dead-shared-component-pattern]] again: a helper exists, is documented, and a
caller hand-rolls a worse copy beside it.

**Verified 2026-08-30:**
```
RED   (unmodified main, a journey's session in the keychain)
      ADHD_LifeOSUITests.swift:50: error: testLoginForm_rendersFieldsAndValidatesInput
      ADHD_LifeOSUITests.swift:80: error: testSignIn_invalidCredentials_showsInlineError…
      Executed 2 tests, with 2 failures (0 unexpected) in 83.652 seconds
      ** TEST EXECUTE FAILED **   EXIT=65

GREEN (same keychain session, with the fix)
      testLoginForm_rendersFieldsAndValidatesInput                passed (89.245 seconds)
      testSignIn_invalidCredentials_showsInlineErrorAndStays…     passed (69.546 seconds)
      Executed 2 tests, with 0 failures (0 unexpected) in 158.792 seconds
      ** TEST EXECUTE SUCCEEDED **   EXIT=0

swiftlint lint  →  Found 0 violations, 0 serious in 551 files   (550 + the new test file;
                   the zero baseline set by F-DiscClearance holds)
```

**The exit-code trap fired again, and the standing rule caught it.** The green-check run's shell
reported success while the real `xcodebuild` exit was 65, because `echo "EXIT=$?" | tee` returns
tee's status, not xcodebuild's. `EXIT=` was captured separately, which is the only reason the RED
above is a measurement rather than an assumption. See [[build-machine-limits]].

---

### FEATURE: F-TriageCardTruth — the decision card says what it is, and the tabs say how many  [x] COMPLETED

**Two defects, both visible in one screenshot of the Capture Inbox, both about a number or a word
that disagrees with the truth beside it.**

**Bug 1 — the top triage card renders a blank title for a photo capture.**
`CaptureInboxSections.swift:30` is `Text(capture.title ?? capture.content)`. `title` is `String?`
and `content` is a non-optional `String`, so a photo capture with no title and empty content
renders `Text("")` — E's screenshot shows the "Photo / 47 hours old" chips above an empty card.
The shared helper `CaptureRowPresentation.primaryText(for:)` already has the correct four-step
fallback chain ending in `"Photo capture"`, and is already unit-tested for exactly this input
(`CaptureRowPresentationTests:72`). The `Then` rows and Today's list use it and render correctly.
The decision card simply hand-rolls its own chain instead.

This is the SECOND time the card being a separate view from `CaptureRowView` has cost something —
the comment at `CaptureInboxSections.swift:34` records the first (the place label, E, 2026-08-27).

**Bug 2 — every count in the filter picker goes stale after any triage exit.**
The screenshot reads **"To triage (18)"** beside **"17 left"** with a **17** tab badge, and
**"Sorted (8)"** on a screen where a capture had just been journalled. The headline counts
`state`; the picker reads `service.counts[option]` (`CaptureInboxView.swift:204`). `removeCapture`
(`CaptureInboxService.swift:324`) rewrites `state` and never touches `counts`, and the only other
writers are `load()`, `refresh()`, `refreshInactiveCount()` and `refreshToTriageCount()` — the last
of which early-returns on this screen, because it is guarded on the screen NOT offering the
to-triage slice. So all four exits (`sort`, `logToJournal`, `discard`, `undoSeen`) leave it stale.

**Acceptance criteria**
- [x] The top decision card resolves its title through `CaptureRowPresentation.primaryText(for:)`;
      a photo capture with no title and empty content reads "Photo capture", not a blank line.
- [x] After any triage exit, `counts[activeFilter]` matches the list on screen — the picker can
      never contradict the headline.
- [x] After an exit, the DESTINATION tab's count is re-learned too (journalling raises Promoted,
      sorting raises Sorted), by the existing failure-tolerant `refreshInactiveCount` contract:
      a failed count fetch leaves that number alone and never surfaces an error.
- [~] `CaptureInboxService.swift` ends BELOW its 400-line ceiling, not at 398 — it is at the
      ceiling now, so this block splits before it grows.
      **PARTIAL, and stated rather than glossed: it ends at 397.** `refreshInactiveCount` moved out
      to `+Counterweight`, which paid for `removeCapture` growing, but the net is ONE line. That is
      not headroom. `removeCapture` and `replaceCapture` cannot follow it — `state` has a
      `private(set)` setter, so its writers are pinned to this file — so a real split has to move
      something larger (`promoteToTask` is the candidate). The brief's warning stands unchanged.
- [x] Unit tests first, covering each exit's effect on the active count and the destination count.
- [x] The Captures UI journey seeds a photo capture as the decision card and asserts it renders a
      title — the unit suite cannot see a SwiftUI body, and this defect only ever existed there.

**Two things found while fixing it, both folded in:**
- `promoteToTask` was a FIFTH exit site — it open-coded `state = .loaded(captures.filter { ... })`
  rather than calling `removeCapture`, so "Task it", the most-used verb of the five, carried the
  same staleness. It goes through the same door now.
- Undo needed the identical treatment in reverse: it moves a capture OFF another slice, and
  `refresh()` only ever corrected the tab being stood on.

**Deliberately NOT done, reasoning in the code:** `weekCounterweightLine` ("27 captured · 10 cleared
this week") goes stale on the same screen for the same reason. Refreshing it costs a third read per
tap (`fetchCaptures` pulls everything) on a screen built for rapid one-at-a-time triage, and unlike
the tab labels nothing sits directly above it contradicting it. `refreshCountsAfterExit` is the
function it belongs in if that ever changes.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 543 files
                                (TaskDetailView 438 file_length + UITests static_over_final_class)
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
xcodebuild test (unit)        → Executed 1806 tests, with 0 failures (0 unexpected)
xcodebuild test (5 journeys)  → Executed 5 tests, with 0 failures (0 unexpected) in 526.633s
coverage                      → CaptureInboxService 91.24%, +Triage 96.08%, +Counterweight 73.68%
```

**Journey flakiness, recorded because it cost time and will recur.** The first five-journey run on
this tree failed THREE of them — `testDueNudge`, `testSettings`, `testTaskDetail` — all with
messages pointing at `signOutIfSignedIn` ("Settings never presented", "Settings did not open, so
sign-out could never be reached"). Every one passed when re-run alone, and all five then passed
together on the rebuilt tree in 526s. So it is the documented harness fragility, not this block, and
not the app. The remaining weak point is visible: `UITestSession.swift:94` taps `settingsButton`
ONCE with no retry, so a swallowed tap surfaces two lines later as a true statement about the wrong
step. That helper has already been hardened twice; a third pass wants a retry loop around the tap.

---

### FEATURE: F-ArrangeFold — Arrange hides inside the fold with the list it reorders  [x] COMPLETED

**E's screenshot note, 2026-08-28:** with the life-areas list collapsed, the Arrange button stays
sitting there on its own. It should fold away with the list.

It is a control over the ROWS, so with the section folded its entire effect happens off-screen —
and it is worse than merely useless, because entering Arrange mode force-expands the section, so
tapping it while folded silently undoes the fold the user just chose.

The existing `activeAreas.count >= 2` test stayed and gained a second condition, both now stated
once in `HomeLifeAreasSection.showsArrangeControl(areaCount:isExpanded:)` rather than inline at the
call site. That same force-expansion is what makes hiding it safe: `isExpanded` is true throughout
Arrange mode, so the button — reading "Done" by then — stays on screen as the way back out. There
is no state where this strands someone inside the mode, and a test says so.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 543 files
xcodebuild test (unit)        → Executed 1810 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
```
No journey run: nothing in `ADHD LifeOSUITests` references the Arrange control or the life-areas
list, and `home.lifeAreasCollapsed` defaults to false, so Today looks to them exactly as before.

---

### FEATURE: F-NudgesDoor — the nudges section stops reading as a footer  [x] COMPLETED

**E's screenshot note, 2026-08-28:** the circled nudges area "needs a little bit of work — make it
stand out more and more prominent to the user's eye."

What it was: a grey caps eyebrow ("NOTHING DUE · 4 SCHEDULED") over a grey chevron row, sitting
between a bold ring/streak block and a loud blue "Clear the deck" CTA. It read as the end of the
screen rather than a part of it.

**E's three calls, asked before building:**
1. **Shape** — match the Capture inbox card's anatomy (icon tile, title, subtitle, count chip) and
   list the next few nudges underneath. Chosen over a one-line "next up" and over a louder version
   of the same single row.
2. **Due state** — raise it too. If the quiet state becomes a card, a due nudge sharing that
   surface would read as equally optional, which on this screen is the wrong signal.
3. **Position** — leave it where it is. Folding the life areas already pulls it up the screen.

**What shipped**
- `nudgesDoorCard` mirrors `inboxPeekCard` exactly — same 44pt tinted tile, title, subtitle, chip.
- Rows read "Today 18:00" / "Tomorrow 05:00" / "Mon 09:30", soonest first, capped at
  `maxCards` with "and N more scheduled". Beyond tomorrow the weekday is NAMED — "in 4 days" makes
  the reader do the arithmetic they asked to avoid.
- Due nudges now come FIRST and carry a new `urgentBentoCard` (warn tint + matching border), so
  urgent still visibly outranks quiet.

**Two implementation notes worth keeping**
- **The next-fire maths is dueness's own, not a second copy.** `NudgeDueness.nextFireTime` existed
  but was private; it gained a `nextFire(for:after:)` wrapper rather than a duplicate weekday-walk
  in `HomeNudgesSection`. The two questions genuinely differ and the seam says so: a nudge that
  fired last Tuesday has a next fire in the PAST, which is exactly what makes it due, and is not
  what a user reading "next up" is asking. Display passes `now`; dueness passes the nudge's own
  reference date.
- **The urgent tint is an alpha over the card surface, not a new colorset.** `StateWarn` is already
  the app's single "wants attention" hue (inbox chip, inbox headline, the old nudges eyebrow), and
  a second baked token would be one more thing to keep in agreement with it.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 544 files
xcodebuild build-for-testing  → ** TEST BUILD SUCCEEDED **
xcodebuild test (unit)        → Executed 1827 tests, with 0 failures (0 unexpected)
xcodebuild test (5 journeys)  → Executed 5 tests, with 0 failures (0 unexpected) in 524.424s
```
`testDueNudge_appearsOnHomeAndCanBeDismissed` is the one that matters: it proves the due card still
reaches Today and its dismiss button is still addressable after the cards moved to the top of the
section and changed surface. The journey run was clean first time — no repeat of the
`signOutIfSignedIn` flakiness recorded under F-TriageCardTruth.

**[x] APPROVED BY E ON DEVICE, 2026-08-30.** All four states shot on `wishwashwacky15` at
`b1f4b6f` and archived in `screenshots/nudges-door-device/`:

```
dark-5-due.jpeg          chip "5 due" amber · warn-tinted cards above · "and 2 more due"
light-4-due.jpeg         chip "4 due" amber · same anatomy in the light appearance
dark-nothing-due.jpeg    chip "8 scheduled" neutral · "Nothing due — all on time."
light-nothing-due.jpeg   ditto, light
```

E's verdict: **"Approved — tick it."** The door reads as a card in both appearances, the quiet
state is settled rather than deficient, and the due state visibly outranks it. This was the last
unticked acceptance criterion in the whole file.

**Two things the stills exposed that are NOT this block's**, both now their own entries:
- The three stacked full-width green "Done for now" buttons dominate the due state. E flagged it as
  a secondary concern while approving the door — noted, not actioned here.
- The capture disc obscures real content in **all four** shots. See F-DiscPill.

---

### FEATURE: F-DropAltButton — the composer's second button goes  [x] COMPLETED

**E's call, 2026-08-28, from two device screenshots** ("Retake the photo", "Send to inbox
instead"): "on proper reflection, these buttons need to be removed from all capture types."

One control, five labels — `CaptureComposerCopy.altLabel(for:)` driving a single bordered button
under the CTA in `QuickCaptureView`'s footer:

| Kind  | Label                      | What it did                    | Still reachable without it?          |
|-------|----------------------------|--------------------------------|--------------------------------------|
| note  | Make it a task instead     | switch kind to task            | **No** — see below                   |
| task  | Send to inbox instead      | switch kind to note            | **No** — see below                   |
| voice | Discard and start again    | clear recording, start again   | **Yes** — the record button already reads "Re-record" and `toggleRecording()` nils the URL and restarts. An exact duplicate. |
| photo | Retake the photo           | clear image, open camera       | **Yes** — "Take Photo" and "Choose Photo" are both already on screen |
| link  | Clear the link             | empty the text field           | **Yes** — the field is editable and has a paste button |

So three of the five were pure duplicates of a control sitting inches away, which is very likely
why they read as noise on device.

**The one real loss, stated rather than buried: note ↔ task kind-switching mid-composition is
gone,** and nothing replaces it. Changing your mind now means cancelling and reopening from the
capture fan. That is defensible — the fan is where a kind is chosen, and this button was an odd
hybrid that let the composer contradict the door you came through — and it is the same instinct as
the round-2 audit's "too many places it lives". But it IS a capability that existed this morning
and does not now. If E misses it, the honest replacement is a kind control at the TOP of the
composer next to the title, not a second button in the footer.

Removed all four pieces rather than orphaning any: the button, `altLabel(for:)`, `performAlt()`,
and the two assertions in `CaptureFanTests`. `isShowingCamera` and `CameraCapturePicker` survive —
"Take Photo" still uses them, checked rather than assumed.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 546 files
xcodebuild test (unit)        → Executed 1827 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → exit 0, all targets
```
No journey run: nothing in `ADHD LifeOSUITests` opens the quick-capture composer (the
`composerAreaChip` hits are the capture TRIAGE card, a different screen).

---

### FEATURE: F-PadBalance — the pad stops fighting its own wardrobe  [x] COMPLETED

**E's reframing, 2026-08-28, and it is the thing that finally settled this:** "it would be much
easier to perform a light redesign of the rest of the Journal Card in order to create a balanced
colour scheme … in order to facilitate my request of yellow."

That was correct, and the arithmetic proves why. Asked only to "make the night face more gold", the
ceiling was hard and close: with the parchment ink fixed, `#7A6000` (which E had ALREADY rejected as
mustard) measured 4.67:1, and anything goldier failed AA outright. **The ceiling was a consequence
of the wardrobe, not of the yellow.** A warm page was wearing cool clothes:

| Element | Was | Hue vs goldenrod (43°) |
|---|---|---|
| Selected chips | `AccentColor` `#0A7CFF` | **210° — near-exact complement** |
| Quiet chips | `CardSurfaceSecondary` | ~225°, cool grey |
| Writing box | `CardSurface` (`#1D2027` at night) | ~218°, cool |

**What shipped**
- **`JournalPaperChrome`** — the desk. In LIGHT it is the pad's own gold, so the day face reads
  full-bleed exactly as approved; at night it goes dark and the same structure becomes a lit pad on
  a dark desk. One layout, two appearances, decided entirely in tokens — **there is no
  `colorScheme` branch in the palette and there must not be one.**
- That structural move is what buys the gold: the night pad is a real `#C99A1E` with dark ink,
  reusing the day face's already-proven pairing instead of hunting the mid-tone valley where no ink
  passes.
- **`JournalPaperSurface`** — a warm sheet for the writing box and quiet chips. `CardSurface` was
  only ever half a fix: white by day, but a COOL near-black at night, i.e. the same mistake in the
  other appearance.
- **Monochrome selection** (E's pick): a chosen chip fills with the pad's own ink and labels itself
  in the page gold. No new hue. Per-area tints are suppressed on the pad — eight more hues is the
  last thing a surface with a hue problem needs.
- Four follow-ups from the first render: the Save button (the last cool object), the footer (moved
  to the chrome so the inset pad's bottom corners survive), the placeholder, and "optional".

**Two findings worth more than this block**
1. **There is no dimmed ink on the gold page, and that is arithmetic.** Primary ink clears AA at
   only ~5.2:1, so anything dimmed lands under 4.5 (`#6B4E12` on `#DAA520` = 3.45:1). Hierarchy
   comes from weight and size (§1), never a lighter ink or an opacity (§4). Encoded as
   `softInkAsset(for:)` returning the SAME ink, with the measurement in its doc comment.
2. **The sheet is the one exception**, because the ink clears ~9.5:1 there — which is why the
   placeholder can be `#6B5220` (5.98:1 day / 5.61:1 night) and still pass.

**Blast radius, and how it was contained.** Four shared components across ~20 call sites
(`ChoiceChipButtonStyle` ×7, `PrimaryActionButtonStyle` ×10, `ComposerAreaChips` ×3,
`ComposerSectionHeader` ×3). Every override is OPTIONAL and defaults to nil, so only the pad opts
in — verified by the journeys, not merely argued.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 546 files
xcodebuild test (unit)        → Executed 1831 tests, with 0 failures (0 unexpected)
xcodebuild build-for-testing  → exit 0, all targets
xcodebuild test (5 journeys)  → 4 passed; testCreateTask failed in signOutIfSignedIn setup
                                (UITestSession.swift:102) and PASSED alone in 114.061s —
                                the documented harness flakiness, third occurrence today
```
`testCreateTask` is the journey that walks `TaskCreateView`, which uses BOTH changed chip
components — so its passing is the specific evidence that the nil-default containment holds.

**Superseded:** `F-PadWarmNeutral` below is subsumed by this — the cool `#E9ECF3` chips it existed
to fix are gone from both faces.

---

### FEATURE: F-PadNightRender — put the journal pad's night face in front of E  [x] COMPLETED

**CLOSED 2026-08-28.** The harness was rebuilt from `22dba79`, both faces were rendered in both
appearances with `simctl ui … appearance` driving it explicitly, and E ruled: "make the night face
more gold", then — after seeing the contrast ceiling — "perform a light redesign of the rest of the
Journal Card". That produced `200d0ea` (F-PadBalance) above. The cameras were deleted again at E's
instruction once the judging was done; their four hard-won traps are recorded in
[[journal-pad-design]] rather than in the repo.

**Not a code block — a verification block, and the reason the other three can be judged.** E's
five screenshots were all light appearance, so the gold pad's night face (`9848ee8`) remains the
one thing from 2026-08-28 that no human has seen. It also has the worst track record of anything
in the app: three colour attempts were rejected on device before the render loop was built.

Rebuild the throwaway harness rather than re-deriving it —
`git show 22dba79:"ADHD LifeOSUITests/ComposerLookCaptureUITests.swift"` is the exact file, deleted
in `891ea8f`. Drive the appearance explicitly with `xcrun simctl ui <udid> appearance dark`; do not
trust whichever way the simulator happens to be pointing, because that is precisely what let a
"forced light" pad ship with no night face at all. Let the spring settle before the shutter — a
capture fired mid-animation once showed Log's content on the gold footer and read as an app defect.

**Acceptance criteria**
- [ ] Day and night stills of the journal composer, extracted and handed to E.
- [ ] The harness is deleted again before commit, or committed deliberately — not left behind.
- [ ] E's verdict recorded here before anything else touches the pad's colours.

---

### FEATURE: F-PadOneInk — the pad's one ink stops being half an ink  [x] COMPLETED

**Found by measuring E's device shots of `200d0ea` (2026-08-28, four screenshots: both kinds ×
both appearances), not by reading the code.** The pad's TOKENS were all correct and all clear AA.
What shipped wrong is that most of the page never used them.

**The tokens, verified against the asset catalog and E's actual pixels — these are fine:**

| pair | light | dark |
|---|---|---|
| page (`#DAA520` / `#C99A1E`) + ink (`#4A3506` / `#3D2B05`) | 5.20:1 | 5.25:1 |
| writing sheet (`#F5E7C0` / `#EFE0B4`) + ink | 9.47:1 | 10.34:1 |
| placeholder `#6B5220` on sheet | 5.98:1 | 5.61:1 |
| selected chip label on selected fill | 5.20:1 | 5.25:1 |

The night face is genuinely gold (`#C99A1E`, L=0.356), not the brown 20%-lightness version. The
inset card with near-black gutters at night is intentional and documented. `200d0ea` held.

**Bug 1 — every quiet label on the pad is the ink at HALF alpha, and fails AA.**
`LogComposerView` sets `.foregroundStyle(Color(inkAsset))` once on the container, and its comment
claims `.secondary` inside therefore "turns warm ink instead of system grey". Half true, and the
half that is wrong is the whole defect: under a container whose foreground style is a plain
`Color`, `.secondary` inherits that colour **at roughly half alpha**. It is warm — which is why it
looks fine and why five renders missed it — and it is dimmed.

Measured off E's device, and the blend arithmetic proves the mechanism rather than suggesting it:

- ink `#4A3506` at 50% over `#DAA520` predicts `#926D13`; measured **`#916D12` = 2.13:1**
- ink `#3D2B05` at 50% over `#C99A1E` predicts `#836212`; measured **`#836212` exactly = 2.18:1**

Against a 4.5 bar, on a page where the same ink at full strength clears 5.20:1 / 5.25:1. Affects
"WHAT KIND OF ENTRY?", "ENERGY", "MOOD", "LIFE AREA", "TAGS", the lead caption and the kind
explainer. The tell was visible in one screenshot: "optional" — same component, same line, one
`detailAsset` away — renders the full 5.20:1 while the title beside it renders 2.13:1.

**`JournalComposerPalette.softInkAsset` — the helper written for exactly this, carrying the 5.2:1
reasoning in its doc comment — was DEAD CODE.** No view called it. Worse, its unit test
(`testJournalHasNoSecondaryInk`) passed the entire time, because it asserts the helper returns the
right answer and nothing asserts anyone asks it. A green test guarding an unused function.

It was also unusable in its old shape: it returned `"LabelSecondary"` for a log, and an opaque
`LabelSecondary` is not what `.foregroundStyle(.secondary)` paints — wiring it up would have
restyled the ordinary composer as a side effect. It now returns `String?`, `nil` meaning "keep
exactly what you already do".

**Bug 2 — the energy sublabels dim by alpha, same class of error.** `.opacity(0.7)` on
`level.detail` renders ink at 70% on the parchment chip: predicted `#7D6A3E`, measured **`#7D6A3D`
= 4.27:1**, under the bar by day. Full ink clears 9.47:1 there. The chip's fill already carries
selection, so the dimming bought no signal.

**Bug 3 — the footer caption is a cool grey on gold, and it is LIGHT-ONLY.** `footerBar` hangs off
`.safeAreaInset`, outside the ink container, so it inherits nothing: system `#3C3C43` at 60% over
gold = **2.47:1**. At night it lands on the near-black chrome and measures 6.12:1 — so a dark-only
or a render-only check passes it. It was also the last cool grey left on this screen.

**The trap inside the fix, caught by measuring before shipping rather than after.** The obvious
repair — hand the footer the page ink — is wrong, because the footer sits on the CHROME, not the
page, and the chrome tracks the appearance while the page does not. Page ink `#3D2B05` on the night
chrome `#1A1610` measures **1.33:1**: an invisible line, in the dark half only. Hence a separate
`JournalPaperChromeInk` token (light `#4A3506` = 5.20:1 on gold, dark `#EFE0B4` = 13.71:1 on
near-black). The ink follows the surface.

**Bug 4 — `JournalComposerPalette`'s own doc comments record a night face that does not ship.**
They describe a `#2A2109` page with parchment `#F2E2B8` ink, and a writing box "white by day and
near-black by night". Neither value exists in any colorset; the writing box is warm parchment in
both appearances. This project treats those comments as the measurement record, so a stale one is a
trap for whoever reasons about this screen next. Corrected to what ships, with the rejected
alternative kept and labelled as rejected.

**Acceptance criteria**
- [x] Every quiet label on the pad resolves to the page's one ink at FULL strength — 5.20:1 by day,
      5.25:1 at night — with no alpha anywhere in the chain.
- [x] The footer line takes the CHROME ink, not the page ink, and is legible in both appearances.
- [x] `softInkAsset` is actually called by the view, and returns `nil` for a log so the ordinary
      composer is unchanged BY CONSTRUCTION, not by inspection.
- [x] `TaskCreateView` (5 `ComposerSectionHeader` sites) and the capture triage row
      (`JournalEnergyMoodPicker`) are untouched — every override is optional and defaults to `nil`.
- [x] Tests first, and they must fail for the right reason before the fix.
- [x] The stale night-face doc comments say what actually ships.
- [x] `testCreateTask` is run, because it walks the shared component this block changed.

**Verified 2026-08-28.** The renders here are a MEASURING INSTRUMENT, not a taste check — the
before/after numbers are read out of the pixels with the same sampler, so "it looks fine" never
enters it.

```
swiftlint lint                → Found 2 violations, 0 serious in 544 files
                                (TaskDetailView 438 file_length + UITests static_over_final_class
                                 — the two known debts, no new ones)
xcodebuild build-for-testing  → RED first: "value of type 'ComposerChipPalette' has no member
                                 'softInk'" (3 failures) — the new API, failing for its own reason
xcodebuild test (unit)        → Executed 1836 tests, with 0 failures (0 unexpected)
                                 ** TEST SUCCEEDED **   (1831 baseline + the 5 added here)
xcodebuild test (5 journeys)  → Executed 5 tests, with 2 failures in 544.060s
                                 BOTH failures identical, BOTH at UITestSession.swift:102,
                                 "Settings did not open, so sign-out could never be reached"
re-run in ISOLATION           → testCreateTask ... passed (112.020 seconds)
                                 testTaskDetail ... passed (103.638 seconds)
```

**On those two journey failures — the house rule was followed rather than assumed.** Both are the
documented `signOutIfSignedIn` fragility, in SETUP, before either test reached the screen it tests,
and both pass alone. `UITestSession.swift:94` still taps `settingsButton` ONCE with no retry, so a
swallowed tap surfaces at line 102 as a true statement about the wrong step. That `testCreateTask`
was one of them mattered here more than usual — it is the journey that walks the shared
`ComposerSectionHeader` this block changed — which is exactly why it was re-run alone rather than
waved off. It is green.

**Measured, before → after (E's device shots vs the fixed renders, appearance driven explicitly
with `simctl ui … appearance`):**

| | before | after |
|---|---|---|
| page eyebrows, light | 2.13:1 | **5.20:1** |
| page eyebrows, dark | 2.18:1 | **5.25:1** |
| footer caption, light | 2.47:1 | **5.20:1** |
| footer caption, dark | 6.12:1 | **13.71:1** |
| energy sublabels, light | 4.27:1 | **9.47:1** |
| `#916D12` (50% ink, light) | 11,830 px | **0 px** |
| `#836212` (50% ink, dark) | 12,200 px | **0 px** |
| `#7B6635` / `#979699` (cool grey) | 2,615 px each | **0 px** |

The zero-pixel counts are the strongest evidence here: the dimmed inks are not merely darker, they
are absent from the render entirely.

**Not done, and said out loud:** the journey harness's retry-less tap is untouched. It is the
single biggest source of noise in this suite, it cost a full 9-minute run in this block alone, and
it remains unrelated to any feature — which is precisely why it keeps not getting fixed. It wants
a retry loop around `UITestSession.swift:94`.

### FEATURE: F-PadFooterLift — the night SURROUND stops being a cliff  [x] COMPLETED

**E marked up a device shot of the night pad (2026-08-28)**, drawing round the pinned footer bar:
"it should not be jet black like you have it set currently — I think it should be more easy on the
eye. Currently it's very abrupt to view."

**The app had already answered this question elsewhere, which is what made it decidable.** E's
second screenshot — the ORDINARY composer at night — shows its footer sitting *lighter* than its
page: `#2C2E32` on `#15171C`, a step of **1.32:1**. A lifted pinned bar is the house pattern.

The gold pad was the only screen painting its footer with the DESK (`JournalPaperChrome`
`#1A1610`), which meant stepping **down** from the page by **6.97:1** — five times the house step,
and precisely the cliff E was reacting to. It was not a taste disagreement; the pad was the outlier.

**The fix:** the footer gets its own token rather than borrowing the desk's.
`JournalPaperFooter` dark `#332C20`:

- **1.31:1 lift** off the desk — the ordinary composer's own step, to two decimal places.
- **warm** (hue 38°, in the pad's family) — no cool grey creeps back onto this screen.
- **23% saturation against the ink's 85%**, so it reads as a SURFACE, not as a giant selected chip.
  A more saturated brown at the same luminance would have; contrast ratio cannot see that
  difference, because it only measures luminance — the saturation gap is what separates them.
- The parchment caption still clears **10.51:1** on it; the cream Save button still reads as an
  object sitting on the bar.

Light is byte-identical to the chrome (`#DAA520`), so the day face E approved is untouched **by
construction**, and that was verified rather than asserted: the day render measures the same
`#DAA520` footer at the same 5.20:1, with an identical gold pixel count (1,588,099) to the previous
build, and `#332C20` appears **0 times** in it.

**Second pass, same day + 1 (E, 2026-08-29: "do the header and gutters too").** The first pass
lifted only the bar E had circled and left the header band and side gutters at `#1A1610`. E asked
for the rest, which **collapses the token added an hour earlier**: once the whole surround lifts,
`JournalPaperFooter` and `JournalPaperChrome` can never differ, and two tokens that cannot differ
are drift-bait. So the lift moved INTO the chrome — dark `#1A1610` → `#332C20` — the extra colorset
was deleted, and `footerSurfaceAsset(for:)` now returns the chrome asset. It is kept rather than
inlined only so `testThePadsFooterWearsTheDesk` has something to assert: a future re-split fails
that test and has to write its reasoning down instead of rediscovering it from a screenshot.

Everything on the new desk was re-checked, not assumed: chrome ink / Save button `#EFE0B4`
**10.51:1**, the "New entry" title and Cancel in white **13.80:1**. The pad still reads as an object
on a desk at **5.34:1**, down from a 6.97:1 cliff.

**Acceptance criteria**
- [x] The night footer is a lifted warm surface, not the desk, at the ordinary composer's own step.
- [x] The caption and the Save button stay legible on it (10.51:1).
- [x] The day face is unchanged — verified by measurement, not assumed.
- [x] Failing test first.

**Verified 2026-08-28:**
```
swiftlint lint                → Found 2 violations, 0 serious in 545 files (the two known debts;
                                 a line_length violation this block introduced was FIXED, not kept)
xcodebuild build-for-testing  → RED first: "type 'JournalComposerPalette' has no member
                                 'footerSurfaceAsset'"
xcodebuild test               → Executed 1838 tests, with 0 failures (0 unexpected)
                                 ** TEST SUCCEEDED **   (1836 + the 2 added here)
renders, both appearances     → FIRST pass:  night footer #332C20, caption 10.51:1
                                 SECOND pass: #1A1610 present 0 px anywhere in the night render —
                                 header band, side gutters and footer all measure #332C20
                                 day face: #332C20 and #1A1610 both 0 px, footer still
                                 #DAA520 at 5.20:1
```

**One honest note on the day-face check.** The gold pixel count moved between the two day renders
(1,588,099 → 1,666,031) and the distinct-colour count fell. That is **seed data, not this change**:
the second run's emulator account had no life areas and no tags, so the LIFE AREA section was absent
entirely and TAGS rendered as just its empty field — fewer chips means more exposed gold and far
fewer distinct colours, since the area chips carry emoji. The colour facts that actually matter are
unaffected and were each checked by value rather than by total: page `#DAA520`, footer 5.20:1, and
both night-only values absent. Worth recording because a raw pixel count is only a valid before/
after comparison when the seeded content is identical, which across emulator runs it is not.

---

### FEATURE: F-JournalRowMood — the mood stops floating beside a wrapped line  [x] COMPLETED

**E's device shot, 2026-08-29: "a bug relating to the positioning of the mood ratings on entries."**
The 2:06am row read `Journal · 💬 Relationships ·` / `at Home 📍` with `😴  low` hanging off to the
right of neither line.

**Three defects in one row, and the third explains the other two.**

1. **The layout.** `logRow` put the context line, the mood and the energy chip in one
   `HStack(spacing: 4)`. That reserved a trailing column, so the context wrapped even though the
   card was wide enough for it — orphaning a `·` at the end of the first line — and an `HStack`
   centres by default, so against a two-line context the pair floated at neither line's height.
2. **The wrong label.** It rendered `energy.rawValue` — `"low"` — where `EnergyLevel.chipLabel` is
   `"low energy"`. That property's own doc comment reads *"The journal list's chip, mirroring the
   web's `{entry.energyLevel} energy`"*, and the journal list was the one place not using it. It is
   already unit-tested (`LogEnergyMoodTests:50`); only the view ignored it.
3. **`JournalEnergyMoodBadge` — "the read-only counterpart: how a written entry shows what it was
   written with" — existed and was used NOWHERE**, while this row hand-rolled its own copy. That is
   the THIRD time this exact shape has cost something here: `CaptureRowPresentation.primaryText`
   (blank photo card, `eddef9b`) and `softInkAsset` (dimmed pad labels, `fff08b9`) were the first
   two. The hand-rolled copy also dropped the badge's `accessibilityLabel("Mood …")` and its
   `.combine`, so VoiceOver read a bare emoji as its own element.

**The fix:** the context line gets the whole width, and the shared badge sits on its own row beneath
it. Nothing has to be aligned to anything, so neither failure mode can return.

**A fourth defect the fix CREATED, caught only by putting it on screen.** The badge was a
`Label(chipLabel, systemImage: "bolt.fill")`, and the bolt landed immediately beside the mood emoji
— where `JournalMood.defaultEmoji` is ⚡, so the COMMON case rendered **"⚡ ⚡ medium energy"**. The
glyph was dropped: `chipLabel` already spells the word "energy", so it duplicated rather than
informed, and `.combine` is what was really doing the VoiceOver work. This is only visible in a
render — no unit test can see it — which is the argument for rendering every view change.

**Acceptance criteria**
- [x] The mood and energy sit in a fixed place that cannot depend on whether the context wrapped.
- [x] The energy reads `chipLabel` ("low energy"), matching the web and the shared badge.
- [x] The row uses `JournalEnergyMoodBadge` rather than a fourth hand-rolled copy, so it inherits
      the VoiceOver labelling too.
- [x] An entry with neither field is unchanged (the badge renders nothing).

**Honestly stated: no new unit test.** The defect lives entirely in a SwiftUI body, and the model
guarantee it violated (`chipLabel`) was already tested. Verified by render instead, in dark
appearance, via a throwaway camera that was deleted afterwards.

**The camera lied once first, and it is the documented trap again.** Its first version looked for
`app.textViews["logComposerBodyField"]` — but `ComposerTextBox` is a `TextField` with
`axis: .vertical`, so it silently matched nothing, left the body empty, left Save disabled, and
photographed the composer it never left. **It PASSED while doing so.** The rebuilt version asserts
Save is enabled, waits for the composer to stop existing, and asserts the timeline is back before
the shutter.

**Verified 2026-08-29:**
```
swiftlint lint  → Found 2 violations, 0 serious in 544 files (the two known debts; none introduced)
xcodebuild test → Executed 1838 tests, with 0 failures (0 unexpected)  ** TEST SUCCEEDED **
render (dark)   → "Journal · 🫀 Health" / "⚡ medium energy" / body — context on its own line,
                   badge beneath it, one bolt, correct label
```

---

### FEATURE: F-JournalJourney — the Journal tab gets a journey, and it asserts LAYOUT  [x] COMPLETED

**Closes both caveats E called out on `e7c5b7c`:** that fix had no test that runs, and it was
verified by a throwaway camera that was deleted afterwards.

**The journey asserts GEOMETRY, not existence — and that distinction is the whole point.** An
existence check would have PASSED on the broken build: the badge was on screen the entire time,
just beside the context line instead of below it.

```
1. badge.frame.minY >= context.frame.maxY - 2   below, not beside
2. badge.frame.minX == context.frame.minX ± 2   same left edge, not pushed trailing
3. badge.label contains "energy"                chipLabel, not the bare rawValue
```

**Proved by deliberate regression, not asserted.** Reintroducing the exact `HStack` from E's
screenshot makes it fail with the right message:

```
XCTAssertGreaterThanOrEqual failed: ("270.0") is less than ("283.66666666666663")
  - The mood/energy badge overlaps the context line's row — it is beside it, not below it
```

Working code was committed (`f4b84e1`) BEFORE that regression, restored with `git checkout --`, and
the restore proved by re-running rather than by inspection — per [[never-destroy-uncommitted-work]].

**The retry loop finally landed, and only because it blocked this.** After restoring, the journey
failed with "No compose button" — the tab tap swallowed while Today was still settling. That is the
same single-unretried-tap weakness flagged for `settingsButton` across four false failures on
2026-08-28. **A guard that fails randomly is not a guard**, so `UITestSession.tap(_:untilExists:)`
now retries and is wired into both this journey and `signOutIfSignedIn`. The duplicate assertion
that used to follow the settings tap is deleted rather than left as a second copy of the same fact.

Evidence it worked: in the six-journey run, **all four journeys that historically flaked in
`signOutIfSignedIn` passed** — `testCreateTask`, `testSettings`, `testTaskDetail`, `testDueNudge`.

**Two traps this produced, both new angles on known ones:**
- `.accessibilityElement(children: .combine)` publishes one element whose **TYPE is not
  guaranteed**. Querying `otherElements` found nothing while the badge was plainly on screen; the
  first run failed with "No energy/mood badge" for exactly that. The query is
  `descendants(matching: .any)`.
- Lint flagged the new journey twice — `SignedInJourneyUITests` file_length 409 and a
  function_body_length of 52. **Both were FIXED, not accepted**: the journey moved to its own
  `JournalJourneyUITests` class and its body split across a `writeAJournalEntry` helper.

**Acceptance criteria**
- [x] The Journal tab has a journey that runs, closing a documented gap.
- [x] It fails on the actual defect, proved by reintroducing it.
- [x] The retry loop exists and is used by the call site with the known history.
- [x] No new lint debt.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 2 violations, 0 serious in 545 files (the two known debts)
xcodebuild test (unit)  → Executed 1838 tests, with 0 failures (0 unexpected)
journey (red check)     → FAILS on the reintroduced bug, with the geometry message above
journey (restored)      → Executed 1 test, with 0 failures (0 unexpected)
six journeys            → Executed 6 tests, with 1 failure in 695.723s
                          the 1 = testCapturesTab, and it is NOT this change — see below
```

**[OPEN, and separate] `testCapturesTab` has a SEEDING race, distinct from the tap race just
fixed.** Across three runs it failed twice with two DIFFERENT messages — "No life-area chips"
(`SignedInJourneyUITests:283`) and "The decision card rendered a wordless capture as a blank"
(`SignedInJourneySupport:88`) — and passed on the third, in isolation. Both messages are about
seeded content not being present yet, not about a tap.

It is **not** caused by this work: it passed in the five-journey run at `fff08b9` this morning, and
nothing since touches the capture inbox (`c864c1c`/`78053ce` are colour tokens; `e7c5b7c`/`f4b84e1`
touch the journal timeline row). Independent corroboration: a composer render taken at `fff08b9`,
before any journey change, showed **no life areas and no tags at all** — the same symptom, from
before this branch of work. The seed evidently does not always complete before the UI reads it.
`tap(_:untilExists:)` cannot help here; this wants the journey to wait on seeded content.

---

### FEATURE: F-AccountName — a name you can actually set  [x] COMPLETED

**Settings' Name row is correct code that E will never see fire.** `SettingsView.swift:190` is
`if let name = authService.signedInUser?.displayName`, so the row hides when there is no name —
right behaviour. But the name is written ONCE, at sign-up, and nothing anywhere can set it
afterwards.

Verified live rather than assumed (Firebase MCP, 2026-08-28): E's Auth record
`xcKeMrUiFoZRGQOEUMNW8y6aXmc2` was created **2026-08-19 02:22 UTC**, nine days before F-DisplayName
(`9c3418a`), and carries no `displayName` field at all. Its Firestore `users/{uid}` document holds
only `seeded_at` — not even the `email` that the current `signUp` always writes — so the document
predates that code path entirely. Nothing is broken; the feature is simply unreachable on the only
account that matters.

Note while implementing: `signUp` writes the name TWO places — onto the Firebase Auth user
(`commitChanges`, swallowed with `try?`) and into `users/{uid}.display_name`. Everything that
READS it reads only the Auth user (`FirebaseManager.swift:98`). A silently-failed `commitChanges`
would therefore leave a name in Firestore that the app can never show. Whatever this block adds
should not repeat that split.

**Acceptance criteria**
- [x] A name is editable from Settings' Account section, not only at sign-up.
- [x] The write lands somewhere the app actually reads back, and a failure is reported rather than
      swallowed.
- [x] Setting a name on an account that has never had one makes the Name row appear.
- [x] Clearing it removes the row rather than showing a blank value.
- [x] Tests first for the pure validation/normalisation; `AuthFormValidation.normalizedDisplayName`
      already exists and should be the one rule.

**How the note above was honoured.** It warned that `signUp` writes the name TWO places (the Auth
user via `commitChanges`, swallowed with `try?`, and `users/{uid}.display_name`) while everything
that READS it reads only the Auth user — so a silently-failed commit leaves a name in Firestore the
app can never show. This does not repeat that: `FirebaseManager.updateDisplayName` writes **only
what is read**, and **throws**. The Firestore copy stays a legacy artefact of sign-up, documented as
unmaintained rather than quietly written to a second time.

`AuthService.updateDisplayName` takes the user BACK from the client rather than patching `state`
locally, so a failed write leaves the displayed name untouched instead of lying about the server.
`displayNameUpdateFailed` is its own error case for the same reason.

**The UI keeps the "no row when there is no name" rule** the Account section already documented —
what was missing was a way IN when it is hidden, which is why the row could never appear on E's own
account. So: the value row when set (tappable to rename), an "Add your name" button when not.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 2 violations, 0 serious (the two known debts; five that THIS block
                           introduced in its own test file were fixed, not accepted)
xcodebuild test (unit)  → Executed 1843 tests, with 0 failures (0 unexpected)
                           (1838 + the 5 written first here)
journey                 → AccountNameJourneyUITests passed (170.289s) — sets a name on an account
                           that never had one, asserts the row appears, clears it, asserts it goes
```

**Three harness truths this cost, each found by a failing run rather than by reasoning:**
- A `Form` row below the fold does not EXIST to XCUITest, so `waitForExistence` waits for something
  that will never arrive. It must be scrolled into being.
- An alert is its own element tree: its text field is not reliably reachable from `app.textFields`.
  Querying the app found nothing and reported "the alert never opened" about an alert that had.
- **An alert's Save tap gets swallowed like any other tap**, and when it does the alert just stays
  up — surfacing several steps later as "the Name row did not appear", about a row never asked for.
  A screenshot was the only thing that said otherwise. `UITestSession.tap(_:untilGone:)` is the
  mirror of `tap(_:untilExists:)` and now covers it.

---

### FEATURE: F-DiscClearance — the capture disc stops sitting on the last row  [x] COMPLETED

**One defect E reported, and the nine other screens that had it.** The FAB overlaps the nudges
door's last row — `nudgesNewNudgeRow`, a full-width 54pt button that is the ONLY way to create a
nudge, with nothing below it to scroll to. So the disc sat on it permanently.

**`CaptureDiscMetrics.clearance` already existed and already said this would happen.** Its doc
comment, written 2026-08-25: *"The FAB is a fixed overlay above the tab bar, so ANY pinned bar or
bottom-of-scroll content lands underneath it."* Ten screens render inside the `TabView` the disc
overlays. **Two called it.** That is [[dead-shared-component-pattern]] for the fourth time — a
helper written, documented, unit-tested, and not called — and the standing lesson from `a943988`
is that a fix for a class goes to every member, not to the one that happened to be reported.

**Acceptance criteria**
- [x] One shared modifier, `.captureDiscClearance()`, and exactly one spelling of the vertical
      clearance in the whole tree. `CaptureInboxView`'s hand-rolled
      `padding(.bottom, CaptureDiscMetrics.clearance)` — the only site that had it — converted.
- [x] Applied to every screen under the disc: the five tab roots and everything pushed into their
      navigation stacks. Sheets and full-screen covers excluded — they cover the disc entirely.
- [x] `safeAreaInset`, not padding, so ONE spelling serves `ScrollView`, `Form` and `List` alike;
      a `Form`'s rows are not ours to pad. Non-hit-testable, or the reserved strip would swallow
      the taps it exists to restore.
- [x] Tests written first, both red.
- [x] `TaskDetailView` split — it was at 438/400 before this touched it, and the standing rule is
      that the next feature touching it splits it.

**The two exclusions are measured, not missed — both are recorded in the call-site test itself.**
- **`JournalTimelineSections`.** Its composer bar is a `safeAreaInset(edge: .bottom)` that already
  occupies the disc's band, and already carries the TRAILING half of the same clearance
  (`JournalView.captureDiscClearance`). Adding the vertical form on top would open a dead 84pt gap
  under a screen that has been through six colour and layout passes.
- **`LifeAreaEditorListView`.** Pushed from Areas (under the disc) AND presented inside Settings (a
  sheet, above it). The clearance is a property of the PRESENTATION, not of the screen, so
  `AreasView` applies it at its call site and Settings' copy is untouched.

**A call-site test, which is unusual here and deliberate.** The unit suite cannot see this defect
class: the helper is correct in every one of these bugs, and a SwiftUI body is not reachable from
XCTest. So `CaptureDiscClearanceCallSiteTests` reads the SOURCE — the layer the claim lives in —
and asserts three things: every screen under the disc calls the modifier; nobody hand-rolls the
bottom form; the trailing form has not quietly collapsed into it. It is honest about its limit in
its own header: it does not catch a brand-new screen, because a list of ten that is wrong loudly
beats a classifier that is wrong quietly. The geometry itself is asserted on two representative
screens — one pushed, one tab root — by `CaptureDiscClearanceUITests`, which measures the disc's
OWN frame rather than trusting a constant copied into the UI test target.

**Verified 2026-08-29:**
```
swiftlint lint          → Found 0 violations, 0 serious in 550 files
                           (was EXACTLY TWO: TaskDetailView file_length 438, and the UITests
                            static_over_final_class. Both cleared, none introduced.)
xcodebuild test (unit)  → Executed 1846 tests, with 0 failures (0 unexpected)
                           ** TEST SUCCEEDED **   (1843 + the 3 written first here)
journeys (all, alone)   → Executed 12 tests, with 2 failures
                           9/9 JOURNEYS PASSED, including the two new ones.
                           The 2 failures are ADHD_LifeOSUITests' old login-form tests, and they
                           are an ordering artefact, PROVEN not asserted: they fail because a
                           preceding signed-in journey leaves a Firebase Auth session in the
                           simulator keychain, so the app restores into the tabs and the login
                           field never appears. After `xcrun simctl keychain booted reset` both
                           pass (27.2s / 25.1s). Nothing in this block touches auth or LoginView.
```

**The red-check, and what it found — this is the part worth reading.**

The geometry journey **passed against a build with the fix deliberately removed.** It was worthless
as written, and only the red-check said so. Three faults, none of which reasoning would have caught:

1. **It never scrolled, because the screen never filled.** One seeded nudge left the New nudge row
   at y=308 against a disc at y=728 — 420pt apart, an assertion that could not fire whatever the
   code did. It seeds TEN now, so the screen scrolls the way E's did.
2. **The arrival landmark was the row being measured.** `tap(door, untilExists: nudgesNewNudgeRow)`
   waits for a row below the fold on the screen it just opened, and reported "the nudges door never
   opened" about a door that had opened fine.
3. **Waiting for existence before scrolling, twice.** Both screens are `LazyVStack`s; below the fold
   a row is not merely unhittable, it is ABSENT, so `waitForExistence` waits out its full 45s.

Frames are now traced on PASS as well as failure, because an assertion that only speaks when it
fails cannot be checked for vacuity. Measured, both ways:

```
BROKEN   nudges row (16, 720.7, 370, 54)  vs disc (326, 728, 60, 60)  → 46.7pt underneath
         today  row (16, 683.0, 370, 76)  vs disc (326, 728, 60, 60)  → 31.0pt underneath
FIXED    nudges row (16, 636.7, 370, 54)  → clear
         today  row (16, 599.0, 370, 76)  → clear
         both moved exactly 84pt = CaptureDiscMetrics.clearance
```

Restored with `git checkout --` and proven by REBUILDING, not assumed.

**Rendered and looked at** (`screenshots/disc-clearance-block/`), because two defects on 2026-08-29
were introduced BY a fix and invisible to every test. Today, the nudges screen, the task detail
`Form` and the Journal control all render correctly; the Journal shot is the evidence its exclusion
was right — its composer bar sits directly above the tab bar with the disc in the space its
TRAILING padding makes, and 84pt of vertical clearance would have opened a dead gap under it.


---

### FEATURE: F-PadWarmNeutral — the gold pad stops using a cold grey  [x] SUPERSEDED by F-PadBalance

**Do not work this block.** `200d0ea` replaced every cool surface on the pad — the `#E9ECF3` chips
this block existed to fix, the writing box, the disabled Save button — with the warm
`JournalPaperSurface` wardrobe, in BOTH appearances. Kept for the reasoning only.

**Taste, and explicitly E's call — render before committing.** On the gold composer the unselected
life-area chips and the disabled "Save entry" button are both `CardSurfaceSecondary` = **#E9ECF3**,
an opaque BLUE-leaning grey. F-DisabledCTA (`22dba79`) did its job — the button is no longer a
translucent system fill picking up the gold — but a cold grey on a saturated warm ground is what
makes those chips read dead and slightly dirty in E's screenshot. The same token looks right
everywhere else in the app because every other page is already cool grey.

The pad has warm ink for its labels and cool grey for its surfaces; it should pick one.

**Acceptance criteria**
- [ ] A warm quiet-surface token for the gold page, in the asset catalog with light AND dark
      variants — never inline hex, per CLAUDE.md §4.
- [ ] Contrast checked in BOTH appearances, not just the one the simulator opened in.
- [ ] Rendered and shown to E BEFORE commit. Three colour attempts were rejected on device by
      guessing; this one does not get guessed.
- [ ] Nothing outside the gold composer changes appearance.

---

**The history moved.** Every shipped block and every block belonging to a deleted backend now lives
in `TODO-ARCHIVE.md` — 8,183 lines of it, covering the Supabase, Cognito/AWS and Poke eras, all of
which were removed from the app in `5244650`. It was moved rather than deleted: the reasoning in
those blocks is often the only record of why something is the way it is, and several carry
verification trails worth keeping. Nothing in the archive is a work item.

---

## FIX: Task Due-Time Nudge notifications show no app icon in the banner  [x] VERIFIED 2026-08-23

**CLOSED — E confirmed on a physical iPhone 15 Pro, 2026-08-23.** The banner now renders the app
icon (purple gradient, white arc-and-dot), matching `AppIcon-1024.png`, so it is the real icon and
not a system fallback.

Verified against a build of `main` installed that day via `devicectl`, specifically so a stale
device build could not produce a false negative — the git history for `AppIcon.appiconset` does not
show the July `sips` commit this block describes, so which build first carried the small renditions
could not be established from history alone. `assetutil --info` on that build's compiled
`Assets.car` reports discrete 60×60, 87×87, 120×120 and 180×180 AppIcon renditions alongside the
1024×1024 marketing icon.

The test went wider than the criterion required. A task due in 6 minutes with 2 countdown nudges
produced three notifications, all showing the icon:

  +2 min     "This task is due soon."   countdown nudge
  +4 min     "This task is due soon."   countdown nudge
  due time   "This task is due now."    due-moment notification

So both notification features are covered, on the lock screen and in Notification Centre. The
original diagnosis holds: the notification-banner icon path needs the classic small renditions,
which the Xcode-14+ single-size format alone does not provide.

---

**Original block follows, unedited apart from the ticked criterion:**


**Context:** Reported 2026-07-21 by E on a physical iPhone — a Task Due-Time Nudge (local
notification) banner displayed with no app icon, while the Home Screen and App Switcher icons
both rendered correctly. Investigated via `assetutil --info` against the compiled `Assets.car`:
`AppIcon.appiconset/Contents.json` used only the modern Xcode-14+ "single size" format (one
1024×1024 marketing image + dark/tinted variants, `idiom: universal`) with zero classic small
icon renditions (20/29/40/60pt). The compiled catalog's `AppIcon` asset showed only a single
1024×1024 "MultiSized Image" entry with no smaller pre-rendered sizes. Home Screen/App Switcher
render fine from this format, but the on-device notification-banner icon path is known to fail
silently without the classic small renditions present in the catalog.

**Fix (additive, no code change):** generated the eight classic iPhone icon sizes (20/29/40/60pt
at @2x/@3x) from the existing `AppIcon-1024.png` via `sips`, and added them to
`Contents.json` as `idiom: iphone` entries alongside the existing `universal` marketing-icon
entries. Confirmed via `assetutil --info` that the rebuilt `Assets.car` now contains discrete
20×20/29×29/40×40/60×60pt renditions (previously only the single 1024×1024 rendition existed).

**Acceptance Criteria:**
- [x] `AppIcon.appiconset` contains classic `idiom: iphone` renditions at 20/29/40/60pt
      (@2x/@3x), generated from the existing 1024px source — no new marketing artwork needed.
- [x] `xcodebuild build` for the physical device succeeds and signs cleanly (no asset-catalog
      compiler errors from mixing `universal` and `iphone` idiom entries in one appiconset).
- [x] Rebuilt app installed and launched on E's physical iPhone via `devicectl` for retest.
- [x] **E confirmed on device 2026-08-23**: icon renders in the banner. See the verification note
      at the top of this block.

**Implementation Checklist:**
- [x] Generate `AppIcon-20@2x.png`, `AppIcon-20@3x.png`, `AppIcon-29@2x.png`,
      `AppIcon-29@3x.png`, `AppIcon-40@2x.png`, `AppIcon-40@3x.png`, `AppIcon-60@2x.png`,
      `AppIcon-60@3x.png` via `sips` from `AppIcon-1024.png`.
- [x] Add corresponding `idiom: iphone` entries to `Contents.json`.
- [x] Run: `swiftlint lint` — no Swift touched, confirmed no new violations.
- [x] Run: `xcodebuild build ...` for the physical device — confirmed signed build succeeds.
- [x] Verify via `assetutil --info` on the compiled `Assets.car` that the small renditions are
      actually present post-build (not just declared in `Contents.json`).
- [x] Install + launch on E's physical iPhone via `devicectl` for on-device retest.

**Dependencies:**
- Needs: nothing (asset-only fix, no Swift/architecture change).
- Blocks: nothing — Task Due-Time Nudges (the feature this bug affects) already shipped;
  this is a visual-polish fix to its notification banner.

**Notes:**
- This is a plausible, well-supported diagnosis (documented real-device behavior difference
  between the single-size and classic app-icon formats specifically for the notification-banner
  icon path) but not 100% confirmed until E sees an actual nudge fire post-fix — flagged as an
  open acceptance criterion above rather than claimed as verified.
- No iPad-idiom small icons were added — the reported bug and E's test device are iPhone-only;
  `TARGETED_DEVICE_FAMILY` includes iPad (`"1,2"`) but the app has no iPad testing history yet,
  so adding iPad icon renditions here would be unrequested scope creep. Revisit if iPad testing
  ever surfaces the same notification-icon gap there.

---

## KNOWN ISSUE: Flaky sign-in UI tests on this machine (LARGELY EXPIRED — read the 2026-08-23 note first)

**Status 2026-08-23: mostly overtaken by events, kept for the diagnosis rather than the task.** The
suite this describes no longer exists. It reports 4 of 10 UI tests failing intermittently; there are
now 4 UI tests in `ADHD_LifeOSUITests` (one a launch-performance measurement), and of the three named
below, two were DELETED in the 2026-08-19 slimming —
`testCreateTask_fromTasksTab_appearsInList` and `testTaskDetail_opensWithTitleFieldPopulated_notBlank`
went with the Supabase credentials they depended on. Both have since been rebuilt against the
Firebase emulator in `SignedInJourneyUITests`, where they pass consistently (four journeys, four
passes, ~90s each).

What is still worth keeping is the DIAGNOSIS: these failures were traced to simulator/host resource
pressure on this specific Mac, not to app code. If UI tests start failing oddly, check
`sysctl vm.swapusage` before blaming a commit — a 2026-08-23 session found swap at 2.5GB of 4GB
while running the Firebase emulator's two JVMs alongside Xcode.

The one item never actioned: the 15s timeouts on the older tests were flagged twice as too short for
this machine. The new journeys use 45s throughout (`UITestSession.timeout`) and have not flaked.

**Original entry follows, unedited:**

### KNOWN ISSUE: Flaky sign-in UI tests on this machine (2 sessions running, unresolved)

**Not a code bug — logged so a future session doesn't re-diagnose it from scratch.** Across two
separate sessions (2026-07-20, 2026-07-21), `xcodebuild test`'s full UI test suite has
intermittently failed 4 of 10 `ADHD_LifeOSUITests` — always at the same point: `loginEmailField`
(or an equally early post-launch element) never appears within its wait timeout (tried up to 45s).
Which 4 tests fail is non-deterministic between runs (e.g. `testLoginForm_...` failed in the
2026-07-21 rerun after passing in the prior run). Unit tests (`ADHD LifeOSTests`, 212/212) are
unaffected and pass every time. Root cause investigated and narrowed to iOS Simulator
network/resource flakiness on this specific Mac (low free RAM + swap pressure at the time of both
failing runs; host-level `curl` to the same Supabase endpoint is consistently fast) — not the
app's sign-in code, not `TaskDetailView`'s `.onAppear` fix (whose regression test,
`testTaskDetail_opensWithTitleFieldPopulated_notBlank`, is one of the intermittently-affected
tests, meaning it has never yet cleanly exercised the code it's meant to verify). Full diagnostic
trail: `git log` for `COWORK-HANDOFF-TaskDetailView-Fix.md`'s content (deleted after triage, see
git history if needed). If this resurfaces: check `vm_stat`/`sysctl vm.swapusage` before blaming
code, and consider whether the 15s timeouts on the 3 older affected tests
(`testCreateTask_fromTasksTab_appearsInList`, `testLoginForm_rendersFieldsAndValidatesInput`,
`testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm`) are worth bumping to the
file's own 45s convention — flagged twice now, not yet done without E's go-ahead.

---

## RESOLVED: Home's due-nudge dismiss buttons share one accessibility identifier  [x] FIXED 2026-08-23

**Fixed by giving each Dismiss button a per-nudge accessibility LABEL** (`"Dismiss Stretch your
back"`), leaving the identifiers untouched. `testDueNudge_appearsOnHomeAndCanBeDismissed` passes and
is no longer skipped; all four signed-in journeys are green.

The underlying defect is real and REMAINS: `dueNudgesStrip` puts
`.accessibilityIdentifier("homeDueNudgesStrip")` on the enclosing `VStack`, and SwiftUI pushes that
down over the subtree, so every per-nudge `homeDueNudgeDismissButton-<id>` is overwritten and the
buttons cannot be told apart by id. Confirmed from the accessibility tree:

```
Button, 0x113186bc0, {{310.7, 997.0}, {59.3, 20.3}}, identifier: 'homeDueNudgesStrip', label: 'Dismiss'
```

The label fix routes around it and is a genuine VoiceOver improvement in its own right — a row of
buttons all reading "Dismiss" tells a VoiceOver user nothing about which nudge they are acting on,
since the visible label lives in a separate element. The dead per-nudge identifiers are left in
place rather than removed; they cost nothing and document the intent.

**CORRECTION to an earlier claim in this file's history:** an intermediate version of this block
stated that removing the stack's identifier, or adding `.accessibilityElement(children: .contain)`,
CRASHES the app. **That was wrong.** It came from manual `simctl` runs that were confounded three
separate ways — a stale AWS-era build picked out of one of five DerivedData directories, an
unverified sign-in state, and a keychain session that survived `simctl uninstall` so the app was
signed in as a different account than the one being seeded. Nothing here crashes. If you need to
verify app behaviour, drive it through the XCUITest harness, which controls account state, rather
than by hand.

