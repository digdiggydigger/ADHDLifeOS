# Open items register — 2026-09-08, SESSION close-out (eighth edition; the seventh, minutes earlier, closed the tab bar — this one records E's two closing calls)

*This edition covers **F-TabBar-SelectPill (PR #29)** — the first of E's new-feature ideas, taken
from "reopen the edits to the app's Navigation bar" to merged in one night, through THREE device
rounds judged from E's own screenshots. It also carries the handoff:
`START-HERE-new-features.md` archived, `START-HERE-post-tabbar-select-pill.md` written in the
same commit. **Eighth edition, same close-out:** E then made two calls — *delete the bundles*
(done, 39 → 0, a gigabyte back) and *"in the next session i want to deal with the 'You're at
home' card vanishing on drag-reload"* — so the opener was rewritten as
`START-HERE-home-arrival-card.md` (renamed, never consumed) and B1 below is AUTHORISED.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the six earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `76a4f47`** (PR #29) · local = remote, tree clean, **only `main` exists** (the feature
branch was merged and deleted by the merge; `git fetch --prune` cleared the ref) · every change
lands through a PR · re-verified ON MAIN: **unit suite 2,505 / 0** (emulator UP), **SwiftLint
0 / 711**, sim build green · **app target 24.77% (11,133/44,940)** · no `127.0.0.1:9099` in any
of the fourteen run logs; no UI target was run · **E's phone TRACKS MAIN at `76a4f47`** —
rebuilt from main after the merge, installed and launched 05:52 · `firestore.rules` untouched ·
the emulator was left running.

**Coverage, read the CLAUDE.md way:** the denominator moved 44,961 → **44,940** (−21) because
the bar's view body SHRANK (the flat pane and its dot went); the numerator moved 11,114 →
**11,133** (+19) — the new pure rules (`showsLabel`, `restingSlotWidth`, `slotHitOverflow`,
the derived metrics). Both runs measured the whole app target, so the ratios are comparable and
the change is real: 24.72% → 24.77%.

**Shipped and CLOSED this session (PR #29, seven commits):**

- **F-TabBar-SelectPill** — E reopened the bar against the original six-concept canvas and
  chose to **combine B and C**. What shipped, after three rounds on the phone:
  **one floating card in both states** (the flat pane is gone for good); at rest it sits
  4pt in from the edges and 8pt above the safe line with the selected tab as a **capsule pill,
  glyph + label**, 44 tall, 16pt inner padding; scrolled it contracts to 8pt in and 4pt up and
  the mark is the icon-only chip (44×44). The morph is the label collapsing and the card
  sliding; `TabBarScrollActivity`'s near-top rule was already the trigger and did not change.
  `rowHeight` is the card plus the larger lift (60 + 8 = **68**) so the `safeAreaInset` never
  moves with the morph. E, 05:43: *"I think it looks good."*

  ```
  round 1  C's pill on the flat pane            → "shouldn't extend down to the bottom… must stay floating"
  round 2  one card, 8/16 rest, 12/8 scrolled   → "obvious spacing and positioning things" + 3 asks
  round 3  4/8 · 8/4 · highlight 44 · pad 16    → APPROVED
  ```

  Tests **2,497 → 2,505** (+8 net: the class went 22 → 30, several rewritten). Red-checked
  three times: round 1 four regressions → exactly the four predicted; round 2 three together →
  only TWO of three, because two CANCELLED (`restingLift` 8 made `max(8, 8)` equal
  `floatingLift`), then the band regression alone → 1 / 1; round 3 one at a time → 1 / 1,
  1 / 1, 3 / 3. Evidence: `screenshots/tabbar-select-pill/` (00–10, README rows for each).
  Design record: `handoff/SESSION-OPENER-tabbar-select-pill-design.md`.

**The finding worth more than the feature:** measuring E's round-2 shots found **the card was
60pt on the device while the metrics said 50** — the slot's 44pt `minHeight` (§3's touch
target) leaked into the row, so `cardHeight`, the band, the disc's 32pt gap and
`appTabBarClearance()` were all 10pt out, and had been since F-Tools-2-Morph shipped the
floating state. `slotHitOverflow` (negative vertical padding around the slot's `contentShape`)
now carries the target without growing the card, and the metrics are true. Reproduced and
re-verified in a standalone simulator probe of the real bar files.

## A · Decisions only E can make — minutes each

- [x] **Delete the spent `.xcresult` bundles?** — **E: "yes you can clear those."** Done at this
      close-out: 39 bundles, 1.4G → **0**, boot disk 21Gi → **22Gi free**; `git status` untouched
      (all were gitignored). CLAUDE.md's documented test command writes to `TestResults.xcresult`
      and works verbatim again. RESOLVED — carried in this file since the fourth edition.
- [ ] **Should the widget's view-only files be made testable at all?** Unchanged from the sixth
      edition; recommendation is still to leave it. (carried)

## B · Real work, ready to start — recommended order

1. **The "YOU'RE AT HOME" card on Today vanishes on drag-reload — AUTHORISED as the next
   session's first job** (E, closing 2026-09-08: *"in the next session i want to deal with…"*).
   E's report: *"does not stay there when the user drag-reloads the Today page. Which is kind
   of pointless."* Read first-hand at this close-out: the card is `ArrivalSurface`
   (`Places/ArrivalSurface.swift`, rule: no card unless something is OPEN at this place);
   pull-to-refresh is `HomeView.refreshEverything()` → `refreshArrivalSurface()`
   (`HomeMomentumSections.swift:356`), which takes a FRESH location fix and sets the surface to
   nil on any failure. **Two hypotheses, different fixes — the opener spells them out:** (a) a
   failed re-resolution on the pull throws away a card that was correct a second ago; (b) the
   card is honestly gone because its one task was CLOSED (E's own 04:41 → 05:41 screenshots
   show exactly that transition). Investigate, then ask E which they saw. NEW, authorised.
2. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
3. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
4. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with today's builds (05:52), so the
  profile is roughly valid to **2026-09-15**. (updated)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A `CGContext` bitmap is TOP-DOWN.** My pixel reader flipped rows and the card appeared to
  move the wrong way with the lift; two hours of theory followed. Draw a ruler in the probe and
  check the reader against a KNOWN position before concluding. In the design record. (NEW)
- **The swiftc probe settles geometry in a minute** — real bar files + colour shim + `actool` +
  `simctl io screenshot`. Reach for it before theory. The probe (`com.probe.tabbar`) is still
  installed on the test sim; harmless, an erase clears it. (NEW)
- **Red-check regressions ONE AT A TIME** — two can cancel. Second instance of the register's
  "symmetric swap" note; now a rule. (NEW)
- **iPhone Mirroring cannot be started from the terminal**; E's own screenshots, filed with README
  rows, worked well as the evidence route. (NEW)
- **The "second outline" behind the floating bar in dark mode is a page card**, not a bar
  defect — the card surface is opaque (asset alpha 1.0); E confirmed. (NEW)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** (5.1 s / 2.4 s / 2.5 s on the first failure this
  session, then milliseconds) — never scope a red-check down for speed. (carried)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is `START-HERE-home-arrival-card.md`.** `START-HERE-new-features.md` was
  archived at the seventh edition; the seventh's own successor
  (`START-HERE-post-tabbar-select-pill.md`) was RENAMED and rewritten into this one minutes
  later on E's closing call, never consumed, so nothing was archived twice. Exactly one is live,
  and it is an investigate-then-ask opener with the two hypotheses and the code pointers.
  (updated)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
