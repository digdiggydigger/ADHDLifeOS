# Tab bar — C's labelled pill at rest, B's chip scrolled (F-TabBar-SelectPill)

**Environment:** E's iPhone 15 Pro (`wishwashwacky15`), dark mode, live Firebase, signed in as E,
**2026-09-08 02:38**, branch `feature/tabbar-select-pill` @ `96681a3` (round 1). Taken by E, not
by the session — iPhone Mirroring was not running, so these are E's own screenshots from
`../Ethan's Screenshot Folder/`, filed here because they are the evidence for a decision E
settled by looking. E's GIF of the morph (`nav-tab-bar-in-action.gif`, 7.8 MB) stays in E's
folder; it is not in the tree.

**What driving the real screen caught that the tests could not:** the tests pin the pill's
rules and the touch-target floor; they cannot say whether the resting bar *reads right*. It
did not. E's verdict on `00-`: *"the nav bar shouldn't extend down to the bottom of the screen…
must stay floating as it is in [`01-`] BUT MUST still display the labelled pill."* That
verdict deleted the opaque full-width pane — inherited from Design F — and made the floating
card the bar in both states (round 2, `e9cd764`). No throwaway data was created.

| # | file | what it proves |
|---|---|---|
| 00 | `00-round1-rest-flat-pane-REJECTED.jpeg` | Round 1 at rest on Today: the C pill ("Today", capsule-less, 8pt from the edge) on the opaque pane running to the bottom of the screen; Captures badge "20". **Rejected by E** — the pane. The pill itself was liked. |
| 01 | `01-round1-scrolled-floating-card.jpeg` | Round 1 scrolled: Design B's floating card, chip on Today, content visible on all four sides. **This is the shape E wants at rest too**, with the pill in it. |

Round-2 device shots (one card, wider/higher at rest with the capsule pill; contracted and
dropped while scrolling) are owed — add them as `02-`… when the phone can be captured.

## Round 2 on the phone (E's screenshots, 2026-09-08 04:41, branch @ `e9cd764`)

E's own shots again (mirroring still not running); JPEG'd from E's PNGs. Verdict: *"I like
what you've done… there are some obvious spacing and positioning things that need to be sorted
out"*, then two annotated shots. **What driving the real screen caught that the tests could
not:** the card measured **60pt tall on the device** while the metrics said 50 — the slot's
44pt minimum height leaked into the row — and the disc sat 22pt above the card instead of the
measured 32. Reproduced in a standalone simulator probe of the real bar files; fixed in round 3.

| # | file | what it proves |
|---|---|---|
| 02 | `02-round2-light-rest-today.jpeg` | Round 2 at rest, light: the card floats (inset 8, lift 16 — both measured), the "Today" capsule pill 4pt from the card's edge, the far wrench ~16pt from the other edge. Card 60pt tall. |
| 03 | `03-round2-light-scrolled.jpeg` | Round 2 scrolled, light: inset 12, lift 8, chip 44×34 — B as shipped, measured. |
| 04 | `04-round2-dark-rest-areas.jpeg` | Rest with a MIDDLE tab selected: symmetric (12pt each side); the icon shift is C's own trade-off. Slot positions matched the arithmetic to within 0.3pt. |
| 05 | `05-round2-dark-scrolled.jpeg` | Scrolled, dark. The second rounded outline above and below the bar is a **page card behind it** (E confirmed), not a bar defect — the card surface is opaque (asset alpha 1.0). |
| 06 | `06-round2-E-marks-width.jpeg` | **E's annotation**: red marks ~6pt in from each screen edge — *"WIDEN the horizontal width"*. → round 3 insets 4 / 8. |
| 07 | `07-round2-E-marks-icon-padding.jpeg` | **E's annotation**: the Captures pill with the glyph crowded and the badge on it — *"increase the inner-padding of the icon inside the blue highlight"*. → round 3 highlight 44 tall, pill padding 16. |

Round 3 (`8578a23`): insets 4 / 8, lifts 8 / 4, highlight 44 tall, pill padding 16, card
60 = 44 + 16 by design. Device shots still owed as `08-`….
