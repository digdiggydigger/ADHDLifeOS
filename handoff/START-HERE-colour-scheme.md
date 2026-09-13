# START HERE — **the LifeOS colour scheme.** A design arc, and it opens with questions for E

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. **WRITTEN 2026-09-13** by the session that landed `F-CTACelebrations-Surfaces` and
`F-FocusCard-Corners` and got both device verdicts. It archived its own predecessor
(`handoff/archive/START-HERE-post-corners.md`) in the same move that wrote this.*

**E's instruction, 2026-09-13, verbatim in substance:** *hold on starting any of the outstanding
tasks; I would like to create a properly curated & developed colour scheme that we will implement
throughout the LifeOS application — let's start that planning in a fresh session.*

```bash
git checkout main && git pull --ff-only
```

## State

| | |
|---|---|
| `main` | `fef19b0` — clean, green, everything merged; `origin` carries `main` alone |
| unit suite | **3,008 / 0**, emulator UP, **0** `127.0.0.1:9099` hits |
| SwiftLint | **0 / 812 files** |
| sim build | `** BUILD SUCCEEDED **` |
| device | **ON MAIN at `1920536`.** The last four blocks all PASSED — nothing owed on any of them |

## ⚠ TWO INSTRUCTIONS BEFORE ANYTHING ELSE

1. **EVERYTHING IN THE REGISTER IS ON HOLD.** E paused §B's whole queue — the `AppFeedback` tests,
   the dead tokens, arrival containment, Arc 2 routines, all of it — plus the three outstanding
   device looks. **Do not start any of them, and do not offer to.** They stay in
   `OPEN-ITEMS-REGISTER.md` and nothing about them changed except priority.
2. **THIS IS PLANNING FIRST, NOT A BUILD.** E said *"start that planning"*. The arc opens with a
   design conversation, the way the chimes, the peek and the corners did — **options put to E, and
   E picks by looking.** Do not begin recolouring anything. There is no block written yet; writing
   it, with E, is the first deliverable.

## What is actually there today — measured, not remembered

Run these again rather than trusting the numbers, but they were true at `fef19b0`:

- **63 `.colorset`s** in `ADHD LifeOS/Assets.xcassets`. Every one carries a light AND a dark face.
- **§4 compliance is currently PERFECT: zero hardcoded `Color(red:)` anywhere in Swift.** The asset
  catalog is the only sanctioned home for hex (CLAUDE.md §4) and the tree honours it. **Do not be
  the arc that breaks this.**
- **`AccentColor` is iOS system BLUE — `#0A7CFF` light, `#0A84FF` dark.** Not coral. CLAUDE.md
  carried "coral accent" as a claim for weeks and it was never true; read the asset.
- The core surfaces: `PageBackground` `#F2F3F7` / `#15171C`, `CardSurface` `#FFFFFF` / `#1D2027`,
  `LabelPrimary` `#0E0E12` / `#F5F5F7`, `StateGo` `#0AA84E` / `#30D158`, `StateWarn` `#E07A00` /
  `#FF9F0A`, `StateRisk` `#F5102B` / `#FF453A`.

**The finding worth more than the values, and it is a REAL problem for this arc: colours are
reached three different ways, and only one of them is compile-checked.**

| route | how many | checked? |
|---|---|---|
| Generated symbols — `.pageBackground`, `.cardSurface`, `.cardBorder`, `.accentColor` | 4 tokens, ~130 files | **Yes** — a rename breaks the build |
| String literals — `Color("StateGo")`, `Color("LabelSecondary")`, … | **15 distinct names, ~250 uses** | **No** — a typo or a rename fails SILENTLY at runtime |
| Names COMPUTED at runtime — `AreaPalette`'s `rawValue + "Vivid"` / `+ "Tint"` / `"On" + rawValue` | 9 areas × 4 faces = **36 colorsets** | **No**, and invisible to grep |

**That third route cost this session a wrong answer already.** A grep for unreferenced colorsets
reported 15 dead ones; 14 of them are reached by `AreaPalette`'s computed names and are perfectly
alive. **Grep is not an inventory here.** The only token that looks genuinely unreferenced is
**`OnStateWarn`** (0 occurrences, and nothing computes `"On" + state`), and `BarSurface` has 3
occurrences that the register believes are its definition and its test — confirm both before
claiming either is dead.

## The questions the arc must put to E first

Not a plan — a starting set. Sharpen them, add what the codebase suggests, and **put them the way
the chime candidates and the corner radii were put: few, concrete, rendered where possible.**

1. **What is the app's identity colour?** Today it is stock iOS blue, and nothing on record says E
   ever chose it — it may simply be the Xcode default nobody revisited. That is the single highest-
   leverage question in the arc.
2. **How far does "throughout" reach?** The app, yes — but also the **widgets and the Live
   Activities**, which have their own constraints (a Live Activity ignores the widget accent; see
   `live-activity-gotchas`), and the **app icon**, which is E's GUI job and cannot be done from here.
3. **What happens to the nine AREA colours?** They are user-assignable identity for life areas, and
   a curated scheme either constrains them or coexists with them. Four faces each (base / Vivid /
   Tint / On), so a change here is 36 colorsets.
4. **Is the JOURNAL PAPER theme in scope or out?** It is a separate, SETTLED design (`200d0ea`,
   `journal-pad-design`) with three prior device rejections behind it. **Treat it as out unless E
   says otherwise** — re-opening it unprompted would undo a decision E made by looking.
5. **What contrast bar are we holding to?** CLAUDE.md §4 says "high WCAG contrast safety
   thresholds" without naming a level. AA on body text is the conventional floor; E should choose,
   because it constrains every later value.

## Traps that will bite this arc specifically

- **A colour comparison is the one case CLAUDE.md tells you to use PNG, not JPEG** — "use PNG only
  when the point is pixel-exact: a colour comparison, a contrast measurement, anything that will be
  sampled rather than looked at". The rest of `screenshots/` is JPEG for size; this arc's swatches
  are the exception, and the folder README must say which and why.
- **Render, do not describe.** E's standing direction (`show-dont-describe-geometry`): send the
  image, or label with measured numbers. No ASCII palettes, no hex lists presented as a design.
- **`.secondary` under a custom `Color` is HALF alpha**, not a separate token — the trap
  `journal-pad-design` records. It will recur the moment a custom surface gets secondary text.
- **iOS suppresses a keyline's tint in LIGHT mode** (`routines-next-arc`). A border colour that
  reads correctly in dark can be invisible in light and it is NOT a bug to tune around.
- **The celebration recipes use only the seven catalog tokens plus `raw_hue_color`.** Changing the
  palette moves the confetti. `F-CTACelebrations-4`'s pop and the Confirm's fireworks were both
  approved by E BY LOOKING — a palette change re-opens those, so say so rather than letting it
  happen silently.
- **`swiftui-design-principles` and `ui-ux-pro-max --design-system` both push hardcoded hex
  palettes and web-oriented colour systems. CLAUDE.md §4 and §7.5 beat them.** Report the conflict
  rather than silently following either.

## Do this first, in this order

1. Read `claudecode.md`, CLAUDE.md's **§4** (semantic colour) and **§7.5** (skill precedence).
2. Re-measure the inventory above — the numbers, and which route each token is reached by.
3. **Talk to E.** Put the questions, get the identity colour settled, and only then write the block
   into `TODO-CLAUDE-CODE.md`.
4. Nothing is built until there is a block E has seen.
