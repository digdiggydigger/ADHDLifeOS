# START HERE — three device looks from E on three shipped blocks, one of them with Reduce Motion ON

*Written 2026-09-17 at the close of the session that shipped `F-LandscapeFabOverlap`,
`F-TabBarPillInset` and `F-FanCardsFade` (PRs #137, #141, #142) and installed them on E's phone.
**This is a disposable pointer — archive it when you write your successor.** The design records it
leans on are permanent: `SESSION-OPENER-tabbar-select-pill-design.md` (round 4 is the pill's
inset) and the three blocks' own write-ups in `TODO-CLAUDE-CODE.md`.*

## Read these first, in this order

1. `claudecode.md` — the TDD role definition.
2. `CLAUDE.md` → **Architecture notes**, **§2** (now TWO named waivers), **§7.1–7.5**. NOT `docs/`.
3. `handoff/OPEN-ITEMS-REGISTER.md` → **State** and **§B**'s first three items — the whole of this
   opener.
4. `screenshots/landscape-fab-overlap/README.md` (all three blocks' evidence, the device frames
   E sent, and the open question) and `screenshots/tabbar-pill-inset-options/README.md`.
   **The measurements are done; do not re-derive them.**

## State when this was written

`main` @ the SHA `git log --oneline -1` prints — every block is merged, the tree is clean.
Suite **3,029 / 0**, SwiftLint **0 / 819**, build green (37 distinct warnings, the Phase C figure).
The Firebase emulator started by this session may still be running (`lsof -iTCP:8080`); the
harness uses it if it answers and skips if not. The colour-scheme arc stays on E's HOLD
(2026-09-13); its opener is in `handoff/archive/`.

**E's phone (iPhone 15 Pro, iOS 27.0) carries `main` @ `9eb5198`** — all three blocks. Installed
and signed clean; the launch was denied only for `Locked`, so E opens it by hand. **The signing
profile in that build expires 2026-09-17T19:25:02Z.** If E reports the app "won't open", the
first move is a rebuild + reinstall (`device-build-lag` memory has the recipe), not a bug hunt.
Check `xcrun devicectl list devices` before asking for any verdict; install first if the phone is
behind (`ask-for-device-checks-on-a-build-e-has`).

## The three looks — ask for all of them in ONE message

1. **Landscape with a sprint running** (`F-LandscapeFabOverlap`): the cards take the column
   bottom-left and the disc keeps its corner. Does it read right in the hand? E's frame 07 shows
   it working; no verdict word yet.
2. **The pill at 12** (`F-TabBarPillInset`): E chose it from renders; does it read right at the
   pill's edge on the phone, Today and Tools? If E wants another number after seeing it, it is
   the same one-constant change: the pin test and CLAUDE.md §2's second waiver move with it.
3. **The fan fade, with Reduce Motion OFF then ON** (`F-FanCardsFade`): open the capture fan with
   a card up. The cards fade out and the tiles behind them are free. **This block ADDS a reduced
   site**, so §7.3's rule applies — the reduced fade has only run on the simulator by injection.
   The "Verified paths" line reads *"Reduced: run on sim (injected) — NOT on device"* until E
   toggles and says so.

## The open question the fade exposed — E's call, NOT built

With a card pushing the disc up in portrait, **the × sits on the PHOTO tile** (frame 14; the same
overlap E's own frame 8508 showed before the fade). Cause: `CaptureFanOverlay` anchors the arc to
the screen's bottom-trailing corner — the disc's RESTING spot — while the × is ~200pt higher.
Two shapes, in the register §B: re-anchor the arc to the ×'s real centre (fine with one card;
with the away card AND a Confirm stack the top tile clips off the top edge, so it needs a cap), or
let the × drop to its corner while the fan is open (the cards are invisible then; the × moves under
the thumb as the fan opens). Do not build either before E chooses.

## Also carried, unchanged

- Frame 08's observation: the pushed-up disc floats over the hero's *Start another session* in
  portrait — pre-existing, not raised by E, an observation only.
- Phase D's one unlooked-at delta: the schedule summary line's dimness in dark on 27.0.
- The colour-scheme arc: HELD.

## Harness facts this session established (all recorded in the blocks and READMEs)

- The away card can be raised at launch with no production seam: `-focus.sprint.unacknowledgedCompletion
  "<hex>"` in `launchArguments` (`UITestUserDefaultsSeeds.swift`).
- `app.screenshot()` lies on a rotated simulator — landscape evidence is host-side
  `xcrun simctl io <udid> screenshot` polled while the test `hold()`s the pose.
- The AutoFill "Save Password?" sheet produced one false control failure 70 s after sign-in on a
  loaded sim. **Never run SwiftLint or anything heavy beside a UI run.**
- `TEST_RUNNER_` environment variables did not reach the hosted unit-test process on this scheme.
