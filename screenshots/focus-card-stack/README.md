# F-FocusCard-3 — the notification-style stack

**Environment.** iPhone 17 Pro simulator (iOS 26.5), rendered at 393pt wide / 3x from the unit-test
host on branch `feature/focus-card-3`, 2026-09-09. **No backend, no account, no sign-in** — these
are `UIGraphicsImageRenderer` captures of the real `FocusCompletionCardStack` hosted in a
`UIHostingController` over `Color.pageBackground`, driven by three literal `CompletedFocusSession`
values. No throwaway data was created and nothing was written to Firestore. The probe that produced
them (`ZZFocusStackRenderProbe.swift`) was deleted in the same commit that added this folder.

Getting a real three-card stack on a device would mean sitting through three sprints, each floored
at 30s by `FocusCheckpoints.minimumIntervalSeconds`, and confirming none of them. A render costs a
minute.

## Why this folder exists

**The tests could not see the bug this caught, and they all passed while it was on screen.**

The card's background is `.regularMaterial`, which *blurs* what is behind it rather than hiding it.
The first build of the stack drew a full `FocusCompletionCard` at every layer, so the second card's
progress ring and summary line **ghosted through the front card** as a pale smudge — worst in dark
mode, where the ring's `StateGo` green reads brightest against the night surface. Every layout
assertion held: the offsets, scales, opacities and draw order were all correct, and the defect was
in what the cards behind were *drawing*, which no unit test reaches.

The fix is that the layers behind draw a **blank card body** (`FocusCompletionCardEdge`) — same
shape, same material, same keyline, same 76pt height, no content. Only the top edge of a card
behind is ever visible, and that edge carries no information; an iOS notification stack shows blank
rounded bodies behind its front notification for the same reason.

This is the second time in this arc that a `View`-level defect survived a green suite — block 1's
`layoutPriority` compression was the first, and it reached E's device.

## What the renders settled that the tests could not

1. **The ghost is gone.** Compare `01` against `04` at the card's top-left: the rejected build
   shows a pale rounded blob where the second card's ring sits behind the front one; the shipped
   build is clean.
2. **The stack reads as three cards, not as one thick slab.** Two 8pt peeks plus the 5%-per-layer
   shrink are enough to separate them in both themes.
3. **The peek goes UPWARD, and it has to.** The card sits directly on the running timer bar, so a
   downward peek would hide the older cards behind a sprint the user may still be running.
   `FocusCompletionStackLayoutTests.testThePeekGoesUpwardsSoTheStackCannotShipUpsideDown` pins the
   sign; this is what the sign looks like.
4. **A single card is unchanged from what E approved in block 2.** `03` is the same card at the
   same geometry — no peek drawn, and no top padding reserved for one.
5. **The peeks clear the search row, and the running sprint below stays operable.** `06`/`07`
   render the REAL `RootBottomOverlay` — search row, capture disc, the three-layer stack and a
   running sprint's expanded card in one column — because everything above was rendered over a
   bare background and could not answer a composition question. `.offset` reserves no layout, so
   the stack pads its top by `reservedTopPadding(forCount:)`; against the VStack's own 8pt
   spacing that leaves a clear gap under the search row rather than the collision the reservation
   exists to prevent. The sprint's Pause / +30s / +5m / Stop are all reachable underneath, which
   is why the card stacks ABOVE the running one.
6. **Both themes read.** The light peek is carried almost entirely by the `StateGo` keyline, since
   the material and `pageBackground` are close in value; the dark peek is carried by the body as
   well. Legible in both, and noticeably quieter in light — **worth E's eye on device.**

## Files

