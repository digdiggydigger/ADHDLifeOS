# Session opener — the landscape era is closed, next block is F-TabGlyphs (E's "option A")

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-landscape-fix.md`) is **CLOSED** — its block and everything it grew into
shipped in one 2026-08-31 session, every step E-approved on device.

## THIS FILE IS A SNAPSHOT — re-anchor to the live tree before acting on it

Written 2026-08-31 ~08:40 at `main 65019d1`. **E may have worked on the app between this file
being written and you reading it** (another session, another opener, or direct edits). Every
fact below was true at the snapshot; none of it is guaranteed now. So, on session start and
BEFORE acting on anything in this file:

1. `git fetch origin && git log --oneline 65019d1..origin/main` — read every commit that
   landed after the snapshot, and the FEATURE blocks they ticked in `TODO-CLAUDE-CODE.md`.
   **Where a later commit or block record disagrees with this file, the repo wins.**
2. Re-read `TODO-CLAUDE-CODE.md`'s Current Sprint — the queue below may already be stale
   (a block added, ticked, or superseded). The TODO is the truth; this opener is a pointer.
3. Re-read the memory index — a memory updated after this snapshot supersedes any summary of
   it here.
4. Re-derive, don't quote: suite count, lint, device build, coverage — re-run or re-measure
   whatever you intend to rely on or report.
5. If `git status` is dirty, or local and `origin/main` differ, that is either another
   session mid-block or E's OWN uncommitted work — never assume which, never commit, revert,
   stash or build over it; describe what you found and let E say whose it is.
6. Then adjust the plan below to the tree you actually found, and SAY what changed.

If nothing landed since `65019d1`, proceed exactly as written.

## State (snapshot at `65019d1` — re-verify per the rule above)

- **`main 65019d1`**, clean, `origin/main` matches. (Run the git check yourself on session
  start — it has caught silent push failures before.)
- **Unit suite 1,888 / 0.** SwiftLint **0 violations**. **Full UI target run whole: 23 / 0**
  (run it WHOLE — `-only-testing` scoping is how the landscape poison hid for weeks).
- **Device `wishwashwacky15` carries `bbc54b7`** (installed + launch-verified 08:04,
  2026-08-31); `65019d1` on top of it is docs-only, so the phone IS current. The
  `devicectl` flow is in [[device-build-lag]].
- The Firebase emulator may or may not still be running (`./scripts/emulators.sh`, probe
  9099/8080/9199). Emulator accounts are throwaway; create freely via the real signup.
- Coverage last measured 30.09% (11,227/37,314) — check the DENOMINATOR before comparing.

## What the 2026-08-31 session shipped (five commits, three blocks, all E-verdicted)

1. **F-LandscapeFix (`75e3708`)** — landscape login: in compact height the field cards sit
   side by side in ONE row (scroll-on-focus was tried twice and lost both times — the comment
   on `LoginFormSections.fieldsSection` records why; do not retry it). Plus
   `LandscapeLoginUITests`, `UITestSession.rotateToLandscape`, and the landscape sweep render.
2. **F-TabBarMinimize (`aee32d1`)** — iOS 26's `tabBarMinimizeBehavior(.onScrollDown)`, gated
   with the house `@ViewBuilder #available` shape in `RootView`. **E: "the tab feel good for
   now."**
3. **F-FanLandscape (`bbc54b7`, verdict `65019d1`)** — the fan points LEFT in landscape:
   `CaptureFan.horizontalSlots` is the portrait table axis-swapped, picked by
   `verticalSizeClass` in the overlay. **E: "the fan feels good - tick it."** BOTH fan
   orientations are now settled; re-litigate neither.

## Next block: F-TabGlyphs — the minimized pill stops whispering (E's "option A")

**E's call, already made — do not re-ask.** E circled the minimized tab pill in
`Ethan's Screenshot Folder/Screenshot-of-nav-bar-bug.jpeg`: "needs a serious visual overhaul…
more prominent, Eye catching and intuitive (As this is the button to reopen the nav bar tab
menu)." From the options offered, **E chose A: bolder, FILLED tab glyphs**, so the
system-drawn pill inherits a solid accent mark instead of Today's wiry line symbol.

