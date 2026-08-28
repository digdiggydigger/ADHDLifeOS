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

**[ ] OUTSTANDING — E has not seen it.** This is taste, and the standing lesson is that three
colour attempts were rejected on device before a render loop existed. Stills of both states in both
appearances go to E before this is called settled.

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

### FEATURE: F-AccountName — a name you can actually set  [ ] UNCHECKED

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
- [ ] A name is editable from Settings' Account section, not only at sign-up.
- [ ] The write lands somewhere the app actually reads back, and a failure is reported rather than
      swallowed.
- [ ] Setting a name on an account that has never had one makes the Name row appear.
- [ ] Clearing it removes the row rather than showing a blank value.
- [ ] Tests first for the pure validation/normalisation; `AuthFormValidation.normalizedDisplayName`
      already exists and should be the one rule.

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

