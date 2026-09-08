# The tab bar, reopened — C "Select Pill" at rest, B "Bento Bar" scrolled (design record, 2026-09-08)

*Written by the session that built it, off `main` @ `e5a572f`, branch `feature/tabbar-select-pill`.
This is the design record and the why — the sibling of `SESSION-OPENER-tools-tab.md`, which it
partly supersedes. It is a `SESSION-OPENER-*` file: permanent, never archived (CLAUDE.md,
"Session handoff").*

**Status: ROUND 2 BUILT, on the branch, awaiting E's second device verdict.** Round 1 (C on the
flat pane) was judged on the phone and corrected the same night — see "Round 2" at the bottom,
which supersedes the pane wherever the sections below still mention it. Block
`F-TabBar-SelectPill` in `TODO-CLAUDE-CODE.md` (⚠ CLAUDE CODE ADDITIONS) is the tickable
summary. The PR (#29) merges only after E has looked — the sanctioned open-PR exception in
CLAUDE.md's "Landing".

**The canvas E judged from, again:**
`https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9` — page **"All six
options"**. The same canvas the 2026-09-02 pick came from; nothing new was drawn.

## What E decided (verbatim, 2026-09-08)

E opened the new-features session by saying they wanted to "reopen the edits to the app's
Navigation bar", pointed at the canvas, and asked to look at the "All six options" page.

1. *"From that artifact, I want to combine suggestion b and suggestion c."*
2. Asked whether the combination was the bar's one look or still changed on scroll:
   *"I want **C** to be the resting state when the user is at the top of the page. When they
   scroll I want to stay as **B**."* (E typed "see" for C.)
3. The reading below was put back to E in full and answered **"Yes, exactly that."**

So the bar now reads:

| state | design | what it is |
|---|---|---|
| **At rest** — the page near its top | **C · Select Pill** | Flat, full-width, opaque pane (unchanged). Icons only — except the **selected tab, which is a tinted pill holding its glyph AND its label**. The other five give up width to it. |
| **Scrolled** | **B · Bento Bar** | The floating card with the icon-only tinted chip. **Unchanged** from F-Tools-2-Morph. |

**F "Minimal Dot" is retired.** The 2026-09-02 decision "the indicator morphs dot → chip" is
superseded: the morph is now **the pill contracting into the chip** — one shape at two widths,
the label collapsing and nothing else.

## What did NOT change, and why that is the whole trick

- **The trigger.** `TabBarScrollActivity` was already a *position* rule with hysteresis
  (float past 24pt from the top, restore within 8pt), not the "momentary" timer the 2026-09-02
  plan feared it would need. That is exactly E's "at the top of the page → C, scrolled → stay
  as B". Nothing in it moved; its 11 tests are untouched.
- **The band.** `rowHeight` is derived — chip 34 + padding 16 + lift 8 = **58pt** — and the
  pill is the chip's height, so the resting pane and the floating card still cover an identical
  footprint. Everything built on that band — the search row's 90pt lift, the disc's 158pt
  `bottomClearance`, `appTabBarClearance()` on Journal and Captures — is unchanged.
- **The pane.** C's artboard draws the same opaque `CardSurface` plane with a 1pt `CardBorder`
  top edge that F shipped after two material rounds failed in light mode. Every verdict E gave
  on that pane still stands.
- **The identifiers and traits.** `tabBar.<Label>` per button, `.isSelected` — so every UI
  journey's `openTab` keeps working without edits.
- **The badge.** Still an overlay on the tray glyph, so on the labelled Captures pill it sits
  where C drew it.

## The numbers, and why

All in `AppTabBarMetrics` / `AppTabBarPresentation` (`ADHD LifeOS/Theme/`), pinned by
`AppTabBarPresentationTests` (27 tests in the class; 5 new, 1 rewritten).

| constant | value | why |
|---|---|---|
| `restingPaddingHorizontal` | **8** | C's own side padding, so an end tab's pill is never flush to the screen edge. The resting slots used to run edge to edge. |
| `pillPaddingHorizontal` | **8** | C drew **10**. Off the 4/8/16/24 grid; §2 beats the concept (CLAUDE.md §7). |
| `pillGlyphToLabelSpacing` | **8** | C drew **6**. Same. |
| `maximumRestingPillWidth` | **128** | Turns §3's floor into arithmetic: (375 − 2·8 − 128) / 5 = **46.2 ≥ 44** on the SE, whatever the label measures. "Captures" needs ~99pt at default and ~122 at the bar's xxxLarge clamp, so the cap only ever bites at the top of the range, where the label's `minimumScaleFactor(0.8)` absorbs it. |
| pill height | **34** = `chipHeight` | So the morph is width-only. C drew a 44-tall pill (the whole button); the slot's 44pt target is kept by `contentShape`, the pill itself is the chip's size. **Tunable, awaiting E.** |
| pill corner radius | **11** = `chipCornerRadius` | One shape at two widths. A full capsule (17) is the alternative. **Tunable, awaiting E.** |
| label | `.caption` semibold, accent | C's 12pt/600, semantic so Dynamic Type moves it; one line, scales before it clips (§1). Hidden from VoiceOver — the button already carries the name. |

Two pure rules were added, test-first (12 "no member" errors on the red run, then green):
- `showsLabel(isSelected:isFloating:)` = `isSelected && !isFloating`.
- `restingSlotWidth(barWidth:pillWidth:count:)` — the width of one unselected slot beside the
  pill, `0` below two slots. Its SE test is **the resting state's "stops a seventh tab" test**
  (seven → 38.5, fails).

## The trade-off E accepted by choosing C

C's own caption on the canvas: *"the label shifts as you move."* At rest the selected slot takes
its own width and the other five share the rest, so **every icon moves a little when the
selection changes**, and the whole row re-flows as the bar contracts into B's six equal slots.
This is the price of the label and it is inherent to the concept, not to the build. The
alternative — six fixed slots with the pill overflowing its own — cannot hold "Captures" in
65.5pt. Not re-litigated; noted so a later session does not read the shift as a bug.

## How it is built (for the next person in `AppTabBar.swift`)

Each slot is ONE `HStack(glyph, label-if-shown)`; `showsLabel` comes from the pure rule. The
content pads itself when labelled, takes `chipWidth` when floating, caps at
`maximumRestingPillWidth` when labelled; **one `indicatorMark` sits in the background of the
selected slot in both states and is sized by what it sits behind** — pill at rest, chip
floating. Its `matchedGeometryEffect` id is purely the slot-to-slot slide on a tab change. The
selected-at-rest slot is `.fixedSize(horizontal: true)`; every other slot keeps
`.frame(maxWidth: .infinity)`. The `VStack`, the dot, the clear spacer and the separate `chip`
are gone. The existing `.animation(morphAnimation, value: isFloating)` (house spring, nil under
Reduce Motion) animates the whole reflow.

## Conflicts reported (CLAUDE.md §7)

- `ui-ux-pro-max` still rates "bottom nav ≤ 5" HIGH severity. Six stays six; E's knowing call
  from 2026-09-02 is unchanged by this block.
- C's 10pt inner padding and 6pt gap are off-grid → both 8, under §2.

## Verification (this session, tree @ `96681a3`)

- RED: 12 compile errors, every one a missing member on the five new names. GREEN: the class at
  27 / 0, the suite at **2,502 / 0** (emulator up, no `9099` in any log), SwiftLint **0 / 711**,
  sim build green.
- Red-check after the commit: four regressions injected (label ignores floating; pill cap 200;
  gap 6; the count-guard loosened), **exactly the four predicted test cases failed** (five
  assertions — the SE floor test carries two); restored with `git checkout --`, no `RED-CHECK`
  marker left in the tree, full suite green again at 2,502 / 0.
- Device: built with `-allowProvisioningUpdates` (no "No Accounts", no expired profile),
  installed on `wishwashwacky15`; the launch was refused only because the phone was locked,
  which is the known "install is real, unlock and open" case.

## Open, for E on the phone

1. Does the labelled pill read right at rest, and does the morph into B feel like one shape?
2. Pill height 34 (chip) vs C's 44; radius 11 (chip) vs a capsule; the 8/8 spacing.
3. The icon shift on selection — is C's trade-off acceptable in the hand?

`screenshots/tabbar-select-pill/` is owed once the phone can be captured (mirroring was not
running this session; E connects it or sends the shots).

---

## Round 2 — E's first device verdict, and the answers (2026-09-08, same night)

E judged round 1 on the phone from two screenshots and a GIF
(`../Ethan's Screenshot Folder/non_scrolling-nav-tab-bar-test.jpeg`,
`scrolling-nav-tab-bar-test.jpeg`, `nav-tab-bar-in-action.gif`). Verbatim:

> *"I like what you've done but the main change this needs is that the nav bar shouldn't
> extend down to the bottom of the screen like is shown in the screenshot
> 'non_scrolling-nav-tab-bar-test'. The nav bar must stay floating as it is in screenshot
> 'scrolling-nav-tab-bar-test' BUT MUST still display the labelled pill."*

**So the opaque full-width pane — F's pane, which C's artboard had inherited — is gone for
good.** E was asked five questions; the answers, verbatim where they matter:

| question | E's answer |
|---|---|
| Same floating card at rest as scrolling, pane deleted? | *"Option 2 [floating, but positioned differently] but ALSO with 'the flat pane' gone for good."* |
| What does scrolling change now? | *"Only the label (for now..)"* — the pill collapses to the chip; the card itself also moves, see the next two rows. |
| Room for an end pill inside the card? | *"Keep B's 4pt"* — the card's inner padding is unchanged. |
| The pill itself? | **Capsule corners.** Height, label and gap as shipped. |
| How does the resting position differ? | *"Go with option 3, 'Both: wider, lower AND drops', but I may want to tweak this once I've actually seen it."* |

### What it is now

**One floating card, always.** Opaque `CardSurface`, 1pt `CardBorder`, soft shadow, 22pt
corners, B's 8/4 inner padding — in BOTH states. What morphs:

| | at rest (page near its top) | scrolled |
|---|---|---|
| inset from the sides | **8** (`restingInset`) | 12 (`floatingInset`, B's) |
| lift off the bottom | **16** (`restingLift`) | 8 (`floatingLift`, B's, E-tuned) |
| the selected mark | **capsule pill**, glyph + label | chip, 44×34, radius 11, glyph only |

So the card is wider and higher at rest, and contracts inward and drops as you scroll while
the label collapses. All four position numbers are named constants on the grid, because E
said they may want to tweak them once seen.

### The structural consequence — the band

The card is the bar's `safeAreaInset`. If the inset's HEIGHT changed with the morph, every
page's content would jump by the difference each time the morph fired — a scroll-driven
change to the thing that insets the scroll view, which is a feedback loop waiting to happen.
So **`rowHeight` is now the card plus the LARGER lift** — `cardHeight` (50, derived) + 16 =
**66pt** — and the card is bottom-aligned inside that band, moving within it while the band
does not. This is pinned by `testTheBandIsTheCardPlusTheLargerLiftSoTheInsetNeverMoves`.

**Knock-on, all derived and all deliberate:** the band grew 58 → 66, so the search row's
lift is now 98 (32 + 66), the disc's `bottomClearance` 166, and `appTabBarClearance()` 66.
At rest the card's top edge sits at the band's top, so the disc still clears it by E's
measured 32; while scrolling the card drops 8 and the gap reads 40.

### Numbers that changed from round 1

| constant | round 1 | round 2 | why |
|---|---|---|---|
| `restingPaddingHorizontal` | 8 (pane side padding) | **deleted** | no pane |
| `restingInset` / `restingLift` | — | **8 / 16** | E's "wider, lower AND drops" |
| `maximumRestingPillWidth` | 128 | **120** | the floor is now measured inside the resting card: (375 − 2·8 − 2·4 − 120) / 5 = **46.2 ≥ 44** |
| pill corner radius | 11 (chip's) | **capsule** (`pillCornerRadius` = chipHeight / 2 = 17) | E's pick; the chip keeps 11 so B is unchanged, and the mark animates between the two |
| `rowHeight` | 58 | **66** | the band, see above |

### Verification (round 2, tree @ `e9cd764`)

- RED: 7 "no member" errors on exactly the four new names. GREEN: 29 / 0 in the class, the
  suite at **2,504 / 0**, SwiftLint **0 / 711**, sim build green.
- Red-check, after the commit. **A lesson worth keeping:** three regressions injected together
  produced only TWO of the three predicted failures — flattening `restingLift` to 8 made
  `max(8, 8)` equal `floatingLift`, so the broken band formula gave the right answer by
  coincidence and the band test passed. Two regressions cancelled. Re-run with the band
  regression ALONE: exactly one predicted, exactly one actual. The register's "a symmetric
  swap can be invisible" note has a second instance: **inject interacting regressions one at
  a time, or predict the interaction.** Restored with `git checkout --`, no marker left, green
  again at 2,504 / 0.
- Device: rebuilt with `-allowProvisioningUpdates`, reinstalled on `wishwashwacky15`.

### Open, for E on the phone (round 2)

1. The two positions — 8/16 at rest, 12/8 scrolled. E: *"I may want to tweak this once I've
   actually seen it."* Four named constants; change nothing before E has looked.
2. The capsule pill against the 11pt chip — does the corner morph read as one shape?
3. The disc and search row sit 8pt higher than before (the band grew). Acceptable?

`screenshots/tabbar-select-pill/` is still owed; E's round-1 screenshots are the record of
the pane E rejected and belong in it (E's GIF is 7.8 MB and stays in E's folder unless E
wants it in the tree).
