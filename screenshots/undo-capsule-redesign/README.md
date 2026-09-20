# The undo capsule — E's REDESIGN ROUND (2026-09-20), options for E to choose from

> **This folder is a QUESTION, not a record of a decision.** It exists so E picks the capsule's new
> shape by looking. When E has chosen, the chosen shape gets its own evidence in
> `../undo-capsule/`, and the throwaway switch that drew these is deleted.

**What prompted it.** `F-C1-UndoCapsule` went onto E's phone for the first time on 2026-09-20
(`main` @ `3f7932c`, the 44pt height round). E ran both passes and sent back eight frames and a 47s
screen recording. **The Reduce-Motion-ON pass PASSED** — E: *"Passes your request requested
checks"*. The Reduce-Motion-OFF look sent the shape back, verbatim:

> *"Bringing back a second line is smart. I also recommend that we remove the blue chip background
> colour behind the "Undo" Button and increase the corner radius of the entire UndoCapsule card."*

All three are E's call. What these frames decide is the NUMBERS.

**Environment:** iPhone 17 Pro simulator, **iOS 26.5**, Firebase **Emulator Suite** (the audit's
exported state), a throwaway account per variant created by the harness, 2026-09-20 06:20–06:50.
Frames are `app.screenshot()` attachments from `ADHD LifeOSUITests/UndoCapsuleRedesignRenderUITests`,
exported from the result bundles and converted to JPEG. Card heights are measured from the frames
themselves — see "How the heights were measured" below.

**The subject is chosen, not taken.** Every frame closes **"Capture three things on your mind"**,
the longest task first-run seeding writes. The whole point of the round is what the second line
does, so a frame of a short title would answer nothing. (It needs the **Open** filter: the default
Momentum filter groups by dueness and that task has `dueDate: nil`, so it is not in the list at all.
The first run waited 45s for a title that was never going to be on screen.)

## The six shapes

| # | shape | card | what it changes |
|---|---|---|---|
| `00` | **CURRENT — shipped** | **44pt** | 1 line, accent chip behind Undo, radius 12. The reference. |
| `01` | **A · base** | **59pt** | All three of E's changes, middle radius: 2 lines reserved, no chip, radius 20. |
| `02` | **B · radius 16** | **59pt** | A, with the on-grid radius below 20. |
| `03` | **C · fully rounded** | **59pt** | A, as a true capsule — the tab bar pill's and the + disc's own language. |
| `04` | **D · up to two lines** | **53pt** | A, but the second line is ALLOWED rather than reserved, so the card's height follows the title (44pt for "water", 53pt here). |
| `05` | **E · roomy** | **59pt** | A, plus the Undo control's own horizontal padding dropped 16 → 0. |

## What the frames caught that no test could — and it changed the round

**Two lines alone does NOT fix the truncation that prompted E's request.** Shapes A, B and C all
still read *"Capture three things on your mi…"*. The subject's column is narrow because the capsule
shares its row with the 60pt capture disc, and a second line of a too-narrow column is still a
too-narrow column.

**The cause is a leftover, and it is only visible once the chip is gone.**
`UndoCapsuleMetrics.undoHorizontalPadding` is 16, and it was padding the INSIDE of the chip E has
just removed. With no chip to pad it is 32pt of invisible dead space either side of the word
"Undo" — space the subject could have. Shape **E · roomy** reclaims it and is the only one where
the title fits complete: *"Capture three things / on your mind"*.

This is why the round has six shapes and not five: `roomy` did not exist when the renders were
planned. It was added after reading frame `01`.

## Contrast — removing the chip IMPROVES it, and that is worth recording

Computed from the asset catalog's hex values (never sampled from a JPEG), `AccentColor` over
`CardSurface`, with the chip composited at `AppTabBarMetrics.chipTint*`:

| | light | dark |
|---|---|---|
| **today** — accent label on the 12% / 20% accent chip | **3.38:1** | **3.48:1** |
| **after** — accent label on `cardSurface` | **3.93:1** | **4.47:1** |

Both figures move toward `accessibility.md`'s *"Up to 17 pts / All / 4.5:1"* and neither reaches it;
`.callout` is 16pt. **This is NOT fixed here** — the Undo label's contrast is already in the
register as a colour-arc input and round 9's *"Leave it to the colour arc"* holds. The point is only
that E's change helps a known, recorded shortfall rather than worsening it. The 3.38 / 3.48 pair
reproduces the register's existing figures exactly, which is what validates the method.

## How the heights were measured

A column at 30% of the frame's width, inside the card and clear of its corner arc, taking the run
of pixels that differ from the page background by more than 8 (which excludes the soft shadow at
3–5 but includes the 1pt border at 14 and the white fill at 13). **Validated against the known
value**: `00-tasks-current` measures **44.0pt**, exactly `UndoCapsuleMetrics.minHeight`.

Two earlier readings were wrong and are worth not repeating: a tolerance of 14 excluded the white
card itself (it differs from the page by only 13) and returned the tab bar's height for every
variant — five identical numbers that looked like a design that had not changed. And a column at
6% of the width sits 8pt into the card, where a 20pt corner arc eats 4pt off each end.

## The files

Numeric prefixes are the order to read them in. `-L` is light, `-D` is dark.

