# The × drops to its resting corner — F-FanXAtRest (2026-09-17)

**Environment:** `iPhone 17 Pro` simulator, iOS 26.5, light; Firebase emulator (fresh this session);
throwaway emulator accounts created by the journeys (`fanaway…`, `sprinttasks…`); the simulator was
ERASED after every UI run. Branch `feature/fan-x-at-rest`. Captured 2026-09-17.

**What this settles.** E's frame 19 and GIF (`screenshots/landscape-fab-overlap/19`, `21`): in
portrait any card pushes the capture disc up, the fan's tiles are placed from the RESTING corner
78pt apart, and so the × lands on a tile. E called it a bug and chose **shape B, *"× drops to its
corner"***. While the fan is open the stacked disc row now moves to the column's bottom line and
the (faded) cards keep their frame.

**What driving the real screens caught that the unit tests could not:**
- **The collision, at the device's own numbers, before a line was written.** On the unfixed tree
  `FanOverAwayCardUITests` failed with *"the × (centre (348, 505)) sits on the PHOTO tile, 35.3pt
  apart"* (E's frame 14 read 34pt). With the wiring cut, `SprintBarFurnitureUITests` failed with
  *"sits on the TASK tile, 9.49pt apart"* under a seeded collapsed sprint bar (E's frame 19 read 9pt).
- **The move is a real tween, not a jump, and the × stays in front of the card.** A `Layout`
  property change can animate or snap; the recording shows it travelling over ~3 frames at 15 fps
  each way, drawn over the fading card (the disc row's `zIndex`, also proved by
  `RootBottomOverlayDrawOrderTests`). The recording is of the ×-button path; the scrim and
  tile-pick paths set `isFabOpen` bare and ride the container's `.animation(value: isFabOpen)`,
  which a call-site test pins.
- **On Tasks the search row rides down with the ×** (both 612 → 680pt) and both come back.
- **The return is exact:** the journey's fan-closed frame before opening and after closing were
  byte-identical, so only one is kept (01).

**Verified paths:** full motion: run on sim (26.5), device look owed. **Reduced:** the × move is
`nil` under Reduce Motion (§7.2's continuous re-layout) while the cards keep their `.default`
fade; run on sim only by the unit/call-site tests (not injected on a render), **NOT on device —
E's RM-on pass is owed** (§7.3). No `#available` site added.

| file | what it proves |
|---|---|
| `00-before-fan-open-x-on-photo-26.5.jpeg` | **The bug, on the unfixed tree.** Away card up, fan open: the × sits on PHOTO. |
| `01-after-fan-closed-card-up-26.5.jpeg` | The control: fan closed, the card pushes the disc up as E's stack always has. |
| `02-after-fan-open-x-at-rest-26.5.jpeg` | **The fix.** Same state, fan open: the × is in its resting corner and every tile is clear. |
| `03-tween-opening-15fps-26.5.jpeg` | 15 fps crops of the bottom-right as the fan opens: the + travels down over the fading card and becomes the ×. |
| `04-tween-closing-15fps-26.5.jpeg` | The same as the fan closes: the × rises back above the card as it fades in. |
| `05-tasks-collapsed-bar-fan-closed-26.5.jpeg` | Tasks, seeded collapsed sprint bar, fan closed: the search row and disc share a row above the bar. |
| `06-tasks-fan-open-wiring-cut-x-on-task-26.5.jpeg` | Red-check (overlay passes `fanIsOpen: false`): the × covers TASK — E's frame 19 reproduced. |
| `07-tasks-fan-open-row-and-x-at-rest-26.5.jpeg` | **The fix on Tasks:** the search row and the × have dropped together to rest; TASK is clear. |

## E's device verdict, 2026-09-17 ~12:55 — PASSED

iPhone 15 Pro, iOS 27.0, `main` @ `4653433`. E's fan-open frame with a Confirm card up shows the × at
its resting corner, clear of TASK: *"they also show that your fixes to the FAB Icon were
successful."* **Still owed:** the Reduce Motion ON pass (the × jumps; the cards must still FADE).
