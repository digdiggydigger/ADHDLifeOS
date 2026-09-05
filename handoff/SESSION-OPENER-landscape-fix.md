# Session opener — the capture-disc era is closed, next block is F-LandscapeFix

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-post-nudges.md`) is **CLOSED** — its next block (F-DiscPill) shipped and then
grew into a five-block arc, every step verdict-driven by E on device.

The open-items list lives beside this file in `OPEN-ITEMS-REGISTER.md`. **Read it, but verify
its claims against `TODO-CLAUDE-CODE.md` before acting on them** — see lesson 1 below, which
this exact file pair caused.

## State

- **`main 1999bdc`**, clean, `origin/main` matches. (Confirm `git status` and the HEAD/origin
  match yourself on session start — that check has caught silent push failures before.)
- **Unit suite 1,886 / 0.** SwiftLint **0 violations**. Coverage caveats in CLAUDE.md unchanged.
- **Device `wishwashwacky15` carries the current build** (installed & launch-verified 02:2x,
  2026-08-31). `devicectl` install works plugged-in; the flow is in [[device-build-lag]].
- **The Firebase emulator may or may not still be running** (`./scripts/emulators.sh`, probe
  9099/8080/9199). The emulator account `pill-verify@example.com` / `pillverify123` exists only
  while it runs; recreate freely via the real signup ([[simulator-fresh-account-drive]]).
- The five UI-test journeys and the whole capture-disc arc are green together.

## What the 2026-08-30 → 08-31 overnight session shipped (nine feature commits)

The **capture-disc arc, closed end to end and E-approved on device** — every number is an E
verdict, recorded in [[capture-disc-design]] and the TODO; do not re-litigate any of it:

1. **F-DiscPill** — disc → pill on scroll, window-level pan observer, zero per-screen wiring.
2. **F-PillTune** — pill 52×32→…, settle 1.2s, expanding-fade regrow, then E's GIF verdict
   put the pill at **0.68 opacity** ("just below the 0.7 sweet spot").
3. **F-FabDeepField** — E chose the **deep-field gradient FAB** over an ink FAB in a rendered
   A/B; the fan became **glass tiles**; margins stepped back (edgeMargin 24, **clearance 92**);
   pill dialled to **60×48** across four passes. Approved light AND dark.
4. **F-PillStay** — E revised the motion: the pill is now **directional and sticky** (down →
   pill until an up-scroll; ±12pt latch; NO timers — the settle machinery was deleted). Tab
   change resets; that judgment call was offered for veto and stands.
5. **F-PromoteSheetPolish** — E's "it looks horrible" screenshot of the Make-a-task sheet:
   root cause was `ChoiceChipButtonStyle` styling only the BACKGROUND while this sheet passed
   bare Buttons. All four groups now wear one equal-width 44pt chip; priority is P1–P4 chips;
   due date got a labeled group. Confirmed working on device (IMG_8134/8135); the green-toggle
   nit is PARKED on the register's pre-release list at E's direction.

Also: first-run **seeding confirmed on the emulator path** (fresh signup → six areas, 5-item
today); the register's stale door-stills entry corrected (the door was ALREADY approved).

## Next block: F-LandscapeFix

**E's calls, already made — do not re-ask:**
- **Both orientations stay supported.** Do NOT restrict the app to portrait.
- **Scope: fix the login screen first, then sweep the other screens for landscape breakage.**

**The proven defect:** in landscape, `loginPasswordField` never becomes hittable —
`isHittable` false for 45 straight seconds, observed across ten tests during F-PortraitArrival.
The login form (`Auth/LoginView.swift`) almost certainly doesn't scroll, so in landscape the
lower fields sit under the keyboard/off-screen with no way to reach them. Verify the actual
cause before fixing — that hittable-timeout is evidence, not a diagnosis.

**Build notes for the block:**
- TDD leverage exists: `ADHD_LifeOSUITestsLaunchTests` already runs landscape UI configs, and
  `UITestSession.resetToPortrait()` exists (with `testLaunch` deliberately exempt). A journey
  that rotates (`XCUIDevice.shared.orientation = .landscapeLeft`), signs in, and asserts the
  password field is hittable is the natural red → green. Remember [[geometry-journey-vacuity]]:
  red-check it on the unfixed tree first, and remember orientation OUTLIVES the app process
  ([[ui-test-cross-run-state]]) — reset in teardown or you poison the suite.
- The likely fix shape is a scroll container around the login form; the pinned bottom CTA and
  `.captureDiscClearance` conventions don't apply here (login has no disc), but the reveal
  toggle must stay default-hidden or the journeys break ([[auth-v3-design]]).
- After login: sweep Today/Tasks/Areas/Journal/Captures + the composers in landscape on the
  simulator (renders, not guesses). Log what breaks; fix by E's priority if more than trivial.
- The full UI target run whole is 17/0 today — keep it whole (`-only-testing` scoping is how
  the landscape poison hid for weeks).

## Then, waiting on E (register has detail)

- The **fresh-account sweep on E's device account**: does production seeding land, and does any
  tab dead-end when empty? (Emulator path says yes-seeds; production unconfirmed.)
- The **keyboard Done bar removal** on-device confirmation (login screen, focus a field).
- Kind-switching (note ↔ task) verdict — parked since F-DropAltButton.
- The **pre-release UI list** (light-mode login contrast, double "Create account", now the
  green toggles) — explicitly not work until E calls it.

## Lessons this session paid for (the five from the last opener still stand)

1. **The register lied twice in one entry and I relayed it to E.** It said the door stills were
   owed (E had approved them that morning) and that the door was "the last thing above the tab
   bar" (it is mid-page, by E's own position call). Cross-check the register against the TODO
   before sending E to do anything — the TODO block record is the truth.
2. **A ButtonStyle that styles only the background makes every call site responsible for
   padding** — the sprint planner knew, the promote sheet didn't, and E saw "text highlights".
   `ChoiceChipButtonStyle`'s third consumer will hit this too unless they read the promote
   sheet's `chip()` comment first.
3. **`SIMCTL_CHILD_LIFEOS_FIREBASE_EMULATOR_HOST=127.0.0.1` + idb through the real signup**
   gives a signed-in, seeded simulator session with no UI-test harness — and a backgrounded
   `idb ui swipe` + mid-gesture `simctl screenshot` photographs transient states. This is how
   the pill, the fade, and the stickiness were all proven with genuine discriminators.
4. **Fan-overlay tap coordinates cannot be computed from `CaptureFan.slots`** — the overlay's
   GeometryReader excludes safe areas, so the slot table's fromBottom is offset from screen
   points. Read tap targets off a rendered screenshot, not the geometry table.
5. **E iterates in small dials, fast** (pill: four sizes in one evening; opacity: two). Ship
   each dial as its own tiny commit with the device install in the same breath — the loop only
   works because the phone always carries the number being judged.
