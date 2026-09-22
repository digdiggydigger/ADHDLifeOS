# `F-C2-DraftsToInbox` — unsent text caught by the inbox, and the gesture that was unblocked

> **Produced one session late, and recorded as such.** `F-C2` merged on 2026-09-20 (PR #180) with
> this folder as its one unmet acceptance criterion — the block was settled by assertion rather
> than by looking. These are the frames it owed, rendered from `main`'s merge of that block with
> no app code changed since (`git diff 4917955 bc2827e` touches `handoff/` only).

**Environment:** iPhone 17 Pro simulator, **iOS 26.5**, Firebase **Emulator Suite** (the audit's
exported state, `scripts/audit/emulator-state`), two throwaway accounts created by the harness per
run, 2026-09-22. Frames are `app.screenshot()` attachments from
`ADHD LifeOSUITests/DraftsToInboxRenderUITests`, exported with
`xcrun xcresulttool export attachments` and converted to JPEG (CLAUDE.md's "Visual evidence":
these are looked at, not sampled).

**Verified paths:** this block added no `#available` site and no reduced site, so there is no tier
table to report and **no RM-on pass is owed** — the capsule's motion is `F-C1`'s and untouched
(that pass PASSED on 2026-09-20). The frames are the default Reduce Motion state.

## Why this folder exists — what driving the real screens caught that the tests could not

Three things, and none of them is assertable.

1. **The Journal has no compose control at all while a capsule is pending.** On that screen the
   capsule STANDS IN for the pencil disc rather than sitting beside it (E's `F-C1` Step 0 answer
   4, the claim `../undo-capsule/03-` was rendered to confirm). Every unit test was green and the
   first run of this harness simply could not find `journalComposeButton` — it failed with *"The
   journal composer never opened"*, which reads like a broken composer rather than a screen
   deliberately giving its slot away. It is the intended consequence of E's "one bottom bar
   everywhere", **but `F-C2` changed how OFTEN it happens**: before this block only a close or a
   triage made a capsule, and now any composer closed on text does. `02-` and `04-` are what the
   Journal looks like in that state — the + disc present, the pencil gone.
2. **"Reopen" lands on a PUSHED screen, and it is the right one.** `07-` is the capture's own
   detail inside the Captures tab's stack, reading *"Draft from the task composer"* — the draft
   that was pending, not merely the tab it lives on. No assertion in the block distinguished
   "opened the capture" from "opened the tab". It also cost this harness 45 seconds to learn that
   a `navigationDestination` is not a sheet and does not answer a swipe-down.
3. **The left-edge swipe really does pop task detail, with no dialog** — `10-` is a frame of
   something NOT being there, which is the only way to photograph a deleted modal. `11-` is the
   payoff: the edit made in `09-` and never explicitly saved is on the reopened screen.
4. **`F-C1`'s radius cap holds for a WIDER control, and that had to be rendered to know.** The
   AX3 set is here for one reason: `F-C1`'s render caught a Critical because a `Capsule`'s radius
   is derived from its height, so at accessibility sizes the card is a different shape — 6,329
   pixels of glyph and 2,604 of the ↶ Undo control were drawn outside it, and E capped the radius
   at `minHeight / 2`. **`F-C2` then put a wider control into that same derived-geometry card**:
   "↗ Reopen" against "↶ Undo". `04-…-AX3` is the answer — glyph, verb, subject and the Reopen
   control all sit inside the card's fill, nothing clipped and nothing outside. The cap covers the
   new label; no re-render of `F-C1`'s decision is owed.

## One thing to look at that is not a defect and not settled

**The selected Captures tab reads "Captu…" in `07-` and `08-`** — the resting pill's label
truncating rather than scaling.

**The first version of this note blamed the badge, and that was wrong. Corrected 2026-09-22 from
E's own device frames.** The badge is an `.overlay` and consumes no layout width at all; what
clamps the pill is `AppTabBarMetrics.maximumRestingPillWidth = 120`, whose own comment predicts
this exact spot: *"'Captures' — the longest label — needs ~115pt at the default size … so the cap
bites only towards the top of the range, where the label's `minimumScaleFactor` (0.8, so down to
~110) absorbs it (§1: never clip, never truncate)."*

**And E's phone does not reproduce it.** On E's iPhone 15 Pro the resting pill renders "Captures"
in full with a two-digit badge (`IMG_8703`), and the label is absent entirely while the bar is
floating — which is Design C working as specified: `AppTabBarPresentation.showsLabel` is
`isSelected && !isFloating`. So the observation is **simulator-only in the evidence available**,
at default text size on an iPhone 17 Pro, and it is a deviation from the cap's documented "never
truncate" intent rather than a behaviour anyone has seen on a real phone.

Recorded, not re-tuned: every constant in the custom `AppTabBar` is E-approved and CLAUDE.md §7.5
is explicit that a review may name the tension and never re-tune it. **A register candidate worth
one measurement** — what "Captures" actually measures at default size against the 120pt cap — not
a fix in this folder. At AX3 every tab label shortens the same way ("Jo…" for Journal), which is
the cap biting at the top of the range exactly as the comment says it should.

