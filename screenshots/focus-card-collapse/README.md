# F-FocusCard-1 — the collapsible sprint card

**Environment.** E's physical iPhone (iOS 26.4), Firebase project `adhdlifeos-acb49`, signed in as
E's real account, 2026-09-09. Every device image here is E's own screenshot; the three `*-analysis-*`
PNGs are measurements I derived from those same screenshots (pixel scans, 3x → pt at 1179x2556 =
393x852pt). No throwaway data was created — the sprints shown are E's own "9th September - Sprint
Session test" task, and nothing was written to Firestore for this folder.

## Why this folder exists

**Four of the five things that changed in this block were settled by E LOOKING at the card, not by
an assertion**, and three of them were reversals of decisions taken in the design record. The
numbers that came out of it are now unit-tested (`FocusBarGeometryTests` pins the 60pt height, the
16pt inset and both border behaviours), so this folder is not here to prove the geometry — it is
here to record **what the rejected versions actually looked like**, which no test can hold.

The one thing a test genuinely could not have caught is `08`: a correct, tested, *reachable*
component rendering wrongly because of a SwiftUI compositing rule.

## What driving the real screens caught that the tests could not

1. **Full-bleed cannot sit "flush" on a floating inset bar.** The design record settled full-bleed
   AND flush-to-the-bar as separate answers. On device they contradict: the card is 393pt, the bar
   is a floating pill of 385pt (resting) / 377pt (scrolled), so the card's square bottom corners
   land on the *page* either side of the bar. With the bar's 22pt corner radius, ~26pt at each end
   of the card's bottom edge has no bar beneath it at all. See `03a`.
2. **"Flush" held in only one of the bar's two states.** The bar sits in a constant 68pt band but
   *moves inside it* — lifted 8pt at rest, 4pt when scrolled — so a card pinned to the band was
   flush at rest and showed a 4pt sliver of page when scrolled. Not transient: the scroll state is
   hysteretic and sticky. See `03b`. E's fix was to retire the bar's vertical morph entirely.
3. **The row was over-subscribed, and narrowing the card exposed it.** At 305pt with the chevron
   and the PAUSED badge sharing the title's line, the title collapsed to `9…` and PAUSED wrapped
   onto two lines. See `06` / `07`. No test asserted the title stayed readable.
4. **A "collapsed" card taller than the bar it sits on reads as wrong.** 73pt against the bar's
   60pt. E: *"way too tall!"*.
5. **The `next` checkpoint marker rendered as a hole punched in the card** in dark mode. See `08`.

## The bug in `08`, because it will recur

`.next` was the only **hierarchical** style in `FocusCheckpointDotState` (`Color.primary`). Over a
`Material`, SwiftUI resolves hierarchical styles with **vibrancy** rather than as a flat colour, so
the 12pt disc landed mid-grey instead of white. `.reached` and `.pending` are concrete `Color(…)`
values and always rendered correctly — **that asymmetry is the proof**, and it is visible in `08`:
the same `ForEach`, three states, one wrong.

The 2pt `Color(.systemBackground)` ring around it is a *concrete* colour, gets no vibrancy, and so
painted literal `#000000` in dark mode. Its premise — "a page-colour ring separates the marker" —
was false twice: the marker sits on a material (a blur, which no colour can match), and
`systemBackground` (#FFF/#000) was never this app's page colour, which is `PageBackground`
(#F2F3F7 / #15171C).

Fixed by deleting the ring (12-vs-8pt diameter already satisfies §4's shape rule) and moving the
fill to `LabelPrimary`. **Mirrored into `FocusTimerWidget/FocusActivityComponents.swift`**, which
duplicates this palette deliberately, so the enum fix could not reach it.

## Files

| file | what it proves |
|---|---|
| `00-e-original-annotated-request.jpg` | E's original brief: three green arrows for the collapse, a black box over the action row for the target size. The whole arc starts here. |
| `01-r1-full-bleed-73pt-light.jpeg` | Round 1 as the design record specified it — full-bleed, 73pt, flush. Rejected. |
| `02-r1-full-bleed-73pt-dark.jpeg` | Same in dark, where the `next` dot's black ring is first clearly visible. |
| `03a-analysis-full-bleed-overhangs-inset-bar.png` | 5x zoom of the bottom-left join. The card's square corner sits over page, not over the bar — measured, not eyeballed. |
| `03b-analysis-bar-scroll-drop-opened-4pt-gap.png` | Resting vs scrolled, with the measured edges labelled: flush at rest, 4pt gap scrolled. |
| `04-e-marked-width-red-lines.jpeg` | **E's own markup.** Two red lines at 41.8pt / 348.7pt. They land on the first and last tab-icon centres — an alignment that holds only while the bar is scrolled, which is why the shipped inset is a constant and not derived. |
| `05-r2-inset44-305pt-light.jpeg` | Round 2 at inset 44. E: *"can be extended MORE to the left and the right"*. |
| `06-…-dark.jpeg` / `07-…-light.jpeg` | Round 3, paused: the title destroyed to `9…` and PAUSED wrapped to two lines. The reason the chevron and the badge left the collapsed card. |
| `08-analysis-next-dot-vibrancy-bug.png` | 3x zoom, expanded 64pt vs collapsed 44pt vs light. The grey-disc-in-a-black-ring, and how much louder it gets as the ring shrinks. |

## What shipped (E: *"That all works very nicely."*)

60pt tall — the tab bar's own height — inset 16pt so collapsing changes height only; no bottom
border; grabber overlaid in the top padding; ring 44pt; Pause a bare glyph at the far right; no
chevron and no PAUSED badge in this state. Tap opens the full sprint view in **both** states;
swipe up expands, swipe down collapses, and the long-press is retired.
