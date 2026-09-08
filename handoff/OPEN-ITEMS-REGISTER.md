# Open items register — 2026-09-08, late evening (fourteenth edition; F-PillReTap MERGED on E's verdict, nothing in flight)

*This edition closes the day. After the tab depth arc merged (thirteenth edition), E's GIF showed
the capture disc staying a pill after a re-tap scrolled the page to the top; the cause was traced,
the fix built test-first, red-checked, put on E's phone, and merged on E's words — *"I've just
checked that on my phone and it works."* The phone was reinstalled from `main` and the suite
re-run ON main. The thirteenth edition (`3f8ee9b`) is in git history; this one carries only what
is still true.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes the thirteen earlier editions.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `a6b8021`** (PR #37, F-PillReTap; the tab depth arc is `1100a01`, PR #35) · **no
branch in flight**; `fix/pill-retap` and `feature/tab-depth` both deleted both sides by their
merges · every change lands through a PR · verified ON MAIN at `a6b8021`: **unit suite
2,546 / 0** (emulator UP, 0 `127.0.0.1:9099` hits, 0 skipped), **SwiftLint 0 / 720**, device
build green · **app target 24.76% (11,192/45,206)** — denominator +10 over `1100a01`'s 45,196
(the pill rule and the reselect method), numerator +3 · `SearchRowDepthJourneyUITests` 1 / 0 and
`TabReselectionJourneyUITests` 3 / 0 (carried from the tab-depth branch; neither file changed
since) · **E's phone runs `main` @ `a6b8021`** (binary 21:03, `App installed`, `Launched`, no
provisioning trouble) · sim `9181EBF9…` ERASED after the day's two UI runs, shut down and signed
out · `firestore.rules` untouched · the emulator was left running · every `.xcresult` deleted
after its figures were read.

**Shipped and CLOSED this session — F-PillReTap (PR #37 → `a6b8021`, code `9a919a8`):**

- **E's report, with a GIF:** *"the Quick Capture button, if in collapsed pill form, when tapping
  the same tab page and it scrolls to the top of the page, the pill stays collapsed."* The frames:
  the bar restored 2 s after the re-tap while the disc stayed a pill until a finger nudged it.
- **Cause:** `CaptureDiscScrollActivity` has two inputs — the window-level pan gesture and the
  tab-change `reset()`. The re-tap's scroll-to-top is `proxy.scrollTo`, programmatic, no touch;
  the pan recogniser never reported it. The bar reads `contentOffset`, which does move.
- **Fix, inside E's settled 2026-08-31 disc rule** ("until the page is scrolled upwards again" —
  this IS that scroll): `TabReselectionResponse.restoresCaptureDisc` (scroll-to-top true,
  pop-to-root false) and `RootView.reselectTab(_:)` in `RootView+Reselect.swift`. Collapse rule,
  thresholds and timing untouched.
- **Evidence:** tests first, watched red twice (compile; then the call-site guard on its own
  assertions with the rule in and the root unwired); red-checked one at a time after the commit
  (1/1, 1 test/1 test, restore 17/0); **E's device verdict in words.** No UI journey can see the
  pill — the disc's outer frame is 60×60 in both states by design — so the verdict is the record.

