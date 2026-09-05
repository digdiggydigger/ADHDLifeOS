# Start here — Tools tab, blocks 3 and 4

Paste this into a fresh Claude Code session. It replaces `START-HERE-tools-tab.md`, which opened
the arc; blocks 1 and 2 are done and their traps are recorded below because several of them will
bite again in block 3.

---

Read `claudecode.md` and `CLAUDE.md`, then the auto-memories `tools-tab-and-custom-bar`,
`tabview-folds-past-five`, `relaunch-before-judging-device`, `mirroring-cannot-scroll`,
`app-group-provisioning-blocker`, `never-automate-auth-flows`, `dead-shared-component-pattern`.

**Your spec is still `Momentum-v3-Design-Handoff/SESSION-OPENER-tools-tab-build.md`** — blocks 3
and 4 of it are unchanged and still correct. The four blocks are tracked as tickable FEATURE
blocks at the bottom of `TODO-CLAUDE-CODE.md` under **"⚠ CLAUDE CODE ADDITIONS"**; 1 and 2 are
`[x] COMPLETED`, 3 and 4 are `[ ] UNCHECKED`.

## State

Branch **`feature/tools-tab`** @ **`6d850da`**, clean and pushed, **14 commits ahead of `main`**.
Suite **2,154 / 0** (56 skipped = emulator suites, by design), SwiftLint **0 / 618**, sim + device
builds green. E's iPhone carries `6d850da` and it launched.

```bash
git status --short                              # must be empty
git log --oneline -1                            # 6d850da
git log --oneline -1 origin/feature/tools-tab   # same SHA
```

**Do not branch again.** Keep working on `feature/tools-tab`; the arc merges to `main` in one
`--no-ff` at the end.

## What shipped, and the two architecture calls that were NOT in the plan

**Block 1 — `F-Tools-1-Bar`.** Six slots, Tools last, `wrench.and.screwdriver`. E approved on
device after one tuning round ("spacing is so much better").

**Block 2 — `F-Tools-2-Morph`.** The bar contracts to a floating card. E redesigned the trigger
mid-block and then took the visuals through six rounds; all of it is settled and **must not be
re-litigated**:

- **The trigger is POSITION, not motion.** E rejected the momentary model after using it: contract
  past 24pt down, restore at or under 8pt, hold in between (hysteresis). The settle timer,
  injected scheduler and generation counter are all deleted.
- **The capture disc keeps its OWN rule** — E was asked directly and chose "only the bar gets the
  near-top rule". The two are deliberately independent and visibly so at mid-page.
- **The resting pane is opaque `CardSurface`, runs to the screen edge, and its height is DERIVED**:
  `rowHeight = chipHeight 34 + floatingPaddingVertical*2 16 + floatingLift 8 = 58`. Both states
  cover an identical footprint. Change the chip or the lift and the pane follows.

**Two things the plan got wrong, both proven on hardware:**

1. **`TabView` cannot carry six tabs.** It is a `UITabBarController`, and past five UIKit folds
   the overflow into `moreNavigationController` — tabs five and six render with a "More" back
   button. Hiding the bar does not undo it; dropping `.tabItem` does not either. `AppTabContent`
   (a lazy `ZStack` + `AppTabVisitLog`) replaced it. See [[tabview-folds-past-five]].
2. **A SwiftUI `safeAreaInset` does not cross into a child's own `NavigationStack`.** The bar's
   inset therefore misses any screen that pins its own bottom furniture. **This is the one most
   likely to bite you in block 3** — see below.

## Block 3 — `F-Tools-3-Page`: the two traps that are already known

Read the spec's block 3, then these, which the spec could not have known:

- **`appTabBarClearance()` has exactly TWO call sites today** — `JournalView.composerBar` and
  `CaptureInboxView.bottomBar` — and `AppTabBarCallSiteTests` enumerates them. **If the Tools page
  pins anything to the bottom, it needs a third**, and the test's list must grow with it.
- **`PlaceAutomationGuideView` pins a footer with `safeAreaInset`.** It is reachable from Places,
  which lives in the Settings SHEET today — so it needs no clearance. **Block 3 moves Places into
  the Tools TAB, at which point it does.** Add the clearance and the test entry in the same
  commit, or its footer will sit under the tab bar exactly as the Journal composer did.
- The spec's own gate still applies: `placesSection` is `if #available(iOS 17.0, *)` and the floor
  is 16.0, so `ToolsCatalog` must handle Places being absent.
- The Settings split is **asymmetric on purpose** — Places leaves entirely, Life Areas stays AND
  gains a Tools card. Do not make it symmetrical.

## The habit that fixed this arc — use it from the first screenshot

