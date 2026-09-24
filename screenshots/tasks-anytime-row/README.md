# tasks-anytime-row — `F-D3-TasksAnytimeRow`

**Environment:** iPhone 17 Pro simulator on **iOS 27.0** (E's OS), Firebase emulator (started with
`--import scripts/audit/emulator-state`), a throwaway `uitest-d3anytime-*@example.test` account made
per run, 2026-09-24. Frames are `TasksAnytimeRowRenderUITests.testRenderTheAnytimeRow`'s own
screenshots, one run per appearance (`xcrun simctl ui … appearance` / `content_size`), named from
the attachment the harness took at each step. All three runs **PASSED**.

## What these frames settle that no test could

Round 6, E's words: *"The Tasks board gains one collapsed 'Anytime · N' row at the bottom: the tail
stays folded, but a new task is visible where it was added."* Round 8b: *"Undated tasks already live
in Anytime, and future-dated tasks are untouched."*

1. **The rule applied to a real account.** A fresh account is seeded the way production seeds one:
   two undated starter tasks and one due tomorrow. The board opens on "TOMORROW · 1" and then
   **"ANYTIME · 2 ▲"**, last, with no rows under it. Before this block those two tasks were
   invisible on Momentum.
2. **"Visible where it was added" is the COUNT.** A task added with no date (the composer's "Not
   yet") takes the header to **"ANYTIME · 3"** while the fold stays closed. The harness asserts that
   the new title is NOT drawn at this point. The fold opens only when the person asks.
3. **Opened, the new task is there**, with the two seeded ones, and **no ▶ sprint launcher** on
   any of them. ▶ stays on Due today (E's b11 call).
4. **The header is a real target at every size.** It measures **370 × 44.0pt** at the default size
   and at Accessibility XL (§3's floor), from the accessibility tree rather than the picture.
5. **Quiet, as round 9 asked.** Anytime speaks in the plain secondary voice, beside Tomorrow's
   blue. The chevron follows the house convention (`CollapsibleSection.chevron`, E 2026-08-28):
   ▲ folded, ▼ open.

**Not shown by a frame: the pinned header over scrolled rows.** Four tasks do not fill the screen at
the default size, so nothing scrolls there. At Accessibility XL, two drag shapes were tried. One
started on a row at the bottom edge and became the Home gesture (that frame showed SpringBoard and
was deleted). The other was claimed by the row's own swipe gesture, and nothing scrolled. The
surface is instead guarded by `TasksAnytimeRowCallSiteTests.testThePinnedFoldIsPaintedThePage`,
which red-check H proved catches its removal. It is the same `PinnedHeaderMetrics` surface every
pinned header uses, and it is item 14 of E's phone pass (`handoff/ARC-REVIEW-D.md`).

## Throwaway data

Each run made one emulator account and one task in it ("Book the MOT ####"). The emulator is local,
was started from the imported audit state and never exported back, so nothing persists past its
shutdown. The simulator was erased after the UI runs (CLAUDE.md: a UI run signs the simulator in).

## Files

| file | what it proves |
|---|---|
| `00-collapsed-L.jpg` | Light, default size: "ANYTIME · 2 ▲", last on the board, no rows under it. |
| `01-new-task-counted-L.jpg` | After adding an undated task: "ANYTIME · 3", still folded. The count carries the new task. |
| `02-expanded-L.jpg` | Opened ("▼"): the new task and the two seeded ones, with no ▶ on any. |
| `03-collapsed-D.jpg` | Dark, default size: the same fold. |
| `04-new-task-counted-D.jpg` | Dark: the count moves to 3 with the fold closed. |
| `05-expanded-D.jpg` | Dark: opened. |
| `06-collapsed-A.jpg` | Accessibility XL: the header scales and stays on one line, still 44pt tall. |
| `07-new-task-counted-A.jpg` | Accessibility XL: counted, still folded. |
| `08-expanded-A.jpg` | Accessibility XL: opened. The rows' mid-word breaks ("10- / minute") predate this block and belong to `F-B2-AX3Layouts`. |
