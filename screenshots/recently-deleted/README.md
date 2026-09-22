# `F-C3-RecentlyDeleted` — a delete you can take back, and the one you cannot

**Environment:** iPhone 17 Pro simulator, **iOS 26.5**, Firebase **Emulator Suite** (the audit's
exported state, `scripts/audit/emulator-state`), three throwaway accounts created by the harness
per run, 2026-09-22. Frames are `app.screenshot()` attachments from
`ADHD LifeOSUITests/RecentlyDeletedRenderUITests`, exported with
`xcrun xcresulttool export attachments` and converted to JPEG (CLAUDE.md's "Visual evidence":
these are looked at, not sampled). Light and dark are the same journey run twice with
`xcrun simctl ui booted appearance light|dark` between them — both runs **3 tests, 0 failures**.

**Verified paths:** this block added **no `#available` site and no reduced site**, so there is no
tier table and **no RM-on device pass is owed** (§7.3). The new screen draws plain `.bentoCard()`
rows with no animation of its own; the only motion on it is `MomentumBorderedButtonStyle`'s press
scale, which shipped long before this block. The capsule's motion is `F-C1`'s and untouched — that
pass PASSED on 2026-09-20. These frames are the default Reduce Motion state.

## Why this folder exists — what driving the real screens caught that the tests could not

**Three things, and the first is the one that would have shipped.**

1. **Two assertions passed on a build that had not deleted anything.** The harness first wrote the
   delete as `tap(deleteButton, untilGone: titleField)`, and `UITestSession.tap(_:untilGone:)`
   returns `true` on its FIRST LINE when the doomed element is already absent — without tapping.
   Scrolling a `Form` down to the Delete button takes the title field out of the hierarchy, so the
   condition was satisfied by the SCROLL. The follow-up, `row.waitForNonExistence`, then passed for
   the mirror-image reason: the run was still on task detail, where no task row exists. Two green
   assertions, no delete, and `03-` was a photograph of a tab transition captioned as a deleted
   list. **The emulator settled it** — a `runQuery` with `Authorization: Bearer owner` found
   `deleted_at` on **no document in the project**, which is not something a screenshot could show.
   Rewritten, every step here waits on something POSITIVE; an absence is only ever asserted beside
   a presence.

2. **`tap(_:untilExists:)` fails the same way from the other side, and the second delete proved
   it.** Switching the signal to "the capsule appeared" fixed the first delete and broke the
   second: a capsule from the first delete was still pending, `tap(_:untilExists:)` returns
   immediately when its expectation already holds, and so the second delete never happened either.
   The nav bar is what both now use — pinned, so scrolling cannot remove it, and owned by THIS
   screen, so nothing left over can satisfy it. Delete forever then moved to its own run with a
   task seeded already-stamped, which removes the interaction entirely.

3. **A push that has not settled reports frames on the wrong page.** `openTab` returns as soon as
   the tab reports `isSelected`, and `scrollUntilHittable` will call a button hittable on a frame
   still in transit. XCUITest then put `taskDetailDeleteButton` at **x ≈ 10016** — a screen width
   times the tab index — and a plain tap failed with *"Failed to not hittable"* while a coordinate
   tap (tried as a fix) landed on real screen coordinates belonging to the **Areas tab**, which is
   where one run ended up. Intermittent, roughly half of runs. Waiting for the pushed screen's own
   nav bar to come to rest fixed it; three runs green since.

**What none of the three is:** an app defect. Every one was the harness photographing the wrong
moment, and the app behaved correctly throughout — which is exactly why they are recorded here
rather than in the register.

## One more thing the frames settle, which no assertion states

`05-` shows the capsule **still pending while the Recently Deleted screen is open**, offering Undo
for the same task the screen is listing with a Restore button. Two routes to one reversal, on
screen together. That is the shared-slot design working as intended (`F-C1`: one bottom bar
everywhere), and it reads fine — but it is the sort of thing only a photograph shows.

## The frames

Each row is one claim. Every name has a `-light` and a `-dark` twin.

| file | what it proves |
|---|---|
| `00-tools-row-nothing-waiting` | The Recently Deleted section is drawn **even when nothing is waiting** — a door that hid itself when empty would be missing at exactly the moment someone goes looking for it. Note the subtitle is *"Nothing waiting"*, not a count of zero. |
| `01-tasks-list-holds-the-task` | The seeded task, live and listed. The baseline `03-` is measured against. |
| `02-task-detail-delete-button` | The Delete button, **with no confirmation dialog behind it** (E's 2026-09-22 call). |
| `03-tasks-list-without-it-and-the-capsule-offers-undo` | **The block's central claim.** One tap, and the task is gone from Tasks while the capsule reads *"Deleted · ↶ Undo"*. The document still exists; only the stamp hides it. |
| `04-tools-row-one-item-thirty-days-left` | The Tools row counting it: *"1 item · 30 days left"*. Singular, and the countdown is derived from `SoftDelete.retention`. |
| `05-recently-deleted-holds-the-task` | The screen: the row with its kind and countdown (*"Task · 30 days left"*), **Restore as a visible 48pt bordered button** (round 7's rule — never swipe-only), and Delete Forever beside it, quiet. |
| `06-restored-and-the-screen-is-empty-again` | Restore erased the stamp; the screen falls to its empty state, which teaches the 30-day rule rather than going blank. |
| `07-the-task-is-back-in-the-tasks-list` | The round trip closed — **the same task id**, back where it left, with its own data intact because it never actually went anywhere. |
| `08-delete-forever-is-the-one-confirm-that-stays` | The one confirmation left in the delete flow, and the one place *"This can't be undone."* is **true**. Q10's sanctioned friction. |
| `09-deleted-for-good-and-the-list-is-empty` | The document is gone. This is the only irreversible operation the app can reach. |

## Throwaway data

Three accounts per appearance (six in all), created by the harness through the Auth emulator and
left in the emulator's state: labels `recentlydeleted`, `recentlydeletedempty` and `deleteforever`.
Nothing was written to the live Firebase project — `FirebaseEmulatorSettings` turns emulator mode
on only for the Test action's `LIFEOS_FIREBASE_EMULATOR_HOST`, and
`FirebaseEmulatorHarness.requireEmulator()` fails loudly in the one state where a test could reach
production. The emulator's state is not committed, so nothing needs cleaning up in the repo.
