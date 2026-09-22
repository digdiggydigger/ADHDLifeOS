# `F-C4-TagsRecentlyDeleted` — a tag hidden without being unlinked, and one frame that found a bug

**Environment:** iPhone 17 Pro simulator, **iOS 26.5**, Firebase **Emulator Suite** (the audit's
exported state, `scripts/audit/emulator-state`), three throwaway accounts created by the harness
per run, 2026-09-22. Frames are `app.screenshot()` attachments from
`ADHD LifeOSUITests/TagsRecentlyDeletedRenderUITests`, exported with
`xcrun xcresulttool export attachments` and converted to JPEG (CLAUDE.md's "Visual evidence":
these are looked at, not sampled). Light and dark are the same three journeys run twice with
`xcrun simctl ui booted appearance light|dark` between them — both runs **3 tests, 0 failures**.

**Verified paths:** this block added **no `#available` site and no reduced site**, so there is no
tier table and **no RM-on device pass is owed** (§7.3). The survivor alert is a system `.alert`
and the capsule's motion is `F-C1`'s, untouched. These frames are the default Reduce Motion state.

---

## Why this folder exists — what driving the real screens caught that the tests could not

### 1 · THE FINDING: the Undo capsule is mounted but INVISIBLE in the Tag Editor

**Look at `01-deleted-and-the-capsule-offers-undo-*.jpg` and notice what is NOT in it.** The tag
`errand` has gone from the list — the delete landed. There is **no capsule**. There is also **no
tab bar**, and that is the tell: Settings is a `.sheet` presented from Today, and the undo capsule
lives in `RootBottomOverlay`, the same app-level layer the tab bar is drawn in. The sheet covers
both.

**Every gate was green while this was true, and that is the point of the frame.** The harness
asserts `tap(deleteButton, untilExists: capsule)` and it PASSES — XCUITest finds elements in the
accessibility hierarchy whether or not anything is drawn over them. `ADHD_LifeOSApp.swift:251`
explains exactly why the recording half works: `.environment(\.recordAction, …)` is applied
outside every cover and sheet, so a site inside one can still RECORD. Inheriting the environment
is not the same as being drawn, and nothing in the suite can tell the two apart.

**This is the failure mode CLAUDE.md already documents, for a different layer.** The Celebrations
section says a burst is "drawn by one layer PER PRESENTED SURFACE", with four mounts *counted* by
a test, "because the failure mode of per-surface layers is silent: a cover that hosts a site and
mounts no layer draws nothing and passes every other test." The undo capsule has one mount, and
the Tag Editor is behind a sheet.

**Why it matters rather than being a curiosity.** E was asked on 2026-09-22 whether the tag
delete should keep its confirmation, and chose **"drop the alert, add an Undo capsule"** over
"drop the alert, no capsule" — the latter being the option whose named cost was *"it's the one
option that gives no feedback at the moment of the delete."* As shipped, the Tag Editor delivers
that second option. **This is E's call to make and is recorded in the register**, not fixed here:
mounting an overlay on a sheet changes app-wide furniture, and every constant in that furniture is
E-approved.

### 2 · A tag's links genuinely survive, and the restore proves it with no write to the task

`02` → `05` is one journey on one account. The task document is written **once**, at seed time,
and never again. Its tag arrives already stamped, so `02` shows the task with no chip; `04` shows
the tag restored from Tools; `05` shows the chip back on the task. Restoring writes one field on
the TAG and nothing on the task — so a chip that reappears is proof the `tag_ids` array was never
touched. Had the delete stripped the links, `05` could not exist.

**Seeded rather than deleted through the UI, and that is a strength.** Driving the delete would
prove the button works; this isolates the only thing the block changed.

### 3 · The survivor alert, and why its two buttons are not the same word twice

`06` is a restore onto a name that was taken while the tag waited. Both tags are seeded — one
deleted `errand`, one live `Errand` — because the collision folds case while the app renders the
stored case. The two buttons quote the two spellings, which is the whole reason E's *"ask which
one survives"* is a choice rather than a confirmation. (When the two spellings are IDENTICAL the
alert collapses to `Merge` + `Cancel`; that shape is unit-tested in
`RecentlyDeletedSurvivorChoiceTests` rather than photographed, because it differs only in copy.)

---

## Three harness traps this folder paid for — all of them already written down, all walked into anyway

1. **`quickCaptureButton` EXISTS from the first frame and is never HITTABLE.** It is a floating
   overlay outside the tab content, so `settle` (which waits on `isHittable`) times out against an
   app running perfectly. Both journeys died at 144s and 166s having photographed nothing.
   `RecentlyDeletedRenderUITests` waits on existence alone for this same anchor.
2. **`tap(_:untilGone:)` returned true WITHOUT TAPPING — trap #1 from the C3 harness's own
   header.** Popping back from task detail was written as `untilGone: titleField`, and scrolling
   the Form to the tags section had already taken that field out of the hierarchy. The pop never
   happened and task detail was carried into the next step. **An absence the previous step caused
   is not a signal.**
3. **Waiting on a row that is below the fold reads as "the screen never opened".** The gear was
   tapped, Settings opened correctly, and the harness went on retrying against
   `settingsTagEditorRow` — section 5, absent from the hierarchy until scrolled to. Its own
   diagnostic frame showed Settings open, which is what settled it. The fix is to wait on the
   SHEET (`settingsDoneButton`) and scroll to the row afterwards.

Also: a `Form` builds rows lazily, so a tag chip below the fold is genuinely absent and reads as
"the tag was never attached"; and `openTab` returns early when the tab is already selected, so from
a pushed screen it never taps and never pops.

## Throwaway data

Three accounts per appearance (`tagsrestore@…`, `tagsurvivor@…`, `tagsdelete@…`), created by
`UITestSession.createAccount` in the **emulator only** — `FirebaseEmulatorSettings` resolves a
malformed host to *off* rather than to a default, and the scheme sets the variable on the Test
action alone, so none of this can reach the live project. They are left in the emulator's state,
as the C3 runs' accounts were; the emulator is disposable and re-imported from
`scripts/audit/emulator-state`.

## The frames

| file | what it proves |
|---|---|
| `00-the-tag-editor-lists-it` | The starting state: `errand` is live and listed with its usage count. |
| `01-deleted-and-the-capsule-offers-undo` | **The finding.** The delete landed — `errand` is gone — and the capsule is nowhere on screen, because the Settings sheet covers the layer it lives in. The missing tab bar is the tell. |
| `02-the-tag-is-hidden-so-the-task-shows-no-chip` | A task whose `tag_ids` still names a stamped tag draws no chip for it. The add-tag chip beside it proves the row is rendered, so the absence means something. |
| `03-recently-deleted-holds-the-tag` | The tag is in the 30-day list, with the same countdown and the same 48pt Restore button C3 built. |
| `04-restored-and-the-screen-is-empty-again` | Restore landed and the row left only once the write had. |
| `05-restored-and-the-chip-is-back` | **The block's central claim.** The chip is back on a task nothing ever wrote to. |
| `06-restoring-onto-a-taken-name-asks-which-spelling-survives` | E's *"ask which one survives"*: two buttons quoting `errand` and `Errand`, because the collision folds case and the app does not. |
| `07-merged-and-the-list-is-empty` | The merge landed and the row is resolved. |

Each exists in `-light` and `-dark`.