**Shipped and CLOSED earlier the same day — F-TabDepth, blocks 1 + 2 (PR #35 → `1100a01`)**, on
E's *"All 4 checks were successful"*, with E's two screenshots at `screenshots/tab-depth/`.
(carried; nothing about it changed)

## A · Decisions only E can make — minutes each

- [ ] **Keep the search row's spring on a tab SWITCH?** Block 2's one judgment call: the row
      fades with the house spring when the tab changes, not only when a detail is pushed. E's
      checks passed on the build that has it and E has raised nothing; listed only because it
      was never one of the checks. One line in `RootBottomOverlay.swift` to revert. (carried, low)
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still
      to leave it. (carried)

## B · Real work, ready to start — recommended order (nothing is in flight; ask E)

1. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   A fix that ARRIVES but lands outside every radius still clears the card (the app ignores
   `horizontalAccuracy`; the probe puts it at ~3% of pulls at 40 m jitter with Home alone, 27%
   at 65 m). Widening `LocationFixProviding` to carry accuracy touches every caller, which is why
   it was not bundled into the coin-flip fix. (carried, deferred on purpose)
2. **`HomeService.load()` empties `allTasks` on a failed fetch**, which would drop the card
   through the re-check; the inbox precedent keeps last-known on failure. One line + one test.
   (carried, small)
3. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
4. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
5. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the clock restarted with the 06:37 device build, so the
  profile is roughly valid to **2026-09-15**. None of the day's four later device builds needed
  a provisioning update. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **A programmatic scroll is invisible to a gesture-driven model.** The pill (pan-driven) and the
  bar (offset-driven) diverged the moment something other than a finger moved the page. Any
  future programmatic scroll — a deep link that lands mid-page, a "jump to today" — has to tell
  the pill itself, the way the re-tap now does. (NEW)
- **`RootView.swift` is at 399 of 400 lines.** New members go in an extension file with the
  touched members made `internal` and a comment saying why (`RootView+Reselect.swift` is the
  third such file). (NEW)
- **Stacking a block on an unverified block is fine when E asks for it, and the PR should say
  so** — separate commits per block, and the merge waits for the verdict. (carried)
- **A "rule right, wiring wrong" red is worth staging on purpose** — the call-site guard and
  the UI journey both fail on their own assertions, proving they catch the defect this repo
  ships most. Used twice today. (carried)
- **Derive, then `onChange` the derived value.** (carried)
- **`xcrun xcresulttool export attachments --path <bundle> --output-path <dir>`** pulls a
  journey's screenshots out of the result bundle; **`ffmpeg -vf "fps=2,scale=360:-1"`** turns
  E's GIF into readable frames (no PIL or ImageMagick on this machine). (carried, extended)
- **A locked phone refuses the LAUNCH and not the install.** (carried, confirmed)
- **`grep -c 'Test Case.*failed'` counts test NAMES containing "failed"** (eight exist); read
  the `Executed N tests, with M failures` line. (carried)
- **Ask before designing when E invites it; read the user's REAL data before choosing between
  hypotheses.** (carried)
- **The resolver's tie-break was designed for different radii**; take the ordered LIST. (carried)
- **The fence ledger shows all three home fences flapping departure → arrival within 4 s.**
  (carried)
- **A swiftc probe of the pure files + the user's real coordinates settles a geometry question
  in a minute.** (carried)
- **A `CGContext` bitmap is TOP-DOWN**; **red-check regressions ONE AT A TIME**; **iPhone
  Mirroring cannot be started from the terminal.** (carried)
- **A percentage over a denominator that includes code the test target never compiles is not a
  coverage figure.** (carried)
- **A `??` autoclosure is a REGION**; `xccov view --archive --file`. (carried)
- **Failing tests pay a one-off warm-up per RUN** — never scope a red-check down for speed.
  (carried)
- **The 70% coverage bar is arithmetically out of reach without UI tests.** (carried)
- **The emulator harness held its ground.** (carried)
- **The watch-list is EMPTY.** (carried)
- **The strong-password pane is environmental.** (carried)
- **The DEBUG test-fire bypasses the master switch and cooldown BY DESIGN.** (carried)
- **The live opener is `START-HERE-post-pill-retap.md`** — `START-HERE-post-tab-depth.md`
  consumed and archived in the same move. Exactly one is live. (updated)
- **A `NavigationPath` is blind to closure-link and flag pushes, and a path reset pops neither**
  — the design record has the table. (carried)
- **The harness's `openTab` returns early on a selected slot**; the late "Save Password?" sheet
  swallows swipes as well as taps — wait for HITTABLE. (carried)
- **A zero-height anchor view inside a padded stack costs its spacing** — put the `id` on the
  padded root. (carried)
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The emulator was left running.** (carried)