**The one hard constraint:** the pill is system Liquid Glass — you control ONLY the selected
tab's SF Symbol (and its weight/variant), never the pill's chrome. The pill always shows the
CURRENT tab's glyph, so this is a five-glyph pass in `RootView`'s `.tabItem`s, not a Today fix.

**Candidate glyphs (verify each exists in the SDK before shipping — do not trust this list):**
- Today: `chart.line.uptrend.xyaxis.circle.fill` (solid coin instead of the wire)
- Tasks: `checklist` has no `.fill` — try `checklist.checked` or a filled checkmark form
- Areas: `square.grid.2x2.fill`
- Journal: `book.fill`
- Captures: `tray.full.fill`

**Staleness note for this block specifically:** if any commit after `65019d1` touched
`RootView.swift` (the `.tabItem`s live there, and so do `minimizesTabBarOnScrollDown()` and the
FAB overlay stack), the tab bar's minimize behaviour, or the glyph vocabulary anywhere — read
those diffs FIRST and fold them into the glyph pass. E may also have changed his mind about the
pill entirely (option B, or something new) in a block record you haven't seen; the TODO's most
recent entry on the tab bar outranks this plan.

**Build notes:**
- No new pure logic → no new unit tests required; the verification is RENDERS with a
  discriminator, the established pattern: signed-in sim session (`SIMCTL_CHILD_` + emulator,
  keychain may already hold a session), idb swipe to minimize, screenshot the pill
  before/after the glyph change. Put a before/after pair in front of E — this is a design
  block and three journal-pad passes were rejected on device for skipping that step.
- The full-bar look changes too (five filled glyphs) — render the FULL bar as well as the
  pill, light and dark. §4 contrast rules apply.
- Close-out is unchanged and mandatory: lint, full unit suite, **full UI target whole**
  (journeys address `app.tabBars.buttons` by LABEL, so glyph swaps should be invisible to
  them — but run it, don't reason it), commit + push + SHA check, device install + launch,
  and paste real terminal output.
- **Option B stays parked**: if the filled glyphs still whisper on E's device, the named
  fallback is the custom hide-plus-reopen-chip built on the F-PillStay scroll signal — but
  that is E's call to trigger, not yours to preempt.

## Then, waiting on E (unchanged from the register)

- The fresh-account signup sweep on E's device account (production seeding + empty-tab audit).
- The keyboard Done bar removal — on-device confirmation (focus a field on the login screen).
- Kind-switching (note ↔ task) verdict — parked since F-DropAltButton.
- The pre-release UI list (light-mode login contrast, double "Create account", green toggles)
  — not work until E calls it.

## Lessons this session paid for

1. **A green that flakes is its own defect.** The scroll-on-focus login fix passed once and
   failed on identical code; the row layout that replaced it passed every run since. If
   success depends on timing you cannot explain, it is not a fix.
2. **`app.screenshot()` LIES on a rotated simulator** — letterboxed portrait frames that read
   as a broken half-black screen. Ground truth is `xcrun simctl io booted recordVideo` run
   OUTSIDE the test, frames extracted with ffmpeg. Passing runs keep NO attachments.
3. **A single `XCUIDevice` orientation set can be swallowed like a single tap.**
   `UITestSession.rotateToLandscape` toggles and retries; a fresh `simctl` boot clears the
   deeper sulk. The window's own frame is the only truth worth asserting.
4. **The journey red must prove REACHABILITY, not just correctness** — F-FanLandscape ran its
   sweep with the table built, unit-green, and the overlay deliberately unwired: it failed at
   the exact defect. That is the only proof a wired view exists (this repo's six-instance
   dead-shared-component pattern).
5. **The register/opener can be wrong about mechanism even when right about symptoms** — the
   landscape opener guessed "the form doesn't scroll"; it was in a ScrollView all along and
   the defect was keyboard-shaped. Verify the cause before fixing; the block record shows the
   correction.
