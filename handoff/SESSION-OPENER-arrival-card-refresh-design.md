# Design record — the arrival card and the drag-reload (F-ArrivalCardRefresh, 2026-09-08)

*This is the design record and the why, not a session opener. It stays. Written the morning E
reported the card vanishing on a pull, after the investigation E asked for and E's one-word
answer to the one question it produced.*

## What E saw

Today, 06:14: *"YOU'RE AT HOME 🏠 · 1 thing lives here · test quick"*. One drag-reload. No card.
`test quick` still open, At Place = Home. E, 2026-09-08 04:xx: *"does not stay there when the user
drag-reloads the Today page. Which is kind of pointless."* E, 06:12, asked which case: **"Still
open."** Evidence: `screenshots/arrival-card-refresh/`.

## What was actually happening

The card's rule was sound — no card unless something is open at the place you are at — and the
place you are at was the problem. E's account holds **three places at home**, all at the 100 m
floor radius: `Home`, `Action Test 01/09/2026` (left over from the place-actions field walk,
centred **1.2 m** from Home) and `routines test` (34.5 m). `PlaceResolution.place(containing:)`
chose ONE: smallest radius, then nearest centre, then id — designed for "the office inside the
town centre", where the radii differ. With equal radii the nearest centre decides, and 1.2 m is
inside the jitter of every fix a phone takes indoors. A probe over the real geometry files, with
E's real coordinates and 10,000 seeded fixes:

```
jitter σ   Home wins   (Home alone)
 10 m        50%          100%
 20 m        40%          100%
 40 m        31%           96%
 65 m        21%           69%
```

Every fix succeeded. The card still went on most pulls, because a pull took a fresh fix, the
fresh fix picked a different coin face, and `arrivalSurface` was overwritten with whatever the
new resolution said — including nil when the fix simply did not arrive (8 s timeout, a request
already pending, airplane mode).

The opener's other hypothesis — the task had been closed — was also real that night
(`september`, closed 04:53) and is correct behaviour. E's answer ruled it out for the report.

## The two rules that shipped

1. **"Here" is every place the fix fell inside, tightest first.** The resolver now exposes the
   ordered list, and the single-winner function is its head so they can never disagree. The card
   shows the first containing place with something open. Two containing places both with work
   resolve to the tighter one — the same "most specific answer is the useful one" the resolver
   already stood for.
2. **A refresh replaces the card only when a fix positively says otherwise.** The resolution
   reports what it knows — nothing to be at, no fix, or the places a fix fell inside — and the
   refresh rule applies that to the card already showing. No fix keeps the card, re-checked
   against the fresh tasks (closed work drops it; new work joins it). A fix inside no place is
   the one honest "you have left". Toggle off or permission gone clears it, so a card never
   outlives the feature.

Neither rule changes what the card looks like, or when it appears the first time at a place with
nothing open — E's "ambient truth on Today is noise" principle is untouched.

## Alternatives considered, and why not

- **Don't re-resolve location on a pull at all** (rebuild only from the fresh tasks). Fixes the
  pull, leaves the first appearance a coin flip, and makes a pull unable to notice you have
  moved. Rejected: rule 1 was needed anyway, and after it the re-resolution is cheap and honest.
- **Keep the previous card whenever the new resolution is nil.** Masks the coin flip but also
  keeps "You're at Home" when you are standing in Lidl. Rejected: "no fix" and "inside nothing"
  had to be told apart, which is why the resolution grew three states instead of one optional.
- **Accuracy-aware containment** (a fix whose accuracy circle overlaps the place counts as inside).
  The right next lever if a fix that ARRIVES outside every radius still clears the card in
  practice — ~3% of pulls at 40 m jitter with Home alone, 27% at 65 m. Deferred, on the register,
  because it widens the fix provider's contract for every caller and the coin flip was the bug.

## Data hygiene E may want

`Action Test 01/09/2026` and `routines test` are both test places from earlier arcs. Deleting
them would have hidden this bug without fixing it, and a public-launch user will have
overlapping places legitimately (home inside the neighbourhood, gym inside the town centre), so
the code had to handle it. Whether E keeps the two test places is E's call and changes nothing
here.
