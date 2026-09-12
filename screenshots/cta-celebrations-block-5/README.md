# F-CTACelebrations-5 — inbox zero, the streak on 7, the daily goal

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host at a fixed 393 × 852 pt — **E's iPhone 15 Pro's point size, so nothing is judged
at the wrong scale** — on `feature/cta-celebrations-5`, 2026-09-12.

- **No backend, no account, no sign-in, nothing written anywhere.** Every scene is built from plain
  value types, a `FakeCaptureClientAdapting`, and a `CelebrationCenter` constructed with an injected
  gate, so no probe touched Firestore or the simulator's own `UserDefaults`.
- 00–01 drive the **real** `CaptureInboxService`, `CelebrationCenter`, `CelebrationLayer`,
  `CelebrationStage` and `CelebrationFrame` — in situ, not copies. 02–11 draw the real
  `CelebrationFrame` at explicit instants, because `TimelineView` draws at the REAL instant and a
  still cannot be taken through the live stage.
- One throwaway probe, `ZZMilestoneProbe`, ran from the test target and was removed from the tree
  before the commit that adds this folder. Rebuild it from
  `screenshots/cta-celebrations-block-3/README.md` plus block 4's two additions; the copy used here
  is kept in this session's scratchpad.
- **No throwaway data was created**, on device or in any backend, so there was nothing to clean up.

The design: `handoff/SESSION-OPENER-cta-celebrations-design.md` — E's **F3** (which moments), **F7**
(the daily goal, "any tab", once per day), **F8** (the every-Confirm size), **#7** (fade everywhere
new), **R-a**, **R-b**, **R-d** and **R-h**.

## Verified paths (CLAUDE.md §7.3)

