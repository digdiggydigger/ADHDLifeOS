# Open items register — 2026-09-06, FINAL close-out (fourth edition today: the defect-sweep session end to end — widget fold, AutoFill root cause + sweep, clearance bar-band fix, phone on main, fold device-confirmed, next session queued)

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding — so it is the thing to read, and
to update, rather than improvising a list in chat. Supersedes today's mid-session edition.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ `2d0f3ff`** (PR #11's merge; this edition lands as the session's ninth PR on top),
local = remote, tree clean, only `main` exists · every change lands through a PR (protection
unchanged; #4–#11 landed this session, none needed a bypass) · last full verification: unit
suite **2,462 / 0** with the emulator UP and SwiftLint **0 / 705** at the `ae190cc` tree —
**no Swift has changed since** (PRs #8–#11 touched `handoff/` and `screenshots/` only), and
lint re-ran 0 / 705 at this close-out · **the full UI target ran ONCE this session, at
`c333c55` (pre-fix): 30 tests / 6 failures — and every one of the six is EXPLAINED** (2×
AutoFill → fixed #5, 2× clearance → fixed #7, 2× watch-list flakes → section E); NOT re-run
post-fix — section B item 3 · **E's phone TRACKS MAIN** (`e4fe956` installed via `devicectl`
22:05; both app-code fixes on device; the fold DEVICE-CONFIRMED by E's screenshots,
`screenshots/widget-session-fold/`) · `firestore.rules` untouched this session · the emulator
was left running · the sim was erased after every UI run, including manually after the two
watchdog-killed runs (the poison rule held all day).

**Shipped and CLOSED this session (PRs #4–#11):**
- **F-WidgetStoreFold** (#4, `3a831d2`) — register A3's widget half, on E's word: both App
  Group widget snapshots cleared AND both timelines reloaded on session end (sign-out and the
  account-deletion hand-off); without it the last user's task titles and area names kept
  rendering on the Home Screen. TDD staged; red-check 1 + 1 + 2. **DEVICE-CONFIRMED by E's own
  screenshots the same evening** (22:46–22:49, after the 22:05 reinstall): all four widget
  types empty signed out, repopulated signed in — `screenshots/widget-session-fold/`. Do not
  re-verify.
- **The tab-root not-hittable defect: SOLVED, fix landed** (#5, `db32a55`). Root cause from
  the failure dump: **iOS's own AutoFill "Save Password?" sheet** interposing on its own late
  schedule after fresh-credential sign-ins — while it is up, hit-tests die across the WHOLE
  app window. Addressable ONLY through the app's tree (`app.alerts` = wrong TYPE,
  `springboard.sheets` = wrong PROCESS; both falsified in runs).
  `dismissSystemPasswordPromptIfPresent()` (`UITestAutofill.swift`) is woven into every retry
  helper and has now fired live THREE times across passing runs. `HitTestProbeUITests`
  DELETED. The hidden-tabs hypothesis is dead — nothing of theirs in any dump.
- **F-DiscClearanceBarBand** (#7, `ae190cc`) — the clearance pair was a REAL app defect:
  `clearance` (92) dated from the `TabView` world where the system bar reserved its own band,
  so with the custom bar the content floor rested exactly `AppTabBarMetrics.rowHeight` (58pt)
  inside the disc. Fixed by the axis split — `clearance` stays 92 as the TRAILING number
  (E's settled disc geometry untouched); new derived `bottomClearance`
  (= `bottomFurnitureLift` + disc + 8 = 158) feeds `.captureDiscClearance()`; `hasSearchRow`
  and its +60 deleted (the same missing band wearing the row's name). Acceptance: testNudges
  rests 24pt clear (green twice), testToday rests 40pt clear at the EXACT predicted frame.
  Red-check 2 + 1.
- **E's phone brought onto main** (#9 ticked it; install itself was `devicectl`, E's word) and
  **the fold's device evidence landed** (#10, `screenshots/widget-session-fold/` + README —
  which also caught the "Open Momentum once…" stale copy, now queued as B item 2).
- The handoff chores: mid-session register refresh (#6), the first close-out + opener
  succession (#8, old opener archived), next session's queue set on E's word (#11).

## A · Decisions only E can make — minutes each

- [x] **Reinstall E's phone from main** — DONE on E's word (2026-09-06 22:05): built at
      `e4fe956` (`-allowProvisioningUpdates`, zero "No Accounts"), binary stamped 22:04,
      `devicectl` install + `--terminate-existing` launch verified on `wishwashwacky15`.
      The widget fold and the clearance fix are on device.
- [ ] **Re-measure coverage?** CLAUDE.md records 23.62% at `b1f4b6f`, stale — the suite is now
      2,462. (carried)
- [ ] **The permission-banner footer** on the Routines section. (carried)

## B · Real work, ready to start — recommended order

**Items 1 and 2 are E's queued instruction, verbatim (2026-09-06): "lets handle the 'sweep of
DailySummaryStore' and the 'Open Momentum' items in the next session." They go first.**

1. **`F-DailySummarySweep` — finish the leak family.** E's call: sweep it. The blob
   (`home.dailySummary.snapshot`, app-local defaults) QUOTES task titles and journal
   reflections and survives sign-out AND account deletion; `belongs(to:)` already blocks
   cross-account display, so this closes the at-rest half. Shape is the fold's, smaller:
   `clear()` on `UserDefaultsDailySummaryStore` (nil-safe), one line in `AuthService`'s
   default session-ending hook, the source pin extended, behavior test first. No widget
   reload — nothing else reads this store.
2. **The "Open Momentum once…" widget copy.** E's call: fix it. THE WORD IS STILL E's TO PICK
   at session start — every other surface says LifeOS, so propose that and wait for the nod.
   The copy is the Life Areas widget's signed-out empty state
   (`screenshots/widget-session-fold/01-…` shows it); it lives in the widget target, and the
   copy is test-pinnable once chosen.
3. **Full UI target once on main, post-fix — the new baseline.** Expectation: green except
   possibly the two watch-list flakes (section E). Run it FOREGROUND, or one class at a time —
   the memory watchdog killed two BACKGROUND UI runs today (section E).
4. **Arc 2 — first-class routines + the "at a time" trigger.** Not authorised. (carried)
5. **`F-Search-3-Journal`** — recommendation is to kill the block. E's call. (carried)
6. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip** — smart skip has its
  data in `routine_runs`. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles (valid to 2026-09-10). (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **The 8GB machine's memory watchdog KILLED two background UI runs today**, mid-test, with
  ~70% memory free between runs and NO `127.0.0.1:9099` churn in the tail — genuine transient
  pressure during the run's own spike, NOT the poisoned-sim signature (check the tail before
  concluding either way). Foreground single-test runs passed first try. Long UI work on this
  machine: foreground, scoped.
- **Two watch-list flakes, one sighting each** (the pre-fix full run): `testRenderSignUpForm`
  "Keyboard never appeared" (sim keyboard flake) and `LandscapeLoginUITests` "Signing out did
  not return the app to the login screen" (rotation family). The post-fix baseline run (B1)
  will say whether they persist.
- **`UIFullRun.xcresult`** in the repo root (gitignored) is the session's evidence bundle —
  both root causes were read out of its automatic hierarchy attachments. Keep it until the
  baseline run confirms the fixes; its exported attachments lived in the session scratchpad
  and are gone with it.
- **Twelve `screenshots/` folders without READMEs** — deliberately left. (carried)
- **Stale unchecked bullets inside four finished blocks.** (carried)
- **The 107-second failing test** in routine-record block 1's red-check — failure-path only,
  unexplained. (carried)
- **The emulator was left running** (`scripts/emulators.sh`, restarted this session after a
  machine reboot); `firestore-debug.log` in the repo root is the truth for a silently failed
  write.
- **The review-session journal rows** from the swipe-path experiment — E's own data,
  deliberate, nothing to clean up. (carried)
