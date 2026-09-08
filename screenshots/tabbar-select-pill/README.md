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
