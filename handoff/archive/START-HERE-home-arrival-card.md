# Start here — E's next item: the "You're at home" card vanishes on drag-reload. Investigate FIRST, then ask.

*Paste into a fresh Claude Code terminal. Written 2026-09-08 at the close of the session that
shipped `F-TabBar-SelectPill` (PR #29, three device rounds, merged; `main` @ `76a4f47` for the
code, `e09f87f`+ for the close-out docs). E's phone was reinstalled FROM MAIN. The 39 spent
`.xcresult` bundles were deleted on E's word, so CLAUDE.md's documented test command works
verbatim again.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## The one instruction that matters

**E's direction, closing the last session:** *"in the next session i want to deal with the
'You're at home' card vanishing on drag-reload as i noted earlier in this session."*

E's original words, mid-session, looking at a Today screenshot with the card showing:
> *"the 'YOU'RE AT HOME' notification box at the top of the Today page does not stay there when
> the user drag-reloads the Today page. Which is kind of pointless."*

This is E's item and E's design authority. **Your first move is to INVESTIGATE, not to build** —
there are two candidate mechanisms and they lead to different fixes, one of which is "nothing
is wrong". Establish which one E is seeing, put it to E in one question, then design.

## What the code says (read first-hand this close-out, `main` @ `76a4f47`)

The card is the **arrival surface** — `ADHD LifeOS/Places/ArrivalSurface.swift`. Its rule, in
its own doc comment and pinned by tests: **NO card unless there is something open AT this
place** — `make(currentPlace:tasks:)` returns nil when the place is nil OR when no task with
`atPlaceId == place.id` is `.open`.

Pull-to-refresh on Today is `HomeView.swift:345` → `.refreshable { await refreshEverything() }`.
`refreshEverything()` (`HomeView.swift:363`) reloads home / nudges / inbox in parallel, then
**`await refreshArrivalSurface()`** (`HomeMomentumSections.swift:356`), which:

```swift
refreshLiveRoutine()
let place = await CurrentPlaceResolution.current()     // a FRESH When-In-Use location fix
arrivalSurface = ArrivalSurface.make(currentPlace: place, tasks: homeService.allTasks)
```

`CurrentPlaceResolution.current()` (same file as `ArrivalSurface`, further down) is one
foreground fix — no fences, no Always — and "nil at every failure — no permission, no fix, no
named place, nothing open here — and nil simply means no card."

**So the two hypotheses:**

- **(a) The refresh THROWS AWAY a card it already had.** On the pull, the fresh fix fails, times
  out, or lands just outside the place's radius (indoors is the classic), `current()` returns
  nil, and `arrivalSurface` is set to nil — the card that was correct a second ago is gone.
  This matches E's words exactly ("does not stay there when the user drag-reloads"). The fix
  shape would be: a failed re-resolution KEEPS the previous surface rather than clearing it
  (and probably re-checks the task list against the previous place), with the pure rule for
  "what does a refresh do to an existing surface when the fix is nil" pinned in a test.
  `CurrentPlaceResolution.current()`'s timeout / accuracy path is the thing to read next.
- **(b) The card is honestly gone because its one task was CLOSED.** E's own screenshots from
  last night show it: `screenshots/tabbar-select-pill/02-…` (04:41) has the card — *"1 thing
  lives here · september"* — and `08-…` (05:41) has **no card and "1 OF 6 CLOSED"**, i.e. the
  task at Home was closed in between. Under the rule above, no card is CORRECT then. If this is
  what E saw, the question for E is whether the rule should change ("show the place even with
  nothing to do here"), which the rule's doc comment argues against ("ambient truth on Today is
  noise") — E's call, not yours.

Both can be true at once. **Do not guess which:** reproduce (a) on the phone or in a signed-in
sim with an OPEN at-place task and a pull, and ask E what state the task was in when they saw
it vanish. The `Places/` folder has the resolution, the fence and the arrival-nudge code;
`ADHD LifeOSTests` has `ArrivalSurface` tests to extend — TDD, the pure rule first.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (every change lands through a PR; `main` is
   protected), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **eighth edition** (this
   item is B1, AUTHORISED by E as the next session's first job).
4. **`handoff/SESSION-OPENER-location-services.md`** and the `location-services-spec` memory —
   the arrival card's origin ("variation B, block 4c"), and why it is the gentlest surfacing.
5. **`handoff/SESSION-OPENER-tabbar-select-pill-design.md`** — the newest settled design
   record and the house style for one; its round-3 lessons on measuring and probing apply to
   any on-device geometry question.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect e09f87f or later (close-out PRs are docs-only)
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 711 files
ls -d *.xcresult                     # expect NONE — deleted on E's word 2026-09-08
```

Last verified ON MAIN at `76a4f47`: unit suite **2,505 / 0** (emulator up), lint **0 / 711**,
sim build green, app target **24.77% (11,133/44,940)**. **E's phone tracks main at `76a4f47`**
(every merge since is docs-only). Free-dev-account profile roughly valid to **2026-09-15**.

## Traps that matter right now

- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. The tab-bar PROBE app (`com.probe.tabbar`) is still
  installed on that sim; an erase clears it. No UI target ran last session; 0 `9099` hits.
- **Reproducing (a) needs a signed-in session with a place and an open at-place task.** A
  signed-in SIM is the tool (`relaunch-before-judging-device` memory) — and under
  `never-automate-auth-flows` that means STOP and ask E to sign the sim in, then drive it.
  Location on the sim: `xcrun simctl location <udid> set <lat>,<lon>` puts you "at" a place;
  moving it outside the radius before a pull is exactly hypothesis (a).
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding; inject
  regressions ONE AT A TIME (two cancelled last session).
- **Geometry questions: probe first, theory second** (design record, round 3), and a
  `CGContext` bitmap is TOP-DOWN.
- **iPhone Mirroring cannot be started from the terminal**; E's own screenshots, filed with
  README rows, are the working evidence route.
- **Never automate auth.** The emulator was left running.
