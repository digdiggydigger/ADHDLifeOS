# `F-E3-OneCardToday` — Today's one card

**Environment:** iPhone 17 Pro simulator · iOS 27.0 · Firebase Emulator Suite (fresh throwaway
accounts, one per test, `e3onecard-…` / `e3resume-…`) · `TodayOneCardRenderUITests`, one appearance
per run, the simulator erased and warmed ~45–60s before each · 2026-09-26. Suffix `-L` light,
`-D` dark, `-A` light at Accessibility Extra Large (AX3). `00-` files are the boards E answered from.

## Why this folder exists

Unit tests pin the slot order, the pin and skip stores and every string. Only the real screen shows
the card where it sits, the pin and "Not this one" answering a tap, the next step saved from the
card, the capsule after a close, the Resume card, and the two doors that moved. **Driving it caught
two things no test had:**

1. **The capture disc covered the done line's "Week review ›" at rest** in every Today frame with a
   two-row "then" list, light and dark. `CaptureDiscClearanceUITests` stayed green because it
   asserts the row is clear once SCROLLED to rest, and it was (~50pt of scroll). E chose to move the
   link after the count (Q3, below).
2. **The card's "Close it" words measure 2.74:1 in light** (`StateGo` on its own 12% tint; the
   number is computed from the colorsets, not sampled from these JPEGs). E kept them and sent the
   fix to the colour arc (Q4, below).

It also showed three harness faults, fixed before the frames here were taken: iOS's "Save
Password?" sheet re-appeared over frame 02 (now cleared before every frame); the Tools row sat
under the undo capsule frame 05 leaves up (now lifted to mid-screen); and the AX3 card STACKS
Close over "Not this one" by design, so the side-by-side "one height" check does not apply there.

**Throwaway data:** each run creates its own emulator account and seeds two areas and four tasks
into it. Nothing touches the live project; the emulator state is not exported, so nothing persists
past the emulator's restart.

## The boards E answered from (2026-09-26)

Q1 and Q2 were rendered with the REAL tokens and the shipped button styles at 402pt by a throwaway
`ImageRenderer` probe, deleted after (board `59`'s precedent). The next-step line is drawn as
`Text`: `ImageRenderer` cannot draw a UIKit `TextField` and paints a yellow "no" bar in its place —
a probe artifact, not the app. Q3 and Q4 are real harness frames of a temporary edit, reverted after.

| file | what it settled |
|---|---|
| `00-E3-Q1-close-layout.jpg` | `F-E1`'s gain line "Close it — makes today count" in H1's half-width Close. A: side by side, 354pt card, two lines (three at xxxLarge, where the render caught the pair going RAGGED — 84pt beside 48pt — fixed with one-height pairing, `buttons.md › Style`). B: stacked, 410pt. **E: "A · Side by side".** |
| `00-E3-Q2-done-line.jpg` | The done line once a daily goal is set. **E: "B · '3 of 5 done today'"** — with the ring gone, the only place a chosen goal can be seen. |
| `00-E3-Q3-done-line-vs-disc.jpg` | Where "Week review ›" sits. A: the right edge, as built — the disc covers "review" at rest. B: after the count, round 5b's "✓ 0 done today · Week review ›". **E: "B · Follows the count".** |
| `00-E3-Q4-close-contrast.jpg` | Close's words, light: as built 2.74:1 vs primary-colour words 16.89:1. **E: "A · Keep, send to colour arc"** — a Critical held for that arc. |

## The frames

| file | what it proves |
|---|---|
| `01-suggested-{L,D}.jpg` | The Suggested card: eyebrow, title, the next step, time + area chips, ONE prominent "Start 15 min" (56pt), the quiet pair at one height (Close 165 × 48 beside "Not this one" 165 × 48), the corner pin; the "then" list; the done line with the link after the count, clear of the disc. |
| `01-suggested-A.jpg` | AX3: the compact card — title, then the buttons, then the details — with Start ABOVE the fold (asserted, not just shown: Start's bottom at 565pt, the tab bar's top at 780pt), and the pair stacked (Close 338 × 137 over "Not this one" 338 × 51). At rest the disc sits over the right end of "Not this one"; the AX3 page scrolls it clear (a Low, recorded). |
| `02-pinned-{L,D}.jpg` | Pinned: the pin fills, the eyebrow reads "Next · Pinned", "Not this one" is gone. |
| `03-not-this-one-{L,D}.jpg` | "Not this one": the next due task takes the card ("Start 30 min") and the skipped task is back in the "then" list. |
| `04-next-step-on-the-card-{L,D}.jpg` | A next step typed on the card and saved by Return survives (`value` asserted). |
| `05-closed-from-the-card-{L,D}.jpg` | Close from the card: the undo capsule, and the done line counts it ("1 done today"). |
| `06-tools-nudges-row-{L,D}.jpg` | Nudges' door on Tools, beside Routines (E, 2026-09-24). |
| `07-areas-week-review-row-{L,D}.jpg` | The second Week review door, at the top of Areas. |
| `08-week-review-from-areas-{L,D}.jpg` | The review that door opens. |
| `09-resume-card-{L,D}.jpg` | A PAUSED sprint takes the card: Resume only, no "Not this one". Not shot at AX3 — the shared sign-in helper cannot reach Settings' sign-out at that size, a harness limit older than this block; the spec asks AX3 of the Suggested card. |
