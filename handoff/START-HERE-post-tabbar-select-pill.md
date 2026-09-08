# Start here — the tab bar is DONE (three device rounds, merged). E has more ideas: listen first.

*Paste into a fresh Claude Code terminal. Written 2026-09-08 at the close of the session that
reopened the tab bar on E's word and shipped `F-TabBar-SelectPill` in three device rounds in one
night (PR #29, `main` @ `76a4f47`). E's phone was reinstalled FROM MAIN at the close.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them
is a trap — see CLAUDE.md, "Session handoff". Archive this file into `handoff/archive/` in the
same move that writes your successor, at the END of your session, never at the start.

---

## The one instruction that matters

E's direction on 2026-09-07 stands: *"shift our focus to spend some time working on some new
items to add to the LifeOS app."* The tab bar was the FIRST of those ideas, and it is finished.
**E is bringing the next one. Open by inviting it, then get out of the way** — do not recite the
candidate list, do not open `TODO-CLAUDE-CODE.md` looking for a block. The shape that worked
last night, and for every arc before it: E describes; ask one question at a time until the
acceptance criteria are testable; write the design record; write the block; build test-first;
put it on the phone; stop for E's verdict; repeat. Three rounds of that shipped the bar.

**Two things E said last night that are NOT the next idea but are logged, so you can raise
them if E asks what is outstanding:**
- *"the 'YOU'RE AT HOME' notification box at the top of the Today page does not stay there when
  the user drag-reloads the Today page. Which is kind of pointless."* — a Today refresh bug,
  register section B. Not authorised; needs its own look at the place-context card's lifecycle
  across a pull-to-refresh.
- The three F-TabBar tunables are now single constants (`restingInset` 4 / `floatingInset` 8,
  `restingLift` 8 / `floatingLift` 4, `chipHeight` 44, `pillPaddingHorizontal` 16) and E
  approved them as built. Do not re-tune unprompted.

## Read these, in this order

1. **`CLAUDE.md`** — Workflow, Version Control (every change lands through a PR; `main` is
   protected), Session handoff, Visual evidence, UI/UX §1–§7.
2. **`claudecode.md`** — the TDD role definition.
3. **`handoff/OPEN-ITEMS-REGISTER.md`** — THE outstanding list, **seventh edition**, rewritten
   at this close-out.
4. **`handoff/SESSION-OPENER-tabbar-select-pill-design.md`** — the newest settled design record,
   and the house style for one: three rounds, E's words verbatim, every number with its why, and
   the two measuring lessons at the bottom of round 3.
5. `handoff/VISION-adaptive-lifeos.md` — still the richest source of candidate work if E asks.

**Do NOT read `docs/`.** It is an archive of a legacy build and says this app runs on Supabase.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # expect 76a4f47 (PR #29 merge) or later
git log --oneline -1 origin/main     # same SHA
swiftlint lint                       # expect 0 violations, 711 files
```

Last verified ON MAIN at `76a4f47`: unit suite **2,505 / 0** (emulator up), lint **0 / 711**,
sim build green, app target **24.77% (11,133/44,940)** — the denominator moved by −21 because
the bar's view body shrank; the numerator +19 is the new pure rules. **E's phone tracks main at
`76a4f47`** (rebuilt from main after the merge, installed and launched). Free-dev-account
profile roughly valid to **2026-09-14**.

## Traps that matter right now

- **`TestResults.xcresult` still exists in the repo root and CLAUDE.md's documented command
  writes there** — pass a dated `-resultBundlePath`. There are now **thirty-nine** bundles
  (seventeen from this session); deleting them is STILL section-A, sitting with E.
- **Erase the sim between a UI run and any unit run** — `xcrun simctl erase
  9181EBF9-0F54-4A4D-A19C-19945D1BF155`. No UI target ran this session; 0 `9099` hits in every
  log. The tab-bar PROBE app (`com.probe.tabbar`) is installed on that sim — harmless, but an
  erase clears it.
- **Geometry: probe first, theory second.** The real bar files compile into a standalone
  simulator app in a minute (`xcrun -sdk iphonesimulator swiftc -parse-as-library`, a colour
  shim, `actool` for the catalogue, `simctl install/launch`, `simctl io screenshot`) — that is
  what found the 60-vs-50pt card. **And a `CGContext` bitmap is TOP-DOWN**: a pixel reader that
  flips rows makes everything appear to move the wrong way. Draw a ruler in the probe and check
  the reader against a KNOWN position before concluding anything. Both lessons are in the
  design record.
- **Red-check regressions ONE AT A TIME.** Two injected together cancelled last night
  (`restingLift` 8 made `max(8, 8)` equal `floatingLift`) and hid a real gap in the prediction.
- **Commit BEFORE any red-check**, restore with `git checkout --`, prove by rebuilding.
- **iPhone Mirroring could not be started from the terminal** — `connection_state()` was
  `not-running` and only E can connect it. Every device screenshot last night was E's own, filed
  from `../Ethan's Screenshot Folder/` into `screenshots/tabbar-select-pill/` with a README row
  each. That worked well; ask E for shots rather than waiting on mirroring.
- **Never automate auth.** The emulator was left running.
