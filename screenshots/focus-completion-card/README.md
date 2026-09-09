# F-FocusCard-2 — the completed-unconfirmed card

**Environment.** iPhone 17 Pro simulator (iOS 26.5), rendered at 393pt wide / 3x from the unit-test
host at branch `feature/focus-card-2` @ `5ceb195`, 2026-09-09. **No backend, no account, no
sign-in** — the two images are `UIGraphicsImageRenderer` captures of the real
`FocusCompletionCard` hosted in `UIHostingController`, driven by three literal
`CompletedFocusSession` values. No throwaway data was created and nothing was written to
Firestore. The probe that produced them was deleted in the same commit; the only thing kept from
it is the 76pt measurement, now pinned by
`FocusCompletionCardTests.testTheCardIsASingle44ptBandInsideItsPadding`.

## Why this folder exists

**Block 1 shipped a `layoutPriority` bug that no test could see, and E caught it in a screenshot
AFTER the merge.** `.layoutPriority(1)` on the sprint title made SwiftUI compress its priority-0
`Text` siblings to nothing: the life-area emoji vanished and the PAUSED badge rendered as a 1pt
sliver. The block-2 handoff named this as the trap most likely to recur, because this card puts a
title, a duration and a Confirm button on one row — and it says so in terms: *"if you reach for
`layoutPriority` there, get a device look, not just a green suite."*

**This card does reach for it** (the title, so the trailing `Spacer` cannot absorb the width
first), so the guard is `.fixedSize()` on the two rigid siblings — the emoji and the Confirm
label. Whether that guard actually worked is a **width** question, and
`UIHostingController.sizeThatFits` reaches a view's total height but not the width of a `Text`
inside an `HStack`. So nothing in the suite can answer it. These two images are the answer.

`FocusCompletionCallSiteTests.testTheCardsRigidPiecesCannotBeCompressedByTheTitle` is the coarse
textual companion — it fails if a `layoutPriority` ever appears here without a `.fixedSize()`
beside it — but it asserts the presence of a fix, never that the fix worked.

## What the render settled that the tests could not

1. **The emoji survives.** 💼 is present at full size on all three rows, which is the exact thing
   that disappeared in block 1.
2. **The Confirm capsule is not compressed.** It holds its full label and its 44pt height beside a
   priority-1 title — the failure mode that reduced the PAUSED badge to a sliver.
3. **The title truncates, and only the title.** Row 2's deliberately over-long name ellipsises at
   the column edge while everything either side keeps its size.
4. **Both themes read correctly.** `StateGo` / `OnStateGo` are the same pair
   `OfflineSprintSummaryCard`'s "Got it" button already uses, so the two completion surfaces speak
   one language even though they are deliberately separate flows.

## What is NOT settled here, and is E's call

The design record described this card as sharing the collapsed running card's *"full-bleed flush
geometry"*. That was written before block 1, where E reversed full-bleed on device — and "flush"
is only available to the bottom-most piece of bottom furniture, which this card deliberately is
not (it stacks **above** a sprint that may already be running, so the running card stays
operable). It therefore takes the **expanded** card's geometry: 16pt inset, 24pt radius on all
four corners, `.regularMaterial`, one keyline. **E has not seen this and has not chosen it.**

## Files

| file | what it proves |
|---|---|
| `00-completion-card-light.jpeg` | Light mode, three rows: the 25m 30s / 2-checkpoint case, a deliberately over-long title, and a short one. The emoji is present and the Confirm capsule is full size on all three — the block-1 compression bug is absent. |
| `01-completion-card-dark.jpeg` | The same three in dark. Confirms the `StateGo` / `OnStateGo` pair and the keyline read correctly against the night surface, where block 1's other invisible bug (a concrete colour painting literal black over a material) lived. |
