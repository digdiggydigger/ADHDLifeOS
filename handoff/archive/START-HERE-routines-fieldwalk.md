# Start here — finishing the Routines arc (field walk → merge)

*Paste this into a fresh Claude Code session. Written 2026-09-03 at the end of the build
session, on `feature/routines` @ `2c46ee7`. **The arc is BUILT. What remains is E's field walk,
whatever it turns up, and the merge.** Do not rebuild what is already here.*

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `routines-next-arc` (its last two
sections are this session's close-out and traps), `public-launch-intent`,
`dead-shared-component-pattern`, `never-destroy-uncommitted-work`, `never-automate-auth-flows`,
`build-machine-limits`, `device-build-lag`, `live-activity-gotchas`.

**Then read `SESSION-OPENER-routines-build.md`** (same directory) for the settled semantics — it
is still the spec, and every "do not re-litigate" in it still holds.

## State gate — run before anything

```bash
git status --short                            # must be empty
git log --oneline -1                          # expect 2c46ee7
git log --oneline -1 origin/feature/routines  # same SHA
git branch -a                                 # main + feature/routines
```

Baseline on the branch: suite **2,306 / 0**, SwiftLint **0 / 662**, both targets build.
E's iPhone `wishwashwacky15` carries **`2c46ee7`** (installed + launch-verified 20:37).
**The phone is on the BRANCH, not main** — put it back on main after the merge.

The Firebase emulator is NOT running (the machine was restarted). Start it before any UI test:
`./scripts/emulators.sh` in a second terminal. Without it `RoutineJourneyUITests` SKIPS rather
than fails.

## What is already done — all five blocks, on the branch

```
6bb4110  F-Routines-1-Order        drag-to-reorder + PlaceRoutinePlan + RoutineDefaults
c282f7e  F-Routines-2-Notify       RoutineRunStore + ONE notification at 2+ tap-steps
4ff3cf7  F-Routines-3-Screen       router + RootView door + the routine screen
b2b7690  F-Routines-4-HomeCard     Today's card + RoutineJourneyUITests
534265e  F-Routines-5-LiveActivity display Activity (starts on screen open)
52f3092  F-Routines-5              bundle-registration guard hardened
2c46ee7  F-Routines-5              island keyline + untruncated count (E's field walk)
```

All five TODO blocks are ticked. **Do not re-add them.** Zero wire/schema changes all arc, so
there is nothing for E to republish.

## E's field walk — round 1 PASSED (2026-09-03, nine screenshots)

A real departure crossing on a place with two tap-steps produced: ONE notification ("2 steps
ready — Open Spotify · Open Health"), tap → routine screen with correct departure copy, Spotify
opened with **no "wants to open" dialog**, the **Live Activity rendered on both the Lock Screen
banner and the expanded Dynamic Island** and updated to "Next: Open Health", returning
mid-routine held the place (Done + Undo chip, step 2 promoted), Health opened, and the journal
recorded "Left routines test".

**Two defects it found, both fixed in `2c46ee7`:** the island's expanded trailing region
truncated "1 of 2 done" → "1 of 2…" (the island now uses `shortStatusLine` = "1/2"; the banner
keeps the sentence), and the island had no defined edge against a dark background
(`keylineTint(Color("AccentColor"))` — ActivityKit's only supported way to outline it).

## What E still has to walk — round 2

Round 1 was **departure-only, two app-opens, notification-tapped**. Untested:

1. **The Today card** — E has never seen it. Swipe the notification away, open the app, tap
   Continue. This is the whole recovery surface.
2. **An arrival routine with an AUTO-RUN step** (a journal line beside two app-opens) — the
   pre-ticked row and the absorbed auto-run report have never been seen on device.
3. **Departure ending an arrival run** — arrive, leave, card gone. (The stacked-cooldown fixture
   pins it in tests; E's eyes have not.)
4. **Skip**, and Undo on a skipped step.
5. **Tapping the Live Activity** to return to the routine.
6. **One-tap-step regression**: a place with a single action must still give today's old direct
   notification, not a routine.
7. **Whether the keyline and "1/2" read right** — the only part of `2c46ee7` unverified by eyes.

If E reports a bug: reproduce it in `RoutineJourneyUITests` first where you can, fix, red-check,
commit, push, reinstall the phone. That journey is the arc's real proof and it has already caught
four defects unit tests could not.

## Two decisions still awaiting E's veto (stated, not yet answered)

- **Kill-switch OFF still writes the run.** With arrival nudges off there is no notification, but
  the run is recorded and Today shows the card. Reasoning: pull surfaces are records, like the
  auto-runs; only the interruption honours the switch.
- **While a routine is live for a place, that place's `ArrivalSurfaceCard` is suppressed.** Two
  cards about one place is noise. It returns when the run ends.

## The merge, once E blesses it

Full re-run (unit suite + `RoutineJourneyUITests` with the emulator up) → `--no-ff` merge into
main → **re-verify ON main** → push → reinstall `wishwashwacky15` **from main** → **ask E before
deleting the branch** (E has always been asked; branches were kept twice).

Then update `routines-next-arc` memory with the merge SHA and **raise Arc 2 — first-class
routines + the "at a time" trigger — which is designed in outline and NOT authorised.** It is the
one that unlocks E's morning routine, which cannot exist in place-scoped v1 (no place to hang it
off). Fast-follows behind it: interactive Live Activity buttons (E asked for multiple purposeful
ones, iOS 17+ App Intents) and smart-skip, which now has the per-run records this arc creates.

## Traps this session paid for — read before touching the tests

- **`onDisappear` does NOT fire reliably for a `fullScreenCover`.** A finished routine kept its
  Today card. Every deliberate exit calls `leaveScreen()` itself; the callback is only a net.
- **An accessibility identifier on a `.bentoCard()` container is INHERITED by its children** and
  overrides their own — it renamed the Continue button out from under itself. Per-control, never
  on the card.
- **`UITestSession.tap(_:untilGone:)` returns TRUE immediately if the target is already gone**, so
  naming a just-asserted-absent element means the tap NEVER HAPPENS. This cost several runs: the
  cover stayed up and every later assertion read the screen beneath it. Name something still ON
  the screen.
- **`XCTNSPredicateExpectation` can be waited on exactly once** — reusing one across retries
  raises an API violation instead of retrying. Build a fresh one per attempt.
- **A source-reading guard must strip comments**: `contains("Foo()")` still matches `// Foo()`,
  which is how the bundle-registration guard slept through its own red-check. Use the
  `code(of:)` helper in `RoutineActivityCallSiteTests`.
- **The simulator does not composite a Live Activity** onto the Home-Screen island or a freshly
  booted lock screen. Verify with an ActivityKit probe (`areActivitiesEnabled`, `Activity.request`,
  `activities.count` before/after) — and any probe MUST end what it starts and be deleted before
  commit. E's device is the visual gate, and round 1 proved the LA works there.
- **ActivityKit presenters must outlive SwiftUI body re-evaluation** — built inside a
  `@ViewBuilder`, a fresh instance per render drops the handle to the running Activity.
  `RoutineActivityKitPresenter.shared` with a `private init` makes that a compile error.
- **An `if #available` inside a `WidgetBundle` body can silently drop the widget** from the bundle.
- **Reordering has no visible grip handles** — plain `.onMove`, discoverable only via the footer
  copy and a long-press. Verified working by an auth-free `swiftc` probe app; scoped
  `.environment(\.editMode, .constant(.active))` renders NO grips on iOS 26, which is why it was
  not used. If E finds it undiscoverable, the fallback is the forced-editMode List from
  `HomeAccessoryStrips.swift:13-27` behind a "Reorder" row.
- **File-length watch**: `HomeView.swift` 398/400, `RootView.swift` ~386/400,
  `HomeMomentumSections.swift` 393/400. Anything new goes in its own file.

## Standing rules unchanged

Per block: failing test first, suite green, `swiftlint lint` 0, red-check with the injected
regressions COUNTED, commit AND push, paste the close-out triple, then STOP for E's review.
Never script a sign-in. Never `&&` a commit onto a piped build. Commit BEFORE any deliberate
regression. Manual Xcode steps (signing, provisioning — the free account's 7-day profiles expire
~weekly) are E's, never scripted; the device build signed cleanly on 2026-09-03 with
`-allowProvisioningUpdates`.
