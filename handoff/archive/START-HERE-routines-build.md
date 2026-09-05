# Start here — BUILDING Routines (Arc 1)

*Paste this into a fresh Claude Code session. Written 2026-09-03, off `main` @ `218d289`.
The design is SETTLED and the plan is audited — this session BUILDS.*

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc`,
`public-launch-intent`, `place-actions-arc`, `live-activity-gotchas`,
`dead-shared-component-pattern`, `never-destroy-uncommitted-work`, `never-automate-auth-flows`,
`build-machine-limits`.

**Then read, in this order (all in `Momentum-v3-Design-Handoff/`, sibling of the repo):**
1. `SESSION-OPENER-routines-build.md` — THE PLAN. Five blocks, settled semantics, hard
   constraints, per-block acceptance. It is self-contained; build from it.
2. `SESSION-OPENER-routines-design.md` — the WHY (E's settled answers, the ADHD-directives
   mapping, the public-launch lens). Reference, not work items.
3. The canvas E approved (the visual spec for the screen, notification, Home card):
   `https://claude.ai/code/artifact/3a932048-d940-4469-bc91-904d2906034f`.

## State gate — run before anything

```bash
git status --short                 # must be empty
git log --oneline -1               # expect 41da9c9 (the block-queue commit) or later E-blessed main
git log --oneline -1 origin/main   # same SHA
git branch -a                      # main only expected
```

If `main` has moved past `41da9c9`, read the new commits before branching — do not assume
the plan's line numbers survived. Code baseline is `218d289` (`41da9c9` is docs-only): suite
**2,202 / 0** (56 skipped = emulator suites, by design), SwiftLint **0 / 631**, E's iPhone
`wishwashwacky15` on main (carries `218d289` — same app code).

Branch: **`feature/routines`** off main. The location-arc pattern: multi-block, E's field
test gates the merge, `--no-ff` at the end, re-verify ON main, reinstall the phone from main.

## The blocks (detail + acceptance in the plan)

1. **F-Routines-1-Order** — drag-to-reorder in the actions editor + `PlaceRoutinePlan` +
   `RoutineDefaults` + the stale startSprint-footer copy fix.
2. **F-Routines-2-Notify** — `RoutineRunStore` (create/end/window/sweep transitions) + ONE
   routine notification at 2+ tap-steps (own `placeRoutine-` prefix + category; userInfo =
   run KEY only) + `ArrivalNudgeContent`'s tasks-only fifth path + tray hygiene.
3. **F-Routines-3-Screen** — router (pending-door replay) + `RootView` door + the
   full-screen routine screen (pre-ticked auto steps, dominant next card, Skip/Undo,
   progress semantics AS PINNED IN THE PLAN).
4. **F-Routines-4-HomeCard** — the Today card while a run is live (reachability-proven).
5. **F-Routines-5-LiveActivity** — DISPLAY Activity only (starts on screen open —
   ActivityKit cannot start from background; tap-to-return; no buttons, they're the
   fast-follow).

**The FEATURE blocks are ALREADY QUEUED** in `TODO-CLAUDE-CODE.md` under the "⚠ CLAUDE CODE
ADDITIONS" fence ("Routines arc" section, commit `41da9c9`, E authorised 2026-09-03). Do not
re-add them; tick each `[x]` only at its real close-out.

## The traps that cost sessions (full list in the plan — these are the killers)

- **`RootView.swift` is at 396/400 and `HomeView.swift` at 391/400** — blocks 3 and 4 each
  land in one of them. The RootView door split requires demoting `private` `@State` to
  internal (file-scoped `private` — the `HomeView.arrangeAreas` precedent); Home needs the
  card content in its own file. Both audited; read the plan's notes before touching either.
- **Run lifecycle transitions go BEFORE the cooldown guard and OUTSIDE `isEnabled()`** in
  the handler — a departure swallowed by its own cooldown must still end the run, or
  "routine live" haunts Today until midnight. The plan pins the fixture; this one dies on
  E's field walk if missed.
- **The `placeAction-` notification prefix is GREEDY** — routine notifications need their
  own prefix AND their own delegate branch.
- **ActivityKit cannot START an Activity in the background** — the LA begins when the
  routine screen opens, never at the crossing. Do not "fix" this.
- **Below iOS 17 keep the per-action spray** — the screen is 17-gated but crossings aren't.
- **Zero wire/schema changes all arc.** If you find yourself editing `PlaceActionModels.swift`
  or `firestore.rules`, stop — the plan says you've gone wrong.
- **Commit BEFORE every red-check**; restore with `git checkout --`; never `&&` a commit
  onto a piped build; **never pipe xcodebuild through grep** — log to a file, background it,
  poll the file.
- **A signed-in simulator poisons the unit suite** (70-140s/test) — `xcrun simctl erase`
  after any drive; a reboot is NOT enough. **Never script a sign-in** — if a drive needs an
  authenticated session, stop and ask E.
- The **DEBUG test-fire button** on Places rows is the couch harness for crossings — use it
  before asking E to walk.
- LA gotchas: the Activity **ignores the widget's global accent** — `Color("AccentColor")`
  explicitly; cross-target assets ride the synchronized-group exception sets.

## Standing rules

Per-block: failing tests FIRST, suite green, `swiftlint lint` 0, red-check with the injected
regressions counted, commit AND push, paste the close-out triple
(`git status --short` / local HEAD / `origin/feature/routines` same SHA), then STOP for E's
review unless E says carry on. E's field walk gates the merge. Manual steps (signing,
provisioning — the free account's 7-day profiles expire ~weekly, see
`app-group-provisioning-blocker`) are E's, never scripted. Report any design-skill conflict
per CLAUDE.md §7. When the arc closes: update `routines-next-arc` memory and raise Arc 2
(first-class routines + "at a time" trigger) — designed in outline, NOT authorised.
