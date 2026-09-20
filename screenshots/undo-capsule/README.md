# `F-C1-UndoCapsule` — the undo capsule, on every surface it appears on

> **Re-rendered 2026-09-20 (SECOND re-render) after E's SHAPE ROUND — and the render caught a
> Critical the round itself could not have.** E looked at the 44pt capsule on their own phone and
> sent the shape back: *"Bringing back a second line is smart. I also recommend that we remove the
> blue chip background colour behind the "Undo" Button and increase the corner radius of the entire
> UndoCapsule card."* Eight shapes were then rendered on the real screen
> (`../undo-capsule-redesign/`) and E chose **fully rounded, no chip, and the Undo control's 16pt
> padding reclaimed** — then, shown that a second line costs 15pt on every realistic task title,
> **overturned their own opening words and chose 44pt with ONE wider line.** The reclaimed 32pt is
> spent widening that line: these frames read *"Take a 10-minute walk"* where the shipped shape
> truncated.
>
> **Then the accessibility layout was rendered at the new shape, and nobody had ever done that.**
> Every frame of the whole redesign round was taken at the DEFAULT text size. A `Capsule` takes its
> radius from half the card's height — a harmless 22 at 44pt. At Accessibility XL the stacked card
> is **194.3pt**, so the caps grew to **97.2pt** and the curve ate the corners the content sits in:
> **6,329 pixels of the completion glyph and 2,604 pixels of the ↶ Undo control were drawn OUTSIDE
> the card's own fill** — the glyph 59.0pt clear of it, the Undo control 30.3pt. Shown both shapes
> on the real screen (`11-`), **E chose to cap the radius at `minHeight / 2`.** After the cap those
> two counts are **0 and 0**.
>
> **The cap is not a compromise on what E approved.** At 44pt `min(44, 44) / 2` IS 22 — the
> capsule's own radius — and the two builds' renders of this very screen came back **byte-identical
> over the capsule band: max channel delta 0, zero differing pixels across 1206×175**. It changes
75**. It changes the
> accessibility layout and nothing else.
>
> **Every `-L`, `-D` and `-AX3` frame below is the SHIPPED shape**, rendered from `main`'s merge of
> this round. **The two landscape frames are re-rendered too** and have lost their
> `-PRE-HEIGHT-ROUND` suffix — they were two rounds stale.

**Environment:** iPhone 17 Pro simulator, iOS 26.5, Firebase **Emulator Suite** (the audit's
exported state, `scripts/audit/emulator-state`, restarted fresh before the baseline), a throwaway
account created by the harness per run, 2026-09-20. Portrait frames are `app.screenshot()` attachments from
`ADHD LifeOSUITests/UndoCapsuleRenderUITests`; the landscape one is `xcrun simctl io … screenshot`
(see `10-` below for why).

**Why this folder exists — what driving the real screens caught that the tests could not.** Four
things, and none of them is assertable:

1. **The Undo button truncated to "Un…".** In a tight `HStack` SwiftUI compresses whichever child
   will give, and beside a two-line subject the child that gave was the one control in the capsule
   that must never be ambiguous. Every unit test was green. Fixed with `.layoutPriority(1)` and
   `.fixedSize(horizontal:vertical:)`, and `UndoCapsuleCallSiteTests` now pins both by name —
   truncation is not a property a test can see, so the modifiers that prevent it are what get
   pinned. The "Un…" frame is not kept: it was overwritten by the re-run, and the fix is what the
   `02-` frames show.
2. **The Journal case, which board `54` never rendered.** E's Step 0 answer 4 said the capsule
   stands in for the PENCIL, full width, and the + disc never moves. `03-` is that, and it is what
   was claimed rather than something close to it.
3. **The fully-rounded card breaks the ACCESSIBILITY layout, and only a render at that text size
   could show it (2026-09-20).** E chose "fully rounded" from eight frames, every one of them at
   the default text size where the card is 44pt. The stacked accessibility layout is 194.3pt, and a
   capsule's radius is *derived from its height* — so at that size it is a different shape. 6,329
   glyph pixels and 2,604 Undo pixels were drawn off the card. **The general rule: when a shape's
   geometry is derived from its content's size, the accessibility layout is a different shape.
   Render it before calling a shape round closed.** `11-` is the frame E decided from.
4. **Compact-height landscape with a sprint card up, also never rendered.** `10-` is the answer and
   it is a good one: the layout puts the sprint card BESIDE the disc row, the capsule takes the
   band left of the +, and all three sit on one line with nothing overlapping and the sprint's ▶
   still reachable.

