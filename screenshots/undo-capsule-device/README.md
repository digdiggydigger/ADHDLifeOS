# `F-C1-UndoCapsule` — the shipped shape on E's own phone

> **E's device look, 2026-09-22, taken by E and handed over as eight frames.** The shape round
> (2026-09-20) was decided from simulator renders; this is the first time the SHIPPED shape has
> been seen on a real phone. **It passes.**

**Environment:** E's iPhone 15 Pro, **iOS 27.0**, the LIVE Firebase project and E's real account
(so the data is E's own, not a fixture), `main` @ `4917955` installed wirelessly, Reduce Motion
**OFF**, app force-quit before the first frame. Frames are E's own screenshots.

**Verified paths:** `26/27 path: run on E's phone (RM off)`. **No RM-on pass was owed** — `F-C1`'s
reduced path PASSED on 2026-09-20 and the shape round changed no reduced site.

## What E's frames settle

1. **All four things the shape round asked for are true on the device** (`00-`): the card is
   **fully rounded**, there is **no chip behind Undo**, the subject sits on **one line**, and
   "Sun20Sep Test" reads in full where the pre-round shape truncated.
2. **The capsule is one slot across the whole app, and these frames prove it by accident.**
   `05-` closes Today's hero — the ring goes 3 → 4 of 8 and the capsule appears where the retired
   in-place closure card used to be. `06-` is the Capture Inbox moments later carrying **the same
   "Closed · test22sep"** capsule: it survived a tab switch, which no unit test can see.
3. **Three different kinds, three different verbs, one shape** — "Closed" (`00-`, `05-`, `06-`),
   "Skipped" (`03-`) and **"Sorted to 💼 Work"** (`07-`), the last resolving its area label at the
   moment of recording exactly as `RecentActionKind.captureSorted(areaLabel:)` intends.
4. **Design C's tab bar behaves as specified**, which is worth recording because a simulator frame
   suggested otherwise. `AppTabBarPresentation.showsLabel` is `isSelected && !isFloating`: `06-`
   has the bar at rest and the pill reads **"Captures" in full** beside a two-digit badge, while
   `03-` and `07-` have it floating and the selection is the icon-only chip. **This retires the
   "Captu… truncation" note in `../drafts-to-inbox/README.md` as a device claim** — see that file,
   which is corrected rather than deleted.

## What `01-` does and does NOT settle — read this before citing it

`01-` is the same close at the **largest STANDARD text size**, and `02-` is the settings page it
was taken at: the slider is at the top of its range with **"Larger Accessibility Sizes" OFF**.
E supplied `02-` precisely so a later reader would know which size `01-` is.

- **What it settles.** At xxxLarge the capsule still draws as one row, fully rounded, with every
  element inside the card. The subject truncates earlier ("Sun20Sep…") because the Undo control
  keeps its own width as type grows — the documented trade from the height round, seen on a phone.
- **What it does NOT settle: the radius cap.** The cap (`min(minHeight, height) / 2`, E's call of
  2026-09-20) only differs from a plain `Capsule` once the card grows TALL, and the card grows
  tall only when the layout stacks — which happens at **accessibility** sizes, i.e. with the
  toggle in `02-` turned ON. At xxxLarge a capped capsule and an uncapped one are the same shape,
  so this frame cannot distinguish them. **The cap is verified on the simulator only**
  (`../drafts-to-inbox/04-note-closed-capsule-kept-in-your-inbox-AX3.jpg`, where the stacked card
  keeps glyph, verb, subject and the wider "↗ Reopen" control inside its fill). One toggle would
  give it device evidence; it is not owed by any block.

## Still owed after this round

**`F-C2-DraftsToInbox` has no device frame.** None of these eight shows the *"Kept in your inbox ·
Reopen"* capsule or task detail's restored left-edge swipe-back, so that look remains outstanding —
recorded here rather than assumed discharged because all eight frames are `F-C1`'s surfaces.

## The frames

| file | what it proves |
|---|---|
| `00-tasks-the-shipped-shape-default-size` | **The shape round, on a phone.** Fully rounded, no chip behind Undo, one line, and the subject reading in full. The four things E asked for. |
| `01-tasks-the-same-close-at-xxxlarge` | The same close at the largest standard text size: still one row, still rounded, everything inside the card; the subject truncates earlier as the Undo control keeps its width. **Not a test of the radius cap** — see above. |
| `02-the-text-size-01-was-taken-at` | E's own documentation of `01-`: slider at the top of the standard range, **"Larger Accessibility Sizes" OFF**. The frame that stops `01-` being cited as accessibility evidence. |
| `03-inbox-skipped-with-the-bar-floating` | A triage skip's capsule on the Capture Inbox, with the tab bar FLOATING — the selection is the icon-only chip, Design B's state, and the header ↶ is present reading the same slot. |
| `04-today-before-the-hero-close` | Today at 3 of 8 closed, hero "test22sep" with its "Close it". The "before". |
| `05-today-hero-closed-capsule-not-a-card` | The "after": ring at 4 of 8, the capsule where the retired in-place closure card used to be, and the hero recomputed to the next best move rather than being replaced by a celebration. |
| `06-inbox-the-same-capsule-after-a-tab-switch` | **The one-slot claim, caught in the act.** The same "Closed · test22sep" capsule, now on the Captures tab — it survived the switch. Also the tab bar AT REST, with the pill reading "Captures" in full beside a two-digit badge. |
| `07-inbox-sorted-to-work` | **"Sorted to 💼 Work"** — the area label resolved at record time, on real data, with the capsule's third verb. |
