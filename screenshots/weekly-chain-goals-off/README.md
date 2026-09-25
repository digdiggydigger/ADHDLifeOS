# weekly-chain-goals-off — `F-E1-WeeklyChain`

**Environment:** iPhone 17 Pro simulator on **iOS 27.0** (E's OS), Firebase emulator (started with
`--import scripts/audit/emulator-state`), a throwaway `uitest-e1chain-*@example.test` account made
per run, 2026-09-25. Frames are `WeeklyChainRenderUITests.testRenderGoalsOffAndTheGainLine`'s own
screenshots, one run per appearance (`xcrun simctl ui … appearance`). **Both runs PASSED.**

## What these frames settle that no test could

E's round 3: *"Preset goals → 'Off until you set one.' No ring and no percentage until the user
chooses a goal in Settings."* Round 8b: *"'Close it — makes today count'"*, shown only while today
has no activity yet.

1. **A fresh account meets no goal.** Today's scoreboard reads **"0 · CLOSED TODAY"** with no ring
   and no "of N". The streak column is gone, so "Still open · 3 items" is the whole right-hand side.
   (The accessibility label, asserted: `0, closed today, Still open, 3, items`.)
2. **The gain line on a real task.** Nothing has counted today on a fresh account, so Task Detail's
   close reads **"Close it — makes today count"** (370 × 70pt, measured). The harness asserts the
   exact label.
3. **Settings, goals off.** "Set a daily goal" and "Set a daily focus goal" are both OFF and neither
   Stepper is drawn. The chain's own Stepper, **"Active days a week · 3 days"**, sits under "Show
   weekly chain". Toggle rows measure 370 × 52pt.
4. **Turning the goal on reveals its Stepper at the old seed**: "Daily goal · 5 items".
5. **The ring arrives around the same number**, now reading "0 · OF 5 CLOSED", without anything else
   on Today moving (the no-goal count keeps the ring's 126pt footprint on purpose).

**Seen here and left for `F-E3`, not a defect of this block:** Today's hero still reads plain
"Close it" for the same task whose detail says "makes today count". E3's spec replaces that hero
with the one card and gives it the SAME Close copy as Task Detail, from the same
`MomentumTaskContext`, so the two cannot disagree once it lands. Until then they differ for a few
hours of the arc, and nobody sees the arc before its close.

**Frame 01 carries iOS's own "Save Password?" sheet** over its lower half: a fresh sign-up on a
simulator offers it, and it is the system's, not the app's (memory `tab-root-rows-not-hittable`).
The card the frame is about is fully visible above it, and frame 05 shows the same card clean.

**Changed after these frames:** the `apple-design` review moved "Active days a week" inside the
"Show weekly chain" reveal (progressive disclosure, the goal toggles' own pattern). With the chain
on, as here, the screen is identical, so the frames still show it. A frame with the chain off would
show one row fewer.

## Throwaway data

Each run made one emulator account. The local emulator discards it on restart, and nothing was
written to the live project. The daily goal the harness turned on was turned back off before each
run ended (the preference is device-wide), and the simulator was ERASED after the two runs.

## Files

| file | proves |
|---|---|
| `01-today-no-goal-{light,dark}.jpg` | A fresh account's Today: a count, no ring, no "of N", no streak |
| `02-task-detail-gain-line-{light,dark}.jpg` | "Close it — makes today count" before anything has counted today |
| `03-settings-goals-off-{light,dark}.jpg` | Both goal toggles off, no goal Steppers; the chain at 3 days |
| `04-settings-goal-on-{light,dark}.jpg` | Turning the daily goal on reveals its Stepper at 5 |
| `05-today-goal-set-{light,dark}.jpg` | With a goal set, the ring and its "of 5" return |
