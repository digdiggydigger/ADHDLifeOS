# The collapsed bar stops dropping onto the tab bar — F-CollapsedBarLift (2026-09-17)

**Environment:** `iPhone 17 Pro` simulator, iOS 26.5, light; Firebase emulator (fresh this session);
throwaway emulator accounts `barlift…` / `barliftconfirm…` created by `SprintBarFurnitureUITests`;
a PAUSED collapsed sprint (and, for the Confirm poses, one finished sprint awaiting Confirm) seeded
through the launch-argument domain; the simulator ERASED after every run. Frames are host-side
`simctl io screenshot` polls taken while the journey held each pose (`app.screenshot()` lies on a
rotated simulator). "Before" is `main` @ `ad4f3ee`; "after" is `feature/collapsed-bar-lift` @ `aa59da1`.

**What this settles.** E, 2026-09-17: *"it needs to have some margin space added BELOW The card
bottom-left AND ABOVE The NAV tap menu bar"*, then *"Portrait too"*, then *"Line up with the Disc,
But when there are multiple cards being displayed, then maintain the alignment."* This reverses
the 2026-09-09 flush drop. The card's LAYOUT frame was always on the disc's line; a 32pt `.offset`
drew it on the tab bar. Removing the offset puts it on the disc's line in both orientations.

**Reading "line up with the disc" in portrait.** In portrait the disc sits ABOVE the column (a
running sprint pushes it up), so the collapsed bar cannot share the pushed disc's bottom. It lines
up with the disc's RESTING line: the line the disc occupies with nothing up, and where the × drops
with the fan open (`F-FanXAtRest`). In landscape the disc sits beside the cards, so the bar's
bottom is literally the disc's bottom.

**Measured by the journey (points, from XCUI frames; the resting line read from the app itself):**

| pose | bar bottom vs disc's line — before → after | gap above the tab bar — before → after | Confirm button → bar — before → after |
|---|---|---|---|
| portrait, bar alone | +32 → **0** | 0 → **32** | — |
| landscape, bar alone | +32 → **0** | 0 → **32** | — |
| portrait, under a Confirm card | +32 → **0** | 0 → **32** | 56 → **24** |
| landscape, under a Confirm card | +32 → **0** | 0 → **32** | 56 → **24** |

Nothing else moved: the pushed disc sat at y 612 (bar alone) and 528 (with the Confirm card) both
before and after, because the offset never touched layout. Under a Confirm card the column's 8pt
between the two cards is now what is drawn (the button is centred in a 76pt card: 38 − 22 + 8 = 24).

**What driving the real screens caught that the tests could not:**
- **The bottom keyline is back** (a consequence named in the spec, not a new decision): the frames
  show the collapsed card outlined on all four sides, with the same 24pt corners top and bottom.
- **Scroll clearance holds** (08/09): scrolled to the bottom of Today, the last card (Week review)
  still clears the lifted bar. The clearance reads layout frames, which never moved.
- **Harness facts, recorded so the next journey does not pay for them.** The card's
  `focusTimerBar` identifier overrides its children's identifiers (`focusBarPause` matches nothing),
  so the journey finds Pause by label. The AutoFill "Save Password?" sheet must be swept BEFORE
  waiting for an element. A host screenshot poller must be killed when `xcodebuild` exits: one
  `simctl io screenshot` hung on a shut-down simulator and blocked the chained erase for an hour.

**Verified paths:** no `#available` site and no reduced site touched. The collapse animation's
`reduceMotion ? nil` is unchanged, so no RM-on pass is owed for this block.

| file | what it proves |
|---|---|
| `00-before-alone-portrait-26.5.jpeg` | Before: the collapsed bar sits on the tab bar, no bottom keyline. |
| `01-after-alone-portrait-26.5.jpeg` | **After:** 32pt above the tab bar, on the disc's resting line, outlined on all four sides. |
| `02-before-alone-landscape-26.5.jpeg` | Before, landscape: the bar on the tab bar, 32pt below the disc beside it. |
| `03-after-alone-landscape-26.5.jpeg` | **After, landscape:** the bar's bottom lines up with the disc's. |
| `04-before-confirm-portrait-26.5.jpeg` | Before, with a Confirm card above: the bar still dropped onto the tab bar. |
| `05-after-confirm-portrait-26.5.jpeg` | **After:** the alignment holds with two cards up. |
| `06-before-confirm-landscape-26.5.jpeg` | Before, landscape, with a Confirm card: the bar on the tab bar. |
| `07-after-confirm-landscape-26.5.jpeg` | **After, landscape, with a Confirm card:** the bar on the disc's line. |
| `08-before-alone-portrait-scrolled-26.5.jpeg` | Before, Today scrolled to the bottom. |
| `09-after-alone-portrait-scrolled-26.5.jpeg` | **After:** the last card still clears the lifted bar. |