> **No `#available` site is added or changed by this block, and no tier was passed over.** Everything
> here is `Canvas` + `TimelineView(.animation)` (iOS 15) and `onGeometryChange` (back-deployed to
> 16.0), so every file runs the same code on every OS at or above the 16.0 floor. §7.1's filter asks
> whether a later tier shows the user something the tier below cannot; for a particle field and a
> `UserDefaults` day marker, none does.
> - **Full path:** run on the 26.5 simulator (every row below) and on E's phone from `main`.
> - **Reduced:** run on sim (injected — 06, 07, 08, against the control at 09).
>   **NOT on device.** Pending E's Reduce Motion ON pass, which covers this block AND
>   `F-CTACelebrations-4` together (E deferred `-4`'s passes to after this block).
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.

Nobody here can say "works on iOS 16" yet, and nothing in this folder does.

## Why this folder exists

Four claims in this block cannot be made by any assertion in the suite.

**1 · The chain runs end to end, driven the way a user drives it.** The suite proves a real service
ASKS (`CaptureInboxServiceCelebrationTests`) and that the app's hosts thread the centre
(`CelebrationMilestoneCallSiteTests`). Neither puts a single piece of paper on screen. 00 and 01 do:
a real `CaptureInboxService` sorts the last waiting capture, a real `CelebrationCenter` takes the
request, and a real `CelebrationLayer` draws it — **1,174,626 pixels** differ from the control.

**2 · And that is not vacuous.** The control (00) is the same code with a SECOND capture still
waiting. Nothing is drawn, and `centre.bursts` is empty. Without this half, "the chain drew it"
would be equally true of a build that celebrated every exit.

**3 · The reduced path is a still field that fades**, not an absence and not a hard cut (§7.2).
06–08 are the same 120 pieces at rest across the canvas at three instants, and 09 is the control
that shows the comparison can see the difference between still and falling at the same moment.

**4 · A downgraded milestone is a pop from the RING** (R-h), not a full-screen wash and not a pop
from the middle of the screen. 11 is driven through the real centre, so the downgrade is
`CelebrationPolicy`'s and not the probe's.

## What driving the real screens caught that the tests could not

**A defect, found by looking at 11 and asking where that origin comes from when the user is not on
Home.** The daily goal is E's "any tab" milestone: it fires from Home while the user may be on
Tasks. `AppTabContent` parks a hidden tab **10,000 pt** off screen — and the probe measured that the
offset reaches a `.global` frame reading:

| tab state | `.celebrationPopOrigin` reports |
|---|---|
| visible | **(196.5, 451.0)** |
| parked (`AppTabContentLayout.hiddenTabOffset`) | **(10196.5, 451.0)** |

So R-h's fallback pop would have been thrown 10,000 pt off screen whenever the crossing happened on
another tab — the milestone silent in exactly the case R-h exists to prevent, and nothing in the
suite could have seen it: the origin is correct, the request is correct, and the pop is drawn
faithfully at a point nobody can see. `CelebrationPopOrigin.onScreen` now refuses a parked origin,
and `nil` (which the layer centres) is deliberately the answer rather than a clamp — the ring
genuinely is not on screen, so the middle of the screen the user IS on is the honest place for it.

The harness was proved deterministic before any pixel claim above: one scene rendered twice,
**0** differing pixels, against a control at another instant differing in **1,176,079**.

## The files

| file | what it proves |
|---|---|
| `00-control-inbox-not-empty.png` | The control for 01: the same real service and real centre, with a second capture still waiting. **Nothing drawn, to the pixel.** PNG because the claim is exactly zero. |
| `01-live-milestone-through-the-real-chain.jpg` | The real `CaptureInboxService` → real `CelebrationCenter` → real `CelebrationLayer`, over a real empty inbox. Rain from the top, both cannons, the done-green glow. 1,174,626 pixels differ from 00. |
| `02-inbox-zero-light-1200ms.jpg` | The milestone at 1.2 s in light: the rain is arriving, the cannons are still climbing. |
| `03-inbox-zero-dark-1200ms.jpg` | The same instant in dark. The seven confetti tokens and the glow carry both appearances; nothing here is light-only. |
| `04-inbox-zero-light-2600ms.jpg` | 2.6 s, light — the full field, mid-fall. |
| `05-inbox-zero-dark-2600ms.jpg` | 2.6 s, dark. |
| `06-reduced-still-field-200ms.jpg` | Reduce Motion, 0.2 s: **the first frame already has the final geometry** (§7.2's opening-pose rule) and only opacity travels. |
| `07-reduced-still-field-1600ms.jpg` | The same pieces at 1.6 s, at full opacity. Identical geometry to 06 — that is the point. |
| `08-reduced-still-field-5100ms.jpg` | 5.1 s: fading out, still not falling. |
| `09-control-full-motion-at-the-same-instant.jpg` | The control for 07 — 1.6 s with full motion. Without it, "the reduced path is still" would be a claim about two pictures nobody compared. |
| `10-daily-goal-over-the-tasks-tab.jpg` | E's F7, "any tab": the daily goal is requested from Home and drawn over the Tasks list, by whichever layer is frontmost. |
| `11-downgraded-milestone-is-a-pop-from-the-ring.jpg` | R-h: inside the 5 s cooldown the milestone becomes a pop, from the ring's own point — no glow, no wash. Driven through the real centre, so the downgrade is the policy's. |

## How to rebuild the probe

Block 3's recipe holds — a scene-attached `UIWindow`, a synchronous `RunLoop.main.run(mode:before:)`
pump, appearance via `window.overrideUserInterfaceStyle`, RGBA comparison rather than PNG bytes, and
the harness proved deterministic before any pixel claim. Block 4's two additions hold too
(`.fixedSize` on a `minHeight`-flexible row; let the handle escape the wrapper's body). One thing
this block added:

- **`MILESTONE_PROBE_OUT` passed on the `xcodebuild` command line does NOT reach the test process**
  — it is taken as a build setting, and the probe falls back to `NSTemporaryDirectory()`, which is
  the simulator's own app-container `tmp`. That is not a failure: the probe prints the path it
  actually wrote to, and the files are copied out of the container afterwards. Read the printed
  path rather than assuming the environment variable landed.
