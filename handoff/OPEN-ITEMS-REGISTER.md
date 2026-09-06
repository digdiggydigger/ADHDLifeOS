# Open items register — 2026-09-06 (second edition today: widget fold landed; B1 SOLVED and its harness fix landed; the clearance pair is now reproducible)

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and to
update, rather than improvising a list in chat. Supersedes this morning's true-close-out edition.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `db32a55`** (PR #5's merge), local = remote, tree clean, only `main` exists · every
change lands through a PR (protection unchanged) · last full verification AT `db32a55`: unit
suite **2,462 / 0** with the emulator UP, SwiftLint **0 / 705**, both targets build · **full UI
target ran ONCE on main at `c333c55` (pre-fix, the B1 evidence run): 30 tests / 6 failures, the
unstable set MOVED again** — bundle `UIFullRun.xcresult` kept in the repo root (gitignored), its
exported hierarchy attachments are the defect's proof · the four post-fix proof runs each erased
the sim afterwards (the poison rule held all day) · **E's phone runs this morning's build — the
widget-store fold IS app code and is NOT on device yet** · `firestore.rules` untouched this
session · the emulator was left running.

**Shipped and CLOSED this session (this edition):**
- **F-WidgetStoreFold** (PR #4, `3a831d2`) — register A3's widget half, on E's word: both App
  Group widget snapshots cleared AND both timelines reloaded on session end (sign-out and the
  account-deletion hand-off). Neither payload carries an owner field and the widget process has
  no auth concept, so the last user's task titles and area names kept rendering on the Home
  Screen. TDD staged (compile-red, then each source pin watched fail as an assertion);
  post-commit red-check 3 injections → 1 + 1 + 2, each its own guard. Suite 2,462 / 0.
- **B1 — the tab-root not-hittable defect: SOLVED, and its fix landed** (PR #5, `db32a55`,
  probe deleted). Root cause from the failure dump's automatic hierarchy attachments: **iOS's
  own AutoFill "Save Password?" sheet** interposes over the app on its own late schedule
  (>15s after a fresh-credential sign-in), and while it is up hit-tests die across the WHOLE
  app window — even at points far outside the visible sheet. Every historical property follows
  (the shuffling set, the erased-sim reproduction, "no interrupting elements"). The hidden-tabs
  hypothesis is dead — nothing of theirs in any dump. The sheet is addressable ONLY through the
  app's own tree: `app.alerts` is the wrong TYPE and `springboard.sheets` the wrong PROCESS,
  both falsified in runs before the working query. Fix:
  `UITestSession.dismissSystemPasswordPromptIfPresent()` (`UITestAutofill.swift`) woven into
  every retry helper; proof: it fired once in each previously-failing journey (`[AUTOFILL]` in
  the log) and both passed. `HitTestProbeUITests` DELETED — dump job done, never caught it in
  60+ rounds.
- **The full-UI-target-once-on-main record B1 asked for**: 6 failures, membership moved again
  (AccountName and testSettings joined; FirstRunJourney and testDueNudge left) — final
  confirmation the set tracked timing, not the tree.

## A · Decisions only E can make — minutes each

- [ ] **`DailySummaryStore` — sweep it too, or accept at-rest?** E's 2026-09-06 fold call
      covered the two widget stores; this one was left. Verified: the blob (it QUOTES task
      titles and journal reflections) survives sign-out AND account deletion on disk, but it
      stores a `userId` and `belongs(to:)` refuses foreign/unattributed reads — content-at-rest
      only, never displayed cross-account. Finishing the family is one line in the session-end
      hook plus a pin.
- [ ] **Reinstall E's phone from main** — the widget fold is app code and the device doesn't
      have it; a signed-out phone still shows the old widget data until then. E via Xcode, or
      authorise a `devicectl` install.
- [ ] **Re-measure coverage?** CLAUDE.md records 23.62% at `b1f4b6f`, stale — the suite has
      since grown to 2,462. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)

## B · Real work, ready to start — recommended order

1. **The CaptureDiscClearance pair — now REPRODUCIBLE, and post-sweep it looks REAL.** Failed
   3-for-3 on 2026-09-06 with NO password sheet in their dumps (so not the B1 cause):
   `testToday_theLastCardIsNotUnderTheCaptureDisc` has the week-review row resting at
   y=640–716 under the disc at 690–750 — a ~26pt overlap AT REST — and
   `testNudges_theNewNudgeRowIsNotUnderTheCaptureDisc` reports the door never coming into
   reach "even scrolled to the end". Candidates: the 92pt `captureDiscClearance` inset not
   reaching Today's scroll end, or the scroll stopping early. Next step: drive Today on an
   erased sim to the end and read the inset path; these are geometry ASSERTIONS, so the
   failure is honest either way.
2. **Full UI target once more on main, post-sweep** — sets the new baseline; expectation is
   the clearance pair plus possibly the two watch-list flakes (section E). ~67 min.
3. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
4. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
5. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles (valid to 2026-09-10). (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Two watch-list flakes, one sighting each today** (post-sweep run): `testRenderSignUpForm`
  "Keyboard never appeared" (sim keyboard flake) and `LandscapeLoginUITests` "Signing out did
  not return the app to the login screen" (the rotation family). Watch, don't chase — one
  sighting is not evidence either way in this suite.
- **`UIFullRun.xcresult`** in the repo root is the B1 evidence bundle — keep it until the
  clearance pair (B1 above) is settled, since its dumps are also THEIR pre-sweep record.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in routine-record block 1's red-check — failure-path only,
  unexplained. (carried)
- **The emulator was left running** (`scripts/emulators.sh`, restarted this session after a
  machine reboot killed it); `firestore-debug.log` in the repo root is the truth for a write
  that "silently" failed.
- **The review-session journal rows** from the swipe-path experiment — E's own data,
  deliberate, nothing to clean up. (carried)
