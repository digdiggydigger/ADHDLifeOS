# `F-CTACelebrations-6` — the routine Completed flow, wired

**Environment:** iPhone 17 Pro simulator, iOS 26.5, Firebase **emulator** (Auth + Firestore on
`127.0.0.1`), a fresh throwaway account created by the journey harness, **2026-09-13**. Every image
is an `XCUIScreenshot` taken by `RoutineJourneyUITests` on the run at `0e07c39`, exported from the
result bundle and converted to JPEG. **Nothing here has been on E's phone** — see "Still owed".

**Throwaway data:** the harness creates its own account per run and seeds one place ("Gym 🏋️") into
that account's own Firestore subtree, all inside the emulator. Nothing touches the live project, and
the simulator was **erased** (`xcrun simctl erase 9181EBF9…`) immediately after the run, in the same
command chain, per CLAUDE.md's poisoned-simulator rule.

## Why this folder exists — and it is not the layouts

**One of these pictures caught a defect that every test in the block passed over.**

`PlaceRoutineProgress.earnedCelebration` is E's approved R-f rule: a celebration needs at least one
step the **user** tapped done, and a run resolved only by automatic steps and skips "completes
quietly — the congratulation, no confetti". It was written, unit-tested across four shapes, and
**called by nothing**. The first wiring of `complete()` therefore requested the milestone
unconditionally, and the journey's run — 1 auto step + 3 skips, deliberately unearned — came back
carrying full-screen confetti.

Ten call-site guards, 2,957 unit tests and both UI journeys were green while it did. What said
otherwise was looking at `08-`. That is the seventh recorded instance of this repo's most repeated
defect, and the first one found by this practice rather than by a later block tripping over it.

**The confetti image itself was not kept** — it was exported to a scratch directory and deleted
before the defect was understood. `0e07c39`'s commit message is the record; `08-` below is the same
scene after the fix, and the contrast has to be read rather than seen. Keeping the before-shot would
have been better, and the lesson is cheap: export a journey's attachments **into this folder**
before deciding which ones matter.

The rest earn their place the ordinary way — E's R1 is a rule about what does and does not happen
when you leave a screen, which is a sequence rather than a state, and no still of one screen can
carry it.

| file | what it proves |
|---|---|
| `05-all-steps-resolved.jpg` | Every step resolved (1 auto + 3 skipped) and the next-step card gone — the state that used to end the run by itself. |
| `06-closed-but-still-live.jpg` | **E's R1, and the picture the reversed journey exists for.** The screen has been CLOSED with everything resolved, and Today's card is still there saying "All steps done". Before this block, closing here ended the run and took the card with it. Also **C7**: the button reads **"Finish routine"**, not "Continue routine" — E's answer 8, which only became reachable once "resolved but unconfirmed" stopped being a flicker. |
| `07-completed-card.jpg` | The Completed card in the slot the next step would have had — never beside a live one. **Undo is still offered on all three skipped steps**, which is the whole reason E's R1 puts the ending behind a deliberate tap. E's wording, hyphen-minus and all: "1 of 4 done - Ready to finish?". |
| `08-congratulation-quiet.jpg` | The congratulation as E designed it, on a run R-f says is **unearned**: greeting, summary, the pinned detail card with its done-green border, the four 12-hour times (E's answer 8: "8:58 am", minutes always, no seconds), "Time on the routine", the step rows with E's rewording ("Auto", "Skipped after 23s"), and "Tap anywhere to close" — **and no confetti**. The 0.40 light-mode wash E chose by eye is the green under all of it. No "compare to your usual" line, correctly: this is the routine's first run, so there is no history to compare against and the comparison draws nothing rather than inventing a verdict. |
| `09-card-gone.jpg` | Only after the Completed tap does Today's card go. The card is the run's only pull surface, so its absence IS the run having ended. |

## What driving the real screens caught that the tests could not

- **The R-f gap above.** A call-site guard can only assert a call it knows to look for.
- **The detail card is legible against the wash at 0.40** and its done-green border reads as a
  border rather than as a highlight. Both were approved by E on a render of the leaf alone; this is
  the first time either has been seen over a real fetch, with real clock times, inside the cover.
- **Tapping a step ROW dismisses the congratulation.** E reversed answer 6 to make the step list
  scroll, and the mechanical worry was that the scroller would eat the tap. Both journeys now tap
  `routineCongratulationStep-0` — inside the `ScrollView` — rather than the greeting outside it, so
  SwiftUI's "a DRAG goes to the scroller, a TAP goes to the parent's gesture" is exercised on every
  run instead of assumed. A still cannot show this; the journey passing is the evidence.

## Verified paths

> `26 path: run on sim + NOT on device. Reduced: run on sim (injected); NOT on device.`
> `16 path: code run on 26.5 by injection; OS-level behaviour COMPILE-ONLY — no 16 runtime installed.`

## Still owed

- **§7.3's RM-on device pass.** C6 adds this block's reduced site — the congratulation's entrance,
  `PlaceRoutineCongratulationEntrance.fade`, an opacity-only cross-fade whose first frame is already
  at final geometry. Since E turned Reduce Motion **off** on 2026-09-12 that path is no longer
  exercised incidentally, so it needs E to toggle Reduce Motion ON and look once. Until then this
  folder may not claim device evidence for it.
- **Nothing in this block has been on E's phone at all**, reduced path or not.
