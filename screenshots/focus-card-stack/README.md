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
