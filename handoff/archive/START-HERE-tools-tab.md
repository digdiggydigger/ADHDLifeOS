# Start here — Tools tab build

Paste this into a fresh Claude Code session.

---

Read `claudecode.md` and `CLAUDE.md`, then the auto-memory `tools-tab-and-custom-bar`.

**Your spec is `Momentum-v3-Design-Handoff/SESSION-OPENER-tools-tab-build.md`.** It is
self-contained: four blocks, each with files, TDD targets, acceptance criteria and its own traps.
Read it before writing anything. The same four blocks are tracked as tickable FEATURE blocks at
the very bottom of `TODO-CLAUDE-CODE.md`, under the header **"⚠ CLAUDE CODE ADDITIONS"** — tick
them there as you go.

Design record and rationale (only if you need the *why*):
`SESSION-OPENER-tools-tab.md`, and the canvas at
`https://claude.ai/code/artifact/767eacff-e616-4836-ab3a-ac842ddf42c9`.

## State

`main` @ `6af1ed1`, clean and pushed. It is the only branch. Suite **2,100 / 0** (56 skipped =
emulator suites, by design), SwiftLint **0 / 606**, sim + device builds green. E's iPhone carries
`efd72af` from main.

```bash
git status --short          # must be empty
git checkout -b feature/tools-tab main
```

## What you are building

A **sixth tab, "Tools"**, on a **custom tab bar** — iOS shows only five before collapsing the rest
into a "More" list. E chose the bar's design from six concepts, and picked a **two-state morph**:

- **at rest** — full width, icons only, an accent dot under the selected icon;
- **mid scroll** — contracts to a floating card, the selection filling a tinted chip.

Tools holds Places and the Life Areas editor, as bento cards, and nothing else.

## Four blocks, in order

1. **F-Tools-1-Bar** — six slots, resting state only. **Then stop and ask E** whether six feels
   right on device before adding motion.
2. **F-Tools-2-Morph** — the momentary scroll model, the floating state, dot → chip.
3. **F-Tools-3-Page** — bento cards, and Places leaves Settings.
4. **F-Tools-4-Headers** — one shared pinned-header treatment across the app.

## The five things most likely to cost you a session

1. **`.toolbar(.hidden, for: .tabBar)` usually has to go on the views INSIDE the `TabView`, not on
   the `TabView`.** Verify the system bar is genuinely gone rather than merely covered — a covered
   bar still eats touches.
2. **Do not replace `TabView` with `switch selectedTab`.** It rebuilds on every switch and discards
   each tab's scroll position and `NavigationStack` depth.
3. **`CaptureDiscPanObserver.installOnKeyWindow` is idempotent (`guard shared == nil`) — the first
   install's callbacks win.** A second consumer calling it again silently no-ops and your bar
   simply never moves. `RootView`'s existing callbacks must feed both models.
4. **`CaptureDiscScrollActivity` is sticky by construction and cannot express "momentary".** Write
   a second model; never edit the disc's — that behaviour is settled.
5. **Momentum is the real design risk.** A pan recogniser tracks the finger, not the page, so
   after the lift the page glides while nothing reports movement. Use a settle timer restarted on
   each drag (~250–350ms), as one named tunable constant.

## Standing rules

- **TDD** — failing test first for all new pure logic. View bodies are not unit-testable here;
  push testable rules into a pure type, as `PlaceAppPickerPresentation` does.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove it by rebuilding.
- **Never pipe a long `xcodebuild` through `grep`** — it buffers, and you cannot tell progress
  from a hang. Log to a file and grep the file.
- **A crawling suite means a poisoned simulator**, not slow tests: `xcrun simctl erase <udid>`.
  Rebooting does not fix it. A healthy run is ~5 seconds for ~2,100 tests.
- `swiftlint lint` at 0. **`RootView.swift` is ~397 of its 400-line ceiling before you add
  anything — plan to split it in block 1.**
- Every block ends with a landed commit AND push, verified by pasting `git status --short`,
  `git log --oneline -1` and `git log --oneline -1 origin/feature/tools-tab` showing the same SHA.
- **Never script an auth flow.** Need a signed-in session? Stop and ask E.
- **Report this conflict in every block report (CLAUDE.md §7):** `ui-ux-pro-max` rates
  "bottom nav ≤5" HIGH severity with "overloaded nav" as an anti-pattern. E was shown this and
  chose six knowingly.

Stop after each block and wait for E's review.
