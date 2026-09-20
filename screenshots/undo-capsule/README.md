# `F-C1-UndoCapsule` — the undo capsule, on every surface it appears on

> **Re-rendered 2026-09-20 after E's HEIGHT ROUND.** The first set drew the capsule at **74pt**
> against a 60pt capture disc. E marked a **45.3pt** band on
> `02-tasks-capsule-stands-in-for-search-L-EDITED.jpg` — *"the UndoCapsule must be made smaller in
> height, it looks ugly with the UndoCapsule at the same height as the FAB Icon"* — and, shown four
> shapes rendered on the real screen (`../undo-capsule-height/`), chose **two lines, a size
> smaller**: board `54`'s arrangement kept, verb `.footnote` → `.caption2`, subject `.callout` →
> `.footnote`, subject to ONE line. The card is **44pt** now, which is also §3's touch floor and
> the search row's own height — it stands in that slot, so matching it is deliberate.
>
> E also chose the Undo control's trade by name: *"Yes — draw 32, tap 44"*. The pill is drawn at
> 32pt and its hit area is grown back to §3's 44pt with the tab bar's own negative-padding trick
> (`AppTabBarMetrics.slotHitOverflow`). Round 7's *"48pt for anything that … undoes"* cannot be
> drawn inside a 44pt band; that number was written for a control that owns its space.
>
> **Every `-L`, `-D` and `-AX3` frame below is the NEW height.** The two landscape frames are
> suffixed `-PRE-HEIGHT-ROUND` and still show the 74pt capsule: what they prove is the
> *arrangement* (`RootBottomOverlayLayout` puts the sprint card beside the disc row), which the
> height does not change, and a shorter capsule only helps it. Re-rendering them is in the next
> session's opener.

**Environment:** iPhone 17 Pro simulator, iOS 26.5, Firebase **Emulator Suite** (the audit's
exported state, `scripts/audit/emulator-state`), a throwaway account created by the harness,
2026-09-20. Portrait frames are `app.screenshot()` attachments from
`ADHD LifeOSUITests/UndoCapsuleRenderUITests`; the landscape one is `xcrun simctl io … screenshot`
(see `10-` below for why).

**Why this folder exists — what driving the real screens caught that the tests could not.** Three
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
3. **Compact-height landscape with a sprint card up, also never rendered.** `10-` is the answer and
   it is a good one: the layout puts the sprint card BESIDE the disc row, the capsule takes the
   band left of the +, and all three sit on one line with nothing overlapping and the sprint's ▶
   still reachable.

**Throwaway data.** One account per run (`undocapsule*@…`, emulator only) and one note capture
("Ask Sam about the spare key") written by the harness. All of it lives in the Firebase **emulator**,
never the live project; the simulator was **erased** at close-out, which is also the fix for the
signed-in-simulator trap that makes the next unit suite crawl.

**Colours are measured from the colorsets, not from these JPEGs** — see the block report's
`apple-design` section. Light: subject 19.26:1, verb 4.25:1, Undo label 3.38:1. Dark: 14.97:1,
5.52:1, 3.48:1. The two below 4.5:1 are the app's existing `LabelSecondary` and the tab bar's own
selected-pill wash, and belong to the **held colour arc** (round 9: *"Leave it to the colour arc"*).

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
| `09-landscape-portrait-reference-L` | The portrait pose with a seeded sprint running, so `10-` has something to be compared against. |
| `10-landscape-capsule-beside-the-sprint-card-L` | **Board `54` never rendered this either.** Compact height with a card up: `RootBottomOverlayLayout` chooses `.besideTheDisc`, the sprint card takes the column beside the disc row, and the capsule fits in the band with the + — one line, no overlap, the sprint's ▶ still reachable. **Captured with `xcrun simctl io` from outside the test while it held the pose**: `app.screenshot()` lies on a rotated simulator and returns a letterboxed portrait column (`F-LandscapeFix`), which is exactly what the first attempt produced. |

## One thing to look at that is not a defect and not settled

On the Capture Inbox (`04-`) the page's content scrolls **under** the capsule — "INBOX HEALTH" is
behind it. That is the same relationship the capture disc has always had with every page, and the
inbox's `safeAreaInset` reserves the tab bar's room but not the capsule's. It is called out here
rather than re-tuned, because the clearance numbers in that row are E's and were settled over four
device passes.
