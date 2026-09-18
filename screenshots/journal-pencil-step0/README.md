# F-JournalPencilReachable Step 0: the probe, and E revising the shape by looking (2026-09-18)

**Environment:** the rig from `screenshots/journal-door-unpinned/README.md`, unchanged:
- **What was rendered:** the REAL `JournalView` (its own `NavigationStack`), the real `AppTabBar` as a
  bottom `safeAreaInset`, and the real `RootBottomOverlay` as a `.bottom` overlay.
- **How:** hosted in a `UIHostingController` in a key `UIWindow` pinned to the BOTTOM of the
  simulator screen (E's real 34pt home-indicator inset) and drawn with `drawHierarchy` at 3×,
  393 × 852pt.
- **Runtimes:** the `iPhone 17 Pro` simulator on **iOS 27.0** (E's phone's OS). Every finding below
  was ALSO run on **26.5** unless it says otherwise.
- **Tooling and data:** Xcode 27.0, `main` @ `43736a0`. Fake journal data; no backend, no account.

The variants came from TEMPORARY static switches in `JournalView.swift`, `TabNavigation.swift` and
`RootBottomOverlay.swift`, read at body time, plus a throwaway probe test. **All of it was reverted
with `git checkout --`, and `git status` was empty before this folder was added.** None of it is
production code. It drew what the code would draw.

## Why this folder exists

`F-JournalPencilReachable`'s approved plan asked for a Step 0 before any test. It had three parts:
1. Is `.glassProminent` any different from `.borderedProminent` in a toolbar?
2. How does a FILLED pencil sit beside the eye? E had only ever seen an accent GLYPH in the toolbar.
3. Does a tab re-tap bring the large title back?

The first and third are measured below. The second went to E, and **E changed the shape**. So this is
the record of a design settled by looking, and the reason the block was handed to a fresh session
rather than built here (E's standing rule, `build-in-a-fresh-session`).

## E's answers, verbatim

1. Shown `00`: a filled pencil cannot share (b)'s one capsule, because iOS draws the eye in its own
   glass circle and the pencil as a separate blue disc. E answered: *"move the filled pencil icon disc
   down to the left-hand side of the FAB Icon. make the filled pencil disc inline with the FAB icon"*.
2. `00`, columns A / B: **"B (Recommended)"**. The eye is OFF in the label colour and ON in accent;
   the pencil glyph is white in both modes.
3. **"Keep the nav bar"**: the large title stays, with the eye alone top right.
4. **"48pt (Recommended)"**, centred on the + disc's line, 16pt to its left. **Then, mid-session,
   E revised it:** *"decrease the size of the filled pencil disc from 48pt to 42pt"*. **42 is the
   number.** Frames `03`–`05` show 48 because they were rendered before that message.
5. Shown `03`–`05`, what the disc does while the + is a pill: **"1 · Follows the pill
   (Recommended)"**. It goes 68% translucent with the +.
6. At rest: **"Match the + gradient"**, i.e. `CaptureDeep` → accent, top to bottom, as
   `CaptureDiscLabel` draws it. That is over the flat accent the frames show. **E has not seen the
   gradient rendered.** The glow was not asked about. The spec's default is NO glow, so the + keeps
   its glow as the cue that capture is primary, and E judges it on the device.
7. **"Hand off to fresh session (Recommended)"**.

## What was measured, all of it on BOTH runtimes unless stated

**`.borderedProminent` vs `.glassProminent` in a toolbar: pixel-identical.**
- **26.5, the first run:** 0 differing pixels of 3,013,524, light and dark, at rest and scrolled.
- **27.0:** no differences, in all four states.
- **26.5, one later run:** the scrolled frames differed by ≤3/255 per channel. The difference was
  spread over every glass region, the title included, and the dark pencil region was 0. That is
  backdrop-sampling noise.
- **So the system already draws the floor API as prominent glass.** This is moot now that the pencil
  has left the toolbar.

**A prominent item splits a `ToolbarItemGroup`.** The eye gets its own glass circle. A group and two
separate `ToolbarItem`s render identically (26.5).

**Three colour facts, all sampled:**
- **In DARK mode iOS draws a prominent item's glyph BLACK** (0,0,0 on 60,131,246), on both runtimes.
- **A `.foregroundStyle` on the label overrides it.** This is what B shows.
- **On 26/27, toolbar glyphs default to the LABEL colour, not accent.** The spec's old decision 2
  assumed accent, which is true only below 26.

**The re-tap does NOT bring the large title back** (`02`). Measured after scrolling 420pt; identical
on 26.5 and 27.0, light and dark:

| route | nav bar | offset | |
|---|---|---|---|
| at rest | 106pt | −168 | large title |
| R0 shipped `proxy.scrollTo(TabRootScrollAnchor.id, anchor: .top)` | **54pt** | −116 | collapsed |
| R1 iOS 18 `ScrollPosition.scrollTo(edge: .top)` | **54pt** | −116 | collapsed |
| R2 UIKit `setContentOffset(y: −168)` | 106pt | −168 | restored, holds |
| R3 the same, animated | 106pt | −168 | restored, holds |
| R4/R5 offset written to `−adjustedTop − bounds.height`, then layout | 106pt | −168 | the overscroll settles at the EXPANDED top by itself |

**Tasks is no control for this.** Its scroll view sits under a filter row, and its title never
collapses: 106pt at 420pt scrolled.

**The pencil disc's geometry at E's inset** (`03`/`04`, at 48pt):
- the + disc's centre is **695.8** with the pencil and **695.8** without it, so the gate holds
  (predicted 696.0);
- the pencil's centre is **695.8**, on the same line;
- the pencil is **47.7pt** wide;
- the gap to the disc is **16.3pt**.

At 42 the centre line and the 16pt gap are unchanged by construction. The row is the disc's 60pt
height, and a 1pt hit overflow takes the target to 44 without moving the layout.

## Files

| file | what it proves |
|---|---|
| `00-toolbar-options-27.jpg` | What E answered 1–2 from: (b) as rendered vs A (the spec) vs B, at rest, scrolled and eye ON, light and dark. |
| `01-before-after-full-light-27.jpg` | The whole screen: (b)'s capsule vs the split a filled pencil forces. |
| `02-retap-large-title-27.jpg` | At rest; scrolled; the re-tap under R0 and R1 (the title stays COLLAPSED) and R2 (restored). |
| `03-pencil-disc-pill-zoom-27.jpg` | What E answered 5 from: the disc at rest and pilled three ways, light and dark, zoomed. At 48pt, flat accent: both since revised. |
| `04-…-light-27.jpg`, `05-…-dark-27.jpg` | The same four states as whole screens, with the eye alone in the toolbar (B). |

## What these frames do NOT show

- **Not rendered:**
  - the 42pt size;
  - the gradient;
  - a sprint card up;
  - landscape;
  - the fan open;
  - a tab-switch transition.
- **Only portrait at default Dynamic Type was rendered.** The large-title band (52pt here) grows with
  Dynamic Type, which is why the re-tap fix must FIND the expanded top rather than hard-code it.
- **Nothing ran below 26.5.** The re-tap mechanism is verified only on 26.5 and 27.0, which is why
  the spec gates it `#available(iOS 26.0, *)` with the shipped scroll as the floor.
