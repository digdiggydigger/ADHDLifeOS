# F-CTACelebrations-PopScale — the pop at the size E chose on the device

**Environment.** iPhone 17 Pro simulator (iOS 26.5, the machine's only runtime), rendered at 2× from
the unit-test host at a fixed 393 × 852 pt — **E's iPhone 15 Pro's point size, so what E judged is
life-size** — on `feature/cta-celebrations-pop-scale`, 2026-09-12.

- **No backend, no account, no sign-in, nothing written anywhere.** Every scene is plain value types
  over a real `TaskRow`; no probe touched Firestore or the simulator's own `UserDefaults`.
- One throwaway probe, `ZZPopScaleProbe`, ran from the test target and was removed before the commit
  that adds this folder. Rebuild it from `screenshots/cta-celebrations-block-5/README.md`; the copy
  used here is kept in this session's scratchpad.
- **No throwaway data was created**, on device or in any backend, so there was nothing to clean up.

## Why this folder exists

**E asked for this by looking at the app on their own phone**, after `F-CTACelebrations-4` and `-5`
both passed their device passes. In three messages:

> *"I think that the scaling of the 'pop' needs to be increased slightly."*
> *"Bigger spread too, not just bigger pieces."*
> *"Maybe slightly increase the amount of confetti pieces."*

So the decision is three-dimensional, and no assertion can make it: how big a burst of paper reads
on a 393 pt screen is exactly the class of thing CLAUDE.md's "Visual evidence" section says to
render rather than to test. E picked **variant C** from four rendered in situ on a real `TaskRow`,
the same way E picked the pop's family (variant A of four) in `F-CTACelebrations-4`.

## The choice, and what each variant measured

Everything rides ONE constant, `CelebrationRecipes.popScale`, so the three dimensions cannot drift
apart. Measured at the pop's most legible instant (220 ms), with the furthest piece taken at 400 ms
straight off `ConfettiPhysics`:

| variant | scale | pieces | paper on screen | furthest piece |
|---|---|---|---|---|
| **A** — as shipped | 1.0× | 18 | 2,087 px | 140 pt |
| **B** | 1.3× | 24 | 3,998 px | 174 pt |
| **C** — **E's pick** | **1.6×** | **29** | **6,100 px** | **208 pt** |
| **D** | 2.0× | 36 | 10,354 px | 253 pt |

**The variants in 00 are a PREVIEW, and the difference is worth stating.** To show more pieces
before the recipe could produce them, the probe asked `CelebrationRecipes.pop` for successive
ORDINALS and took the first N — each ordinal is a fresh scatter from the same origin with the same
count, angle, speed, lifetime and colour distribution, so it previews "the shipped recipe with a
larger count" rather than a hand-rolled imitation. Size and speed were multiplied on the returned
pieces.

**01–05 are not a preview.** They render `CelebrationRecipes.pop` itself with nothing scaled by the
probe at all, so this folder shows what actually ships. The shipped pop measures **28 pieces, 5,590
painted pixels and a furthest piece at 208 pt** — against variant C's 29 / 6,100 / 208. The spread
matches exactly; the count and area differ slightly because the shipped recipe draws its count from
the scaled range with one seed rather than concatenating ordinals. **That is the check worth having:
the thing E approved and the thing that ships were measured the same way and agree.**

## Verified paths (CLAUDE.md §7.3)

> **No `#available` site is added or changed by this block, and no tier was passed over.** It is four
> constants and a defaulted parameter — the same code on every OS at or above the 16.0 floor.
> - **Full path:** run on the 26.5 simulator (every row below) and on E's phone from `main`.
> - **Reduced:** the still pop scales with the pop (05), run on sim. **NOT on device** — this block
>   changes a reduced site, so it owes an RM-on pass (§7.3).
> - **iOS 16–25:** behaviour is COMPILE-ONLY; no older runtime is installed.

## The files

| file | what it proves |
|---|---|
| `00-the-four-variants-E-chose-from.jpg` | **The choice.** Rows top-to-bottom A (as shipped) / B / C / D; columns 80 / 220 / 400 ms. E picked **C**. |
| `01-shipped-pop-080ms.jpg` | The SHIPPED pop, 80 ms: the paper is still a tight cluster on the close-circle. |
| `02-shipped-pop-220ms.jpg` | 220 ms — the throw at its most legible, and the instant every number above was measured at. |
| `03-shipped-pop-400ms.jpg` | 400 ms: drag and gravity have taken over, furthest piece 208 pt from the tap. |
| `04-shipped-pop-dark-220ms.jpg` | The same instant in dark. The seven confetti tokens carry both appearances; the scale changes nothing about that. |
| `05-shipped-reduced-still-pop-300ms.jpg` | Reduce Motion: the still pop's 48 pt scatter scales with the pop to 76.8 pt, so E's bigger pop and its reduced counterpart cannot drift apart. |

## What is deliberately NOT scaled

**The milestone's 120-piece still field.** `CelebrationRecipes.piece(...)` is shared by the pop, the
still pop and the still field, so scaling it in one place would have silently enlarged the confetti
behind every full-screen milestone — a celebration E did not ask to change, and one E had approved
by sight two hours earlier. `sizeScale` defaults to 1 and only the two pop paths pass `popScale`;
`testTheMilestonesStillFieldKeepsTheConfirmsOwnPaperSize` is what keeps it that way, and it stayed
GREEN through the deliberate red-check that turned every other scale-dependent test red.
