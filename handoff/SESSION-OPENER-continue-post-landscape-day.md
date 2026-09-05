# Session opener — continue the project (the landscape-day arc is closed; F-TabGlyphs is FENCED)

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-landscape-fix.md`) is **CLOSED** — three blocks shipped 2026-08-31, all
E-verdicted on device (detail below).

**FENCE, read before picking anything up:** `SESSION-OPENER-tab-glyphs.md` sits beside this
file and holds the NEXT DESIGN BLOCK (F-TabGlyphs, E's chosen "option A" for the minimized tab
pill). **E will run that opener himself in a dedicated session later today — do NOT start that
block from here.** And because both sessions share one machine: **check `git status` /
`git log origin/main` on start, never run while another session holds an xcodebuild** (this
machine cannot run two, and DerivedData is on the external SSD — [[build-machine-limits]]).

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

- **`main 65019d1`**, clean, `origin/main` matches — verify yourself on session start.
- **Unit suite 1,888 / 0** · SwiftLint **0 violations** · **full UI target whole 23 / 0**
  (keep running it WHOLE; scoping is how the landscape poison hid for weeks).
- **Device `wishwashwacky15` carries `bbc54b7`** (install + launch verified 08:04; `65019d1`
  is docs-only on top, so the phone is current). Flow in [[device-build-lag]].
- Emulator: `./scripts/emulators.sh`, probe 9099/8080/9199; accounts are throwaway.
- Coverage 30.09% (11,227/37,314) — check the DENOMINATOR before comparing anything.

## What shipped 2026-08-31 (five commits, three blocks, all E-verdicted)

1. **F-LandscapeFix (`75e3708`)** — landscape login is a side-by-side field ROW in compact
   height (scroll-on-focus lost twice; the `fieldsSection` comment records why — do not
   retry). Plus `LandscapeLoginUITests`, `rotateToLandscape`, the landscape sweep render.
2. **F-TabBarMinimize (`aee32d1`)** — iOS 26 `tabBarMinimizeBehavior(.onScrollDown)`, gated.
   E: "the tab feel good for now."
3. **F-FanLandscape (`bbc54b7` + verdict `65019d1`)** — the fan points LEFT in landscape
   (`CaptureFan.horizontalSlots`, axis-swapped, picked by `verticalSizeClass`). E: "the fan
   feels good - tick it." **Both fan orientations are settled; re-litigate neither.**

## Work this session may pick up (no E verdict needed)

In rough value order — these are maintenance ticks, not FEATURE blocks; still TDD where logic
moves, still the full close-out per block:

1. **The 45s settled-wait burn** (logged in the F-LandscapeFix block): `signOutIfSignedIn`'s
   comment says "whichever appears first" but `XCTWaiter().wait(for: [a, b])` completes when
   ALL expectations do — so every signed-out launch that lands on the login screen burns the
   full 45s before proceeding. Fix wants first-of semantics (two waiters, or a fulfillment
   count). Behaviour must not change, only the wasted time; the whole UI target run is the
   proof either way (its total should DROP noticeably).
2. **The two files at 397/400** (register debt item E): `Home/DailySummaryView.swift` and
   `Capture/CaptureInboxService.swift`. `state` is `private(set)` so its writers pin to that
   file; `promoteToTask` is the named candidate to move. Split like `LoginFormSections` /
   `UITestOrientation` — same-type extension in a sibling file, no behaviour change, suite
   proves it.
3. **Near-ceiling watch**: `HomeMomentumSections` 390 · `CaptureInboxSections` 390 ·
   `QuickCaptureComponents` 387 · `HomeView` 384. Split only what a block touches anyway.
4. **The contrast unit test that still doesn't exist** (register debt G): colorsets are
   readable from a test bundle; six journal-pad passes were all colour and three were
   rejected on device. A WCAG-ratio test over the token pairs would have caught them.

Anything E types in chat outranks all of the above (CLAUDE.md: direct instructions from E are
the work queue).

## Waiting on E (unchanged — relay, don't action)

- Fresh-account signup sweep on E's device account (production seeding + empty-tab audit).
- Keyboard Done bar removal — confirm on device by focusing a field on the login screen.
- Kind-switching (note ↔ task) verdict — parked since F-DropAltButton.
- The pre-release UI list — not work until E calls it.
- F-TabGlyphs — fenced for its own session (see top).

## Lessons the landscape day paid for (full versions in SESSION-OPENER-tab-glyphs.md)

1. A green that flakes is its own defect — a fix whose success you cannot explain is not a fix.
2. `app.screenshot()` LIES on a rotated simulator; ground truth is external
   `simctl io recordVideo` + ffmpeg frames. Passing runs keep no attachments.
3. A single orientation set can be swallowed like a single tap — retry the SET, judge by the
   window's own frame, and a fresh sim boot clears the deeper sulk.
4. The journey red must prove REACHABILITY (run it against the wired-off view), or the
   dead-shared-component pattern claims a seventh instance.
5. Openers can be wrong about mechanism while right about symptoms — verify the cause before
   fixing, and record the correction in the block.