**Throwaway data.** One account per run (`undocapsule*@…`, emulator only) and one note capture
("Ask Sam about the spare key") written by the harness. All of it lives in the Firebase **emulator**,
never the live project; the simulator was **erased** at close-out, which is also the fix for the
signed-in-simulator trap that makes the next unit suite crawl.

**Colours are measured from the colorsets, not from these JPEGs** — see the block report's
`apple-design` section. **Dropping the chip IMPROVED the Undo label**, because it now sits on
`cardSurface` rather than on a 12%/20% accent wash: **3.38 → 3.93:1** light and **3.48 → 4.47:1**
dark. Light: subject 19.26:1, verb 4.25:1, Undo label 3.93:1. Dark: 14.97:1, 5.52:1, 4.47:1. The
remaining shortfalls against 4.5:1 are the app's existing `LabelSecondary` and `AccentColor`, and
they belong to the **held colour arc** (round 9: *"Leave it to the colour arc"*) — recorded here,
not fixed.

## The frames

Suffix is the appearance: `-L` light, `-D` dark, `-AX3` accessibility extra-large (set with
`xcrun simctl ui <udid> content_size accessibility-extra-large` — a launch argument produced a
size or two up in which the capsule never stacked, i.e. it was photographing the ordinary layout).

| file | what it proves |
|---|---|
| `01-tasks-before-the-close-*` | The disc row as it stands before any close: the search row in the leading band, the + disc at the end. The "before" half of the stands-in-for claim. |
| `02-tasks-capsule-stands-in-for-search-*` | E's round-2b shape A on Tasks — the capsule occupies exactly the search row's slot, the + disc has not moved, nothing stacked. **The AX3 frame is the stacked layout E asked for**: glyph + "Closed" on row one, the subject below it, the Undo pill on its own row. |
| `03-journal-capsule-displaces-the-pencil-*` | **Board `54` never rendered this.** On the Journal the capsule stands in for the 42pt pencil disc, full width, and the + disc stays put — E's Step 0 answer 4, confirmed rather than assumed. |
| `04-inbox-capsule-and-header-arrow-*` | The Capture Inbox's own bottom undo bar is GONE and the capsule does its job instead, while the header ↶ (top right) is still there — E's Step 0 answer 2, both affordances reading one slot. |
| `05-collision-the-close-spent-the-captures-undo-*` | The consequence of E's "one bottom bar everywhere", shown rather than described: a capture was skipped, then a task closed, and the capsule now names the CLOSE. The capture's undo is spent. |
| `06-inbox-header-arrow-gone-with-the-spent-undo-*` | The other half of the same collision, and the reason E's answer 2 is right: back on the inbox, the header ↶ has gone with the spent undo instead of offering an undo the capsule no longer shows. |
| `07-today-hero-before-the-close-*` | Today's hero with its "Close it" button, before. |
| `08-today-capsule-replaces-the-closure-card-*` | The same close, after: the capsule, and **no `ClosureCelebrationCard`** — Home's in-place green card is retired, and the hero recomputes to the next best move rather than being replaced by a celebration. |
| `11-ax3-the-decision-capsule-vs-capped-L` | **The frame E decided the cap from**, side by side at Accessibility XL with the measured numbers on each half: a true `Capsule` (97.2pt caps, glyph and Undo control drawn off the card) against the radius capped at 44/2 (all content on the card, and pixel-identical to the other at normal text size). |
| `09-landscape-portrait-reference-L` | The portrait pose with a seeded sprint running, so `10-` has something to be compared against. |
| `10-landscape-capsule-beside-the-sprint-card-L` | **Board `54` never rendered this either.** Compact height with a card up: `RootBottomOverlayLayout` chooses `.besideTheDisc`, the sprint card takes the column beside the disc row, and the capsule fits in the band with the + — one line, no overlap, the sprint's ▶ still reachable. **Captured with `xcrun simctl io` from outside the test while it held the pose**: `app.screenshot()` lies on a rotated simulator and returns a letterboxed portrait column (`F-LandscapeFix`), which is exactly what the first attempt produced — the harness polls a screenshot every 3s for the whole run and the landscape ones are picked out afterwards, so nothing depends on guessing when the 25s hold starts. |

## One thing to look at that is not a defect and not settled

On the Capture Inbox (`04-`) the page's content scrolls **under** the capsule — "INBOX HEALTH" is
behind it. That is the same relationship the capture disc has always had with every page, and the
inbox's `safeAreaInset` reserves the tab bar's room but not the capsule's. It is called out here
rather than re-tuned, because the clearance numbers in that row are E's and were settled over four
device passes.