**Also visible in the AX3 set and NOT this block's:** the Journal timeline's own rows truncate
hard at accessibility sizes — `04-…-AX3` shows "captured" hyphenated across two lines as
"cap-/tured" beside a title cut to "Draft from the note c…". That is the Journal row's layout, not
the capsule's, and it belongs to the audit's **accessibility arc (B)** rather than here. Named so
a later session does not read these frames as evidence that `F-C2` caused it.

## Throwaway data

Two accounts per run (`uitest-draftstoinbox…`, `uitest-draftsswipeback…`), three `.note` captures
("Draft from the note / task / journal composer") and one seeded task ("Renew the passport"). All
of it lives in the Firebase **emulator**, never the live project; the simulator was **erased** at
close-out, which is also the fix for the signed-in-simulator trap that makes the next unit suite
crawl.

## The frames

Suffix is the appearance: `-L` light, `-D` dark, `-AX3` accessibility extra-large (set with
`xcrun simctl ui <udid> content_size accessibility-extra-large`, never a launch argument — see
`../undo-capsule/README.md` for why that distinction cost a round).

**The journey order is journal → note → task, and it is not arbitrary**: see reason 1 above. The
capsule is one slot, so each composer's capsule is photographed before the next is opened.

**The AX3 set took TWO runs, and the reason is a harness trap worth inheriting.** The composer
journey and the swipe-back journey are separate tests, and the second signs out of the account the
first left behind — at accessibility text sizes the taller Settings rows push `signOutButton` past
the harness's eight swipe attempts, and it fails with *"Settings opened but presented no sign-out
control"*, which reads exactly like a bug in the thing being photographed. A freshly erased
simulator fixes the FIRST test in a run, not the second. So `09-` to `11-AX3` come from a run of
that test alone on its own erase (`pass-swipeback-ax3.sh`'s own header records this).

**A second AX3-only discovery, and it was nearly recorded as a product defect.** `focusAndType`
taps a field to focus it, and at accessibility sizes that tap lands BETWEEN words rather than past
the end of a longer-drawn string: the AX3 run saved *"Renew the — and the visa passport"*, and an
equality assertion duly reported *"the edit did not autosave"* — which was false. **The autosave
worked; the caret did not go where the harness assumed.** The assertion now proves the two things
that are actually claimed (the edit survived, and it is still the seeded task) with CONTAINS.

| file | what it proves |
|---|---|
| `01-journal-composer-typed-*` | The journal composer with text in its body field, before anything closes it. The "before" half of the claim, and the only composer that has to be driven first. |
| `02-journal-closed-capsule-kept-in-your-inbox-*` | Closed on that text: the capsule reads **"Kept in your inbox"** over the draft's first line, with **↗ Reopen** as its control. E's round-2 words, drawn. The Journal's pencil disc is gone and the + disc has not moved. |
| `03-note-composer-typed-*` | The quick-capture note composer, opened from the capture disc — the `.fullScreenCover` route, which is the one a user meets first. (`QuickCaptureView` is presented twice; `.onDisappear` is what covers both.) |
| `04-note-closed-capsule-kept-in-your-inbox-*` | The same capsule for a note draft, still on the Journal because that is where the journey is standing. The subject truncates to "Draft from the note…" — **"Reopen" is a wider control than "Undo"**, so the draft kind gives back some of the 32pt `F-C1` reclaimed for the subject line. Not a defect: the label is E's own choice. |
| `05-task-composer-typed-*` | The task composer's title field with typed text, opened from Tasks. |
| `06-task-closed-capsule-kept-in-your-inbox-*` | The same capsule on **Tasks**, where it stands in for the search row rather than a pencil — the third of the three composers, one rule between them (`ComposerDraftFiling`). |
| `07-reopen-lands-on-the-filed-capture-*` | **The door, where it lands.** Reopen switched to Captures and PUSHED the capture's own detail, reading "Draft from the task composer" as a **Note** — E's Step 0 answer 1, confirmed rather than assumed. The badge reads 3. |
| `08-inbox-holds-all-three-drafts-*` | The inbox afterwards: **"To triage (3)"**, "3 left", "3 NOTES", "3 captured" — all three composers filed, as ordinary notes through the existing seam (which is why no `firestore.rules` change was owed). The first draft sits on the triage card; the other rows are below the fold. |
| `09-task-detail-edited-and-save-never-tapped-*` | Task detail with the seeded title edited to "Renew the passport — and the visa" and **Save never tapped**. |
| `10-swipe-back-popped-with-no-discard-dialog-*` | After a left-edge swipe: back on the list, **no "Discard changes?" alert**. The frame of the modal `F-C2` deleted, and of the gesture it had disabled working again. |
| `11-reopened-the-edit-saved-itself-*` | The same task reopened, with the typed words on it: the edit committed on the way out (`TaskDetailAutosave.shouldSave`), with no Save tap and no dialog anywhere in the sequence. `-L`/`-D` read "Renew the passport — and the visa"; **`-AX3` reads "Renew the — and the visa passport"**, because the focusing tap landed mid-string at that text size. Same proof, different caret. |