| file | what it proves |
|---|---|
| `00-board-light-all-six.jpg` | All six bottom-furniture crops side by side with measured card heights. **The comparison E chooses from.** |
| `00-board-dark-three.jpg` | The same for the three rendered in dark: current, fully rounded, roomy. |
| `00-tasks-current-L/D.jpg` | The shipped shape on Tasks, standing in for the search row — the before. |
| `01-tasks-base-L.jpg` | All three changes at radius 20. Shows the second line, and shows it still truncating. |
| `02-tasks-radius16-L.jpg` | Radius 16 against the same content. |
| `03-tasks-radiusFull-L/D.jpg` | A true capsule, light and dark. |
| `04-tasks-upToTwo-L.jpg` | The variable-height cost restated: 53pt here, 44pt for a short title. |
| `05-tasks-roomy-L/D.jpg` | **The only shape where the full title fits.** Light and dark. |
| `*-inbox-*.jpg` | Every shape over DENSE content (the Capture Inbox), not just over the empty space below the Tasks list. The capsule lies across the "Task it" button there, and a bigger radius is exactly the sort of change that helps in one place and hurts in the other. |

## Verified paths

No `#available` site was touched, so none is owed. **Reduce Motion: untouched** — the variants
change geometry and fill, never `UndoCapsuleMotion`, so F-C1's reduced path is unchanged and no
RM-on device pass is owed by this round. (F-C1's own RM-on pass PASSED on E's phone, 2026-09-20.)

## The switch that drew these, and why it cannot leak

`ADHD LifeOS/Undo/UndoCapsuleVariant.swift` is **temporary and deleted when the round closes**.
`UndoCapsuleVariant.active` reads `LIFEOS_UNDO_VARIANT` from the environment **only under `#if
DEBUG`** and resolves to `.current` — the shipped shape — whenever the environment says nothing. A
release build can never be a variant.

**One test method per variant, and each asserts its own identifier.** The capsule's
`accessibilityIdentifier` carries the variant's name (`undoCapsule-roomy`), so a frame that
photographed the wrong shape fails the run instead of reaching E. This is the guard the height
round lacked: it lost two rounds to switches the app never received (a launch argument beginning
with `-` is read as a UserDefaults key expecting a value and is swallowed; `xcodebuild`'s own
environment does not reach the test runner), and both failures look exactly like a design that did
not change.

---

## ROUND 2 — E chose, the chosen shape was rendered, and the measurement contradicted one reason for it

**E's picks, 2026-09-20:** *"from the images you've made Option C, 'Fully rounded' looks the best"*,
then the Undo padding reclaimed (16 → 0), then **"up to two lines"** over a steady 59pt — chosen
with the 59-vs-60 tension named explicitly, because 59pt sits level with the 60pt capture disc and
that is close to the *"same height as the FAB Icon"* E rejected at 74pt.

**That exact combination had never been rendered, so it was, before anything was written for real.
It does not do what the third choice was for.**

| frame | subject | card |
|---|---|---|
| `06-tasks-chosen-*` | "Capture three things on your mind" | **59pt** |
| `06-tasks-chosen-short-*` | "Take a 10-minute walk" | **59pt** |

**Both wrap.** With the padding reclaimed the subject column holds roughly **12–14 characters per
`.footnote` line**, so "Take a 10-minute walk" breaks to *"Take a 10- / minute walk"*. **"Up to two
lines" therefore behaves like "always two lines" for any realistic task title**; the 44pt fallback
is only reachable for something as short as a nudge label ("water"). E picked it to stay clear of
the disc, and it does not.

**Why `upToTwo` measured 52.7pt earlier and `chosen` measures 59.** `upToTwo` kept the 16pt padding,
so its column was narrower and `.minimumScaleFactor(0.8)` shrank the text to fit — smaller line
boxes, shorter card. Reclaim the padding and the text renders at full size. The two decisions
interact, which is exactly why the combination had to be rendered rather than reasoned about.

**59pt is close to the floor for this arrangement**, not a slack number: `.caption2` verb (~13) +
4pt gap + two `.footnote` lines (~36) + 8pt padding ≈ 61. Stepping the subject down to `.caption`
saves ~4pt. There is no comfortable ~50pt shape that keeps the verb and two lines.

**So the real choice is binary, and `00-board-the-height-choice-D.jpg` is it:**

| | card | shows |
|---|---|---|
| **CURRENT** | 44pt | "Capture three thi…" |
| **44pt · one line** (`07-*`) | **44pt** | "Capture three things on…" — the reclaimed 32pt spent on the line rather than a second line. Same height as today, visibly more title, and everything else E asked for (fully rounded, no chip). |
| **59pt · two lines** (`06-*`) | **59pt** | "Capture three things / on your mind" — complete, at the cost of sitting level with the 60pt disc. |

## Round 2's files

| file | what it proves |
|---|---|
| `00-board-the-height-choice-D.jpg` | **The binary choice**, dark, with measured heights and the disc's 60pt named. |
| `06-tasks-chosen-L/D.jpg` | E's picks as chosen: fully rounded, no chip, padding 0, two lines. 59pt. |
| `06-tasks-chosen-short-L/D.jpg` | The same with the SHORT seeded title — still 59pt, which is the finding. |
| `07-tasks-oneLineRoomy-D.jpg` | The 44pt alternative: everything E chose except the second line. |
| `06/07-inbox-*.jpg` | Both over the Capture Inbox's dense content. |

**One light render of `07` failed, and the failure is the harness working.** The assertion
*"No capsule with identifier 'undoCapsule-oneLineRoomy' — the variant did not reach the app"* fired
because the close never landed, so the run failed instead of photographing the shipped shape and
labelling it as the alternative. That is precisely the trap the height round fell into twice. The
dark render of the same variant passed and is the frame above.