**Measure the render. Do not reason about it.** Six passes went into the bar's chrome and the
first three were wrong because they treated E's feedback as a colour problem when it was
structural. Sampling pixels found the real cause every time from pass four on.

The technique, and it is worth writing again rather than rediscovering: decode the PNG in Python
(`zlib` + the PNG filter loop — no PIL on this machine), sample a column down the left edge or a
row across the bar, quantise to kill JPEG noise, and print colour BANDS with their point ranges.
That turns "it looks off" into `700-767 page / 769-874 bar`. Scratch copies of the script are in
this session's scratchpad; it is ~30 lines and quicker to rewrite than to hunt for.

Two SwiftUI facts it uncovered, both of which caused a "fixed" round that was not fixed:

- **`.background(.ultraThinMaterial)` extends to the screen edge** even when the view it backs
  stops at the safe area.
- **`.background(Color…)` does too** — `Color` and shapes do that by design as backgrounds. Use
  `.background(fill, in: Rectangle())` to clip, or `.ignoresSafeArea` deliberately.

**E's screenshots are JPEG/GIF and the palettes lie.** One GIF reported the page as `#959A96`
where it is `#F2F3F7`. Reproduce on the simulator before trusting any absolute colour from E.

## The environment, as it actually stands

- **There is NO signed-in simulator any more.** One existed through blocks 1–2 (iPhone 17,
  `D4EAC8EE-…`) and was **erased at E's instruction on 2026-09-03**, because a signed-in sim drags
  the unit suite from ~5s to minutes. If block 3 needs to see the Tools page with real data,
  **stop and ask E to sign in** on that sim — the sanctioned route under
  [[never-automate-auth-flows]]; never script the credential step. Everything after sign-in is
  fair game to automate, and simulator swipes DO scroll (mirroring's do not).
- **The unit suite runs on iPhone 17 Pro, `9181EBF9-…`** — a different device on purpose, so a
  signed-in session can never poison the run. If you get one signed in again, keep it off this
  one, and **erase it when you are done**.
- **iPhone Mirroring taps but cannot scroll** — four gesture styles all no-op. Ask E to scroll, or
  use the simulator. See [[mirroring-cannot-scroll]].
- **Device installs break roughly weekly.** Free developer account: profiles expire after 7 days.
  `error: No Accounts` in the build log means **E** must open Xcode → Settings → Accounts and sign
  in; a fresh certificate then needs trusting on the phone (Settings → General → VPN & Device
  Management). Neither is yours to do. Grep the build log for "No Accounts" before suspecting the
  project.
- Install with `devicectl … install app` then `process launch --terminate-existing`. **Judging
  device behaviour after an install-over-running cost a session** to a phantom bug that vanished
  on a clean relaunch — see [[relaunch-before-judging-device]].

## Standing rules

- **TDD** — failing test first for all new pure logic. View bodies are not unit-testable here;
  push testable rules into a pure type, as `ToolsCatalog` is specced to.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove it by rebuilding.
- **Never pipe a long `xcodebuild` through `grep`** — log to a file and grep the file. And note
  `xcodebuild test` often exceeds a 2-minute foreground timeout on the result-bundle step even
  when the tests themselves finished in ~6s; run it backgrounded and poll the log.
- `swiftlint lint` at 0. Watch `file_length` (400) and `type_body_length` (250).
- Every block ends with a landed commit AND push, verified by pasting the close-out triple.
- **Never script an auth flow.** Need a signed-in session? The simulator above already is one.
- **Report this conflict in every block report (CLAUDE.md §7):** `ui-ux-pro-max` rates "bottom nav
  ≤5" HIGH severity with "overloaded nav" as an anti-pattern. E was shown this and chose six
  knowingly.

## Loose ends to raise, not to silently fix

- **`BarSurface` now has zero call sites.** The bar wants an opaque surface and `CardSurface` is
  that colour; minting a duplicate token would be worse. Noted in `AppTabBar.swift`. Leave it
  unless E wants the catalog tidied.
- **The UI journeys were edited but never run.** `app.tabBars` cannot see a SwiftUI stack, so they
  now address `tabBar.<Label>` identifiers via `UITestSession.tabButton(_:in:)`. They compile;
  nobody has executed them since. Running them means a scripted sign-in against the emulator —
  check with E first.
- **E has not given a verdict on the 58pt resting row** (`6d850da`). It is smaller than the 56 E
  once called cramped, though the glyph is 25pt now rather than 20 and the slack matches the
  floating card's. If E wants it looser, the lever is the chip or the lift — the pane is derived
  and follows.
- The capture disc's clearance numbers are untouched, per E's standing "show me on device, then
  decide".
- **The signed-in simulator was erased at the end of block 2** — see the environment section. It
  is not sitting there waiting for you.

Stop after each block and wait for E's review.
