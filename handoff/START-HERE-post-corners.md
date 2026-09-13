# START HERE — everything landed and PASSED on device, and **nothing is queued**

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **WRITTEN 2026-09-13** by the session that settled `F-CTACelebrations-Surfaces`' design
question with E, built it, then did the same for `F-FocusCard-Corners`. It archived its own
predecessor (`handoff/archive/START-HERE-cta-celebrations-surfaces.md`) in the same move that wrote
this. The session that finishes the next block archives THIS one when it writes the successor.*

**`main` @ `598da3b` is clean, green and holds everything.** No branch to check out, nothing
half-built, and `origin` carries `main` alone.

```bash
git checkout main && git pull --ff-only
```

## State

| | |
|---|---|
| `main` | `598da3b` (PR #116) |
| unit suite | **3,008 / 0**, emulator UP, **0** `127.0.0.1:9099` hits |
| SwiftLint | **0 / 812 files** |
| sim build | `** BUILD SUCCEEDED **` |
| UI journeys | both GREEN (run for `-6`; neither block since touches UI a journey asserts) |
| device | **ON MAIN at `1920536`** (installed 2026-09-13 22:29, clean one-pass). **All four blocks PASSED**: `-6`, `-7`, `-Surfaces`, `-Corners`. **Nothing owed on any of them.** |

## ⚠ THE WORK QUEUE IS EMPTY. Do not invent one.

`TODO-CLAUDE-CODE.md` has no open FEATURE block. The CTA celebrations arc is finished (blocks 1–7
plus `-Surfaces`), and `F-FocusCard-Corners` — the one thing that was queued after it — landed in
the same session. **Take direction from E**, and answer "what is outstanding?" from
`handoff/OPEN-ITEMS-REGISTER.md` (forty-fourth edition) rather than improvising in chat: that file
went six days stale once by exactly that route.

If E asks for a suggestion, §B's remaining items in order are the two-test `AppFeedback` gap, the
dead design tokens (`BarSurface`, `AppTabBarPresentation.slotWidth`/`restingSlotWidth`), the
accuracy-aware arrival containment (**only if E still sees drops**), and Arc 2 — first-class
routines. None is started.

## Owed to E — NOTHING on any merged block

Both device checks that were outstanding when this file was first written have since **PASSED**:

- **`F-CTACelebrations-Surfaces`** — E: *"you can mark a PASS to 'the celebration hold' checklist
  item"*.
- **`F-FocusCard-Corners`** — E: *"they look okay"*, with two device screenshots filed in
  `screenshots/focus-card-bottom-corners/`.

**Do not re-ask for either.**

**One standing item, carried:** E RESERVED the runner-up chime. *"keep a hold of the sound 'el-b'
... there is likely other locations that [it] Could be used."* It is at
`screenshots/cta-celebrations-block-7/candidates/05-generated-b.{wav,caf}`, trimmed, normalised and
ship-ready. **When a second sound gets a real site, use that file — do not generate a new one.**

## What this session learned that will bite the next one

- **A green test can be green for a reason that is not yours.** `CelebrationUnknownSheetCompositionTests`
  waited on `isAnythingPresented` — a reading of the whole key window — to learn that *its own*
  sheet was up. A leftover presentation from the previous class satisfies that just as well, which
  made the file flaky AND could have made its positive assertions vacuous. It waits on the sheet's
  own `onAppear`/`onDismiss` now, and the sibling file proves the window CLEAR in `setUp` before
  hosting anything. **When a test waits on global state, ask whose state it is.**
- **A wait budget spelled as an iteration count is a wall-clock budget in disguise.** 50 × 20 ms is
  ample on an idle machine and not ample inside a 3,000-test suite. Deadlines, not counts.
- **Mutation-check anything that passed first time, in BOTH directions.** Forcing the sheet probe
  to `false` kills 8 of 11; forcing it to `true` kills exactly the 3 "reads clear" controls. The
  positives and the controls are each vacuous alone — only the pair pins the behaviour. Same
  discipline caught that the corner tests were real: make the bottom radius follow the top and
  three die.
- **A render probe that does not reproduce the app's z-order answers a different question.** The
  corners probe's first pass drew the tab bar over the card; the whole question is what shows
  through the notch where they meet. `RootView` mounts the bar as a `.safeAreaInset` (`:203`) and
  `RootBottomOverlay` as an `.overlay` after it (`:229`) — card on top.
- **E's answer can make your own block's second half inert, and you say so.** `-Corners` asked for
  `animatableData` to stop the corner snapping mid-spring; E then chose a collapsed radius equal to
  the expanded one, so nothing interpolates — the snap is gone because the difference is gone. The
  wiring stays and the code says it is currently inert rather than implying a morph.
- **"Owed a device check" and "the code is on E's phone" are DIFFERENT FACTS.** Both blocks were
  reported as owing a device verdict while the phone was two PRs behind. E looked, saw nothing, and
  reported it — about a change that was correct and simply not installed. **Install as part of the
  close-out and write the SHA the phone carries.** `device-build-lag` has the recipe.
- **The suite ran at 41 s, then 140 s, then 91 s on the same tree.** 0 × `9099` and 0 `Compiling`
  lines each time, so it was machine load, not the poisoned-simulator failure CLAUDE.md describes.
  **Check those two numbers before diagnosing a slow run.**