| file | what it proves |
|---|---|
| `00-stack-three-light.jpeg` | Three layers, light. Newest in front, two peeking edges above it, each narrower than the last. |
| `01-stack-three-dark.jpeg` | The same three in dark, where the ghosting bug was most visible. The area behind the front card's ring is clean. |
| `02-stack-two-light.jpeg` | Two layers — one peek. The common real case: a routine started a second sprint before the first was confirmed. |
| `03-stack-one-light.jpeg` | One card, and the regression check on it: identical to the block-2 card E approved, with no reserved peek space above it. |
| `04-rejected-ghosting-dark.jpeg` | **The rejected build.** Full cards behind the front one: the second card's ring ghosts through the material as a pale blob at the top-left, and its summary line as a smudge across the card. |
| `05-rejected-ghosting-light.jpeg` | The same rejection in light, where it is subtler but still present. |
| `06-in-situ-three-light.jpeg` | **The real composition**, light: `RootBottomOverlay` with the search row and capture disc above, three layers, and a running sprint's expanded card below. The peeks clear the row; the sprint's controls are all reachable. |
| `07-in-situ-three-dark.jpeg` | The same composition in dark. |
| `08-device-stack-light.jpeg` | **E's iPhone, light.** Two layers — the front card and one 8pt peek — over real scrolled Home content. |
| `09-device-stack-dark.jpeg` | **E's iPhone, dark.** The same moment, same content, same sprint. The pair is the light/dark comparison the renders could not settle. |

## The device pair, and the answer to the light-mode question (added 2026-09-10)

**Environment.** E's own iPhone 15 Pro (`wishwashwacky15`), iOS 26, **live Firebase, E's real signed-in
account**, app build `ddb480f` (block 3 as merged), captured by E at 22:49 on 2026-09-09. Both shots
are the same moment — 10:48 on the status bar, the same Home scroll position, the same completed
sprint (`5m focused · 1 checkpoint`) — so the only variable between them is the theme. No throwaway
data: the sprint and the routines are E's own, and nothing was created or cleaned up for the shot.

**Two layers, not three.** Exactly two keylines appear, 24px apart at 3x = **`peekStep` 8pt,
confirmed on real hardware**; there is no third at y≈1878 (flat background from y=1866 to 1886). The
front card measures 227px tall = **75.7pt, i.e. the specified 76pt**. Both constants are now
device-verified rather than only asserted.

**The open question was whether the light peek reads. Measured off these two files, it does not
carry on its own — and the README's prediction was right.** Sampled at x=250–400, clear of the ring
and the text (luminance is WCAG-relative; contrast is against the page background):

| | light | dark |
|---|---|---|
| page background | `RGB(249,241,230)` | `RGB(49,45,37)` |
| **peek strip** (the visible 8pt sliver) | ΔL **−3.4**, **1.03:1** | ΔL +6.1, **1.09:1** |
| **peek keyline** | ΔL −28.1, **1.30:1** | ΔL +31.3, **1.62:1** |
| front card body | ΔL −16.8, **1.17:1** | ΔL +21.8, **1.39:1** |

**In light the peek's BODY is doing nothing — 1.03:1 is indistinguishable from the page** — so the
second card is carried entirely by its `StateGo` keyline at 1.30:1. In dark the body contributes
(1.09:1) *and* the keyline is 25% stronger (1.62:1). Every element is quieter in light; the card
body itself reads 1.17:1 against the page there, versus 1.39:1 in dark.

For reference, WCAG 1.4.11 asks **3:1** for a non-text boundary that carries meaning. Nothing here
reaches it in either theme. Whether a peeking edge is "meaningful" or decorative is a design call,
not a measurement — and **E made it on 2026-09-10: `peekStep` 8 → 14**, after being shown six
rendered options in `../focus-card-light-peek-options/`. `opacityStep` and `scaleStep` are
unchanged. **These two device shots therefore record the 8pt peek, which no longer ships** — they
are the evidence that prompted the change, not a picture of current behaviour.

**One thing the renders could not have shown, and it is not a defect:** the card floats over
whatever is scrolled beneath it, so here its bottom edge lands directly on a routine card's green
"Done for now" button. That is occlusion, not the `.regularMaterial` ghosting block 3 fixed — the
card body sampled uniform through that band, and the button's pixels start below the card's bottom
edge at y=2153, not inside it. Worth knowing before anyone reads the pair as a ghosting relapse.
