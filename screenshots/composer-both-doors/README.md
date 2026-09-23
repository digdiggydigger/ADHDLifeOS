# composer-both-doors — `F-D1-ComposerBothDoors`

**Environment:** iPhone 17 Pro simulator, iOS 26.5, default text size (`content_size large`),
light and dark. Firebase Emulator Suite (auth + firestore + storage, imported from
`scripts/audit/emulator-state`). A fresh throwaway account per run (`composerdoors-…@…`), created
and signed in by the harness and seeded with the production starter areas. 2026-09-23.

**Produced by** `ADHD LifeOSUITests/ComposerBothDoorsRenderUITests`, run once on the pre-block tree
(`26386cd`'s parent, the harness commit `cffdda9`) and again on the finished block, with
`xcrun simctl ui booted appearance light|dark` between runs. Exported with
`xcrun xcresulttool export attachments`, converted to JPEG. The simulator was erased after every UI
run.

## What the frames settle that a test could not

- **E's round 6, "One composer, both doors", as a person meets it.** `01`/`02` are two unrelated
  composers behind the two doors; `03`/`04` are one. The harness LABELS each frame from the
  hierarchy it found, not from a flag. The old fan composer is `quickCaptureContentField`, and the
  old Tasks "+" composer has `taskCreateNotesField`. So `before-`/`after-` is a claim the app made.
- **The "no forced date" win.** `02-before` says **"Add to Today"**, because the fan's Task path wrote
  `startOfDay(now)` on every create (CAPT-02). `04-after` opens on **"Not yet"**, and nothing is dated
  unless a when-chip says so.
- **The disc's door fetches its own areas.** `RootView` holds no area array, so the composer is given
  a `homeClient`. `04-after`'s Area row reads "None" with areas behind it (`05`). The old fan composer
  had not loaded its area chips when `02-before` was taken.
- **Same view, two chromes, and that is inherited rather than chosen.** `03` is a `.sheet` (the
  Tasks tab), and `04` is a `.fullScreenCover` (the capture disc). The block did not pick either.

## The finding a frame caught (and every other gate missed)

The first after-run of this harness failed on `taskCreateLifeAreaPicker`, which measured
**338 × 20.3pt**. The card had been padded and sized from OUTSIDE each `Menu`. It DREW 48pt tall,
but a `Menu`'s hit area is its label, so only the line of text took a tap. The picture looked
right, and the suite, lint and build were all green. The row is now sized inside the label
(`LifeAreaPicker.popUpRowHeight`, `TaskCreateView.menuRowHeight`). The harness asserts that both
the Area and Time frames are ≥ 48pt. The fixed build measured 47.99999999999994, which is 48 on
screen, so the check allows half a point.

## Files

| file | what it proves |
|---|---|
| `01-before-tasks-plus-composer-L/D.jpg` | The Tasks "+" composer before: due chips, an area chip flow with "Decide later", notes, and tags below the fold. |
| `02-before-disc-task-composer-L/D.jpg` | The disc's Task tile before: a DIFFERENT composer with effort chips, tags, and "Add to Today", the forced date. |
| `03-after-tasks-plus-composer-L/D.jpg` | The Tasks "+" composer after: title, the four when-chips, and Area and Time menus. No tags, place or notes. |
| `04-after-disc-task-composer-L/D.jpg` | The disc's Task tile after: the SAME composer, as a full-screen cover, opening on "Not yet". |
| `05-after-area-menu-open-L/D.jpg` | Area is a pop-up menu, not a sheet: "None" first and ticked, then the areas. |
| `06-after-time-menu-open-L/D.jpg` | Time is a pop-up menu: 15 min (the default, ticked), 30 min, 1 hr. These are the fan's old three chips, ported. |

**No throwaway data is left behind that matters.** Each run's account lives only in the local
emulator, and the two doors were each closed empty, so no draft was filed and no task was created.

**Not covered here:** Accessibility text sizes (AX3). That layout is `F-D2`'s, and its fallback
is part of that block's acceptance.
