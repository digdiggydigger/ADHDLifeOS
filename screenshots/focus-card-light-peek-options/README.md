# The light-mode peek — the options E was shown

> ## ✅ ANSWERED 2026-09-10: **E chose D — `peekStep` 8 → 14.**
>
> Shipped on `feature/focus-card-3-peek` as a follow-up to block 3, test-first.
> **14 is deliberately off §2's 4/8/16/24 grid**: E was offered the on-grid 16 explicitly and
> chose 14, the value they had actually approved by sight. The waiver is recorded in `CLAUDE.md`
> §2 and pinned by `testThePeekStepIsTheValueEChoseByLooking`, so it cannot be "corrected" back.
> `opacityStep` (0.15) and `scaleStep` (0.05) are **unchanged**.

**The open A-item this answers.** The eighteenth edition of the register carried *"the stack's
LIGHT-mode peek is quieter than dark, and E has not looked at it on device"*, and named three
levers "in order of bluntness": `opacityStep` (0.15), `peekStep` (8), `scaleStep` (0.05).
**That ordering was wrong, and these renders are what proved it.** E asked to see the variants
rather than read numbers — their 2026-09-03 direction, *render the thing and send the image*.

**Environment.** iPhone 17 Pro simulator (iOS 26.5), 393pt wide at 3x — E's own device width —
rendered from the unit-test host on `main @ c837f1d`, 2026-09-10. **No backend, no account, no
sign-in.** `UIGraphicsImageRenderer` + `drawHierarchy` over a real `UIWindow`, hosting the REAL
`FocusCompletionCardStack` with two literal `CompletedFocusSession` values. No throwaway data and
nothing written to Firestore.

**How the variants were produced, and why nothing shipped.** The three levers are `static let`, so
the probe could not vary them without a source edit: they were changed to `static var` for one run
and **restored with `git checkout --`, proven by a full `** BUILD SUCCEEDED **`**, with the probe
(`ZZStackVariantRenderProbe.swift`) deleted in the same move. The working tree was clean and
committed at `c837f1d` before the edit, per the standing never-destroy-uncommitted-work rule.
**No lever value was changed in what ships.**

## What the renders overturned

Measured at x=600, clear of the ring and text, against the page background:

| variant | peek height | keyline contrast |
|---|---|---|
| **A · shipped** — peek 8 · scale 0.05 · opacity 0.15 | 8.0pt | 1.30:1 |
| B · `opacityStep` 0.05 | 8.0pt | 1.35:1 |
| C · `opacityStep` 0.00 | 8.0pt | 1.35:1 |
| D · `peekStep` 14 | **14.0pt** | 1.29:1 |
| E · `scaleStep` 0.10 | 8.3pt | 1.21:1 |
| F · `peekStep` 12 + `opacityStep` 0.05 | **12.3pt** | 1.22:1 |

**Opacity was predicted to be the lever that mattered and it is the one that does least.** B and C
move the keyline from 1.30:1 to 1.35:1 — a 4% change, invisible in the render — because the layer
behind already draws at 0.85, so removing the fade entirely is a 15% change on an already-faint
hairline.

**What the eye actually reads is the HEIGHT of the sliver, not the contrast of its edge.** `peekStep`
8 → 14 is the only change that is obvious at a glance, and it is obvious immediately. `scaleStep`
0.10 makes the card behind visibly narrower at the sides but *lowers* keyline contrast to 1.21:1,
because more of that keyline falls on the corner curve.

**The general lesson, which outlives this decision:** a contrast measurement answers *"can this edge
be distinguished from its background"*, not *"will anyone notice it"*. The device pair in
`../focus-card-stack/` measured the peek strip at 1.03:1 and concluded it was carried entirely by
the keyline — correct, and it still did not predict which lever a viewer would feel. Render the
options before ranking the levers.

## Files

| file | what it shows |
|---|---|
| `00-comparison-sheet.jpeg` | **All six light variants stacked with labels, plus the dark anchor.** The one to look at. |
| `01-A-shipped.jpeg` | A — exactly what is on E's phone today. |
| `02-B-opacity-05.jpeg` | B — less fade on the card behind. Near-indistinguishable from A. |
| `03-C-opacity-00.jpeg` | C — no fade at all. Also near-indistinguishable from A. |
| `04-D-peek-14.jpeg` | D — the taller sliver. The clearest single-lever change. |
| `05-E-scale-10.jpeg` | E — narrower card behind; a side-inset cue rather than an edge cue. |
| `06-F-combo.jpeg` | F — peek 12 with a touch less fade. |
| `07-dark-shipped-anchor.jpeg` | Dark at shipped values — the reading E already accepts, for reference. |
