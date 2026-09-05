# Start here — SCOPING Routines

*Paste this into a fresh Claude Code session. Written 2026-09-03, off `main` @ `218d289`.*

**Your job this session is to SCOPE, not to build.** E has asked for scoping. Do not create a
branch, do not write Swift, do not add FEATURE blocks to `TODO-CLAUDE-CODE.md` unasked. The
deliverable is a design E can react to — the same way the Tools tab and bottom-search arcs were
settled, which is by E judging concrete options rather than prose.

---

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc`,
`place-actions-arc`, `app-directory-arc-design`, `location-services-spec`,
`tools-tab-and-custom-bar`, `bottom-search-arc`, `show-dont-describe-geometry`,
`dead-shared-component-pattern`, `never-automate-auth-flows`.

## State

`main` @ **`218d289`**, clean and pushed. **`main` is the ONLY branch** — `feature/tools-tab` and
`feature/bottom-search` were both merged and deleted on E's word, 2026-09-03.

```bash
git status --short          # must be empty
git log --oneline -1        # 218d289
git log --oneline -1 origin/main   # same SHA
git branch -a               # main / origin/main only
```

Suite **2,202 / 0** (56 skipped = emulator suites, by design), SwiftLint **0 / 631**, sim + device
builds green, E's iPhone `wishwashwacky15` on `218d289`.

## What Routines is, in E's own words

E, 2026-09-02: *"park it as the top most high interest feature that we should investigate plan and
build once we finish this current section/task at hand."* It is now unblocked.

E's example, verbatim: **"Open Snapchat at the gym > Open gym app + Open Spotify playlist called
'Gym Music'"** — a location trigger firing an **ordered routine of steps**.

This came out of E correcting a wrong assumption of mine: I had called the app directory's long
tail purposeless ("'open Snapchat at the gym' was never going to serve a purpose"). E's model
reframes the directory entirely — its entries are **the vocabulary of routine steps**, not filler,
which is also why E chose to hold off culling it.

## What already exists — verified in the tree at `218d289`, not remembered

**A place already holds multiple actions and already runs them on a crossing.**

- `Place.actions` is `[PlaceAction]` (`Places/PlaceModels.swift:56`). **There is NO `sortOrder`
  field on `PlaceAction`** — its stored properties are `id`, `direction`, `kind`, `extraPayload`
  (`Places/PlaceActionModels.swift:88-95`). So order exists only as array order, and nothing in
  the editor lets E change it. **That is a real scoping question, not a detail.**
- `PlaceActionPlan.split` (`Places/PlaceActionExecution.swift:23`) sorts a crossing's actions two
  ways:
  - **autoRun** — `journalLine`, `createCapture`: run silently, any number, no tap.
  - **external** — `openApp`, `openLink`, `openURL`, `textContact`, `startSprint`, `openScreen`.
- `PlaceTriggerEventHandler.swift:95` is the line that matters: **`for action in plan.external`**,
  posting **one notification per action**.

**So E's gym routine already runs today — and arrives as three unordered notifications.** No
sequence, no progress, and tapping one strands the other two. That is the problem to solve.

## THE CEILING THAT SHAPES EVERYTHING — do not design around it, design *with* it

**iOS cannot chain app-opens.** A backgrounded app cannot launch another app; only a user-initiated
tap opens one, and each tap opens exactly one. The instant Snapchat opens, LifeOS is backgrounded
and cannot launch the next step.

**N app-opens therefore require N user taps. Always.** This is a platform floor, not a missing
feature, and no amount of design removes it. Any proposal that quietly assumes auto-advance is
wrong — say so out loud rather than discovering it in a build.

Related constraint already learned the hard way (`0c65ca5`): the first `UIApplication.open` must be
**synchronous** on the notification-response callback or the tap loses its user-initiated
attribution and silently fails to open anything.

## The shape that IS possible — the starting proposal, not the answer

**ONE notification for the crossing → tapping it opens LifeOS on a routine screen**: the steps in
order, big buttons, progress ticked as each completes. E taps step 1, the app opens, E comes back
to LifeOS, the list is still there with step 1 done, taps step 2.

That converts an impossible auto-chain into an externalised, ADHD-friendly checklist — order is
visible, nothing has to be held in the head, and **returning mid-routine is the normal case rather
than a failure**. Treat this as the strongest starting point, and test it against E rather than
assuming it.

## The open questions worth putting to E

These are the scoping decisions. Do not answer them alone — several have no obviously right answer.

1. **Is a routine a first-class object, or just "the place's actions, ordered"?** First-class means
   a `routines` collection, a name, reuse across places, and running one manually with no crossing
   at all. Ordered-actions means no new model and no new screen in Tools — but no routine that
   isn't tied to a place either.
2. **Ordering UI.** `PlaceAction` has no `sortOrder` today. Adding one is a schema change to a
   per-user subcollection (see `CLAUDE.md` on the ten subcollections and `firestore.rules`), plus
   drag-to-reorder in `PlaceActionsEditorView`.
3. **What happens to the existing per-action notifications** — replaced by the single routine
   notification, or does a place opt in? A silent behaviour change to something E already uses in
   the field is worth asking about rather than assuming.
4. **Resumability.** If E leaves the routine half-done and comes back an hour later, is it still
   there? Overnight? Does it expire? Where is that state kept?
5. **Do autoRun steps appear on the list already ticked?** They ran without a tap; showing them
   ticked tells the truth about what happened, hiding them keeps the list to what E must do.
6. **Where does the editor live?** Tools is now a real page with exactly two cards (Places, Life
   Areas) and was deliberately left sparse **so Routines has an obvious home** — see
   `Tools/ToolsCatalog.swift`. That was E's stated reason, so it is a strong default, not an idea.

## How E wants to be asked — this is the part that will decide the session

**Show, don't describe.** E's exact feedback, 2026-09-03, after a four-question `AskUserQuestion`
about button geometry: *"those questions you just asked me were rather confusing... Visual
examples/visual graphics would make it much easier to understand what you are describing."*

- For anything about layout or screens: **render it and send the image**, or send a diagram
  labelled with real numbers. Cramped ASCII previews of abstract options confused E.
- The auth-free `swiftc` probe technique (see `tabview-folds-past-five`) compiles a standalone app
  against the **real `Assets.xcassets`** via `xcrun actool` and needs no signed-in session. It is
  how the tab bar, the Tools page and the pinned headers were all settled.
- Prefer **one before/after comparison** over three abstract options. E chose confidently every
  time a render was on the table.
- E answers `AskUserQuestion` well when the measurement or the concrete consequence is **in the
  question text**, not hidden inside preview art.

## Two habits this project earned the hard way

- **MEASURE THE RENDER, do not reason about it.** Decode the PNG in Python (`zlib` + the filter
  loop — no PIL on this machine), sample a row or column, quantise, print colour BANDS with point
  ranges. This found: a header that was never opaque, a capture disc overlapping the tab bar by
  7pt, and an iOS 26 search capsule hiding under the custom bar. In each case reasoning had given
  the wrong answer first.
- **A probe that has drifted from the real view is worse than no probe.** If you hand-add
  something to a probe that the app does not have, stop trusting it and say so.

## Standing rules

- **This is a scoping session.** No branch, no Swift, no TODO edits unless E asks.
- If E green-lights a build afterwards: branch off `main`, TDD (failing test first for all new pure
  logic), commit AND push every block, and paste the close-out triple (`git status --short`, local
  HEAD, `origin/<branch>` at the same SHA).
- **Never script an auth flow.** There is no signed-in simulator; if one is needed, stop and ask E.
- **Never pipe a long `xcodebuild` through `grep`** — log to a file and grep the file, run it
  backgrounded, and poll. The result-bundle step routinely outlives a 2-minute foreground timeout
  even when the tests finished in ~6s.
- `swiftlint lint` at 0. Watch `file_length` (400) and `type_body_length` (250) — **`CaptureInboxView`
  is AT the 250 ceiling**, so anything touching it must move code out rather than add.
- Device `wishwashwacky15`, id `3DBC979A-3255-5456-8C30-172DB19B99B3`: build with a scratch
  `-derivedDataPath`, then `devicectl device install app` → `devicectl device process launch
  --terminate-existing`. Force-quit before judging an install-over-running app.
- **Report the §7 conflict in any build report** (`ui-ux-pro-max` rates "bottom nav ≤5" HIGH
  severity; E chose six knowingly).

## One live warning from the arc that just closed

**A feature can be correct and still be in the wrong place.** The bottom search row shipped on
Tasks, was extended to Captures, and E rejected it on sight: the Captures tab is a one-at-a-time
*decision* screen whose bottom half IS the decisions, so a floating field landed on top of them.
It was reverted whole (`72e7b77`, reverted at `bebb578`) rather than left unwired.

The generalisation is worth carrying into Routines, which will also want screen real estate:
**furniture suits a scanning surface, not a deciding one.** Ask where a routine screen actually
lives before assuming it can share space with something else.
