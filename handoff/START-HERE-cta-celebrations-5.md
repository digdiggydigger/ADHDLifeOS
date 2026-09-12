# START HERE — build `F-CTACelebrations-5` (inbox zero, the streak on 7, the daily goal)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built `F-CTACelebrations-4`. **The
session that writes this arc's next opener archives this file in the same move.***

**STATUS.** Blocks 1–5 of the arc are MERGED. Blocks 1–4's verdicts all PASSED.

**`-4`'s device verdict is DEFERRED, not missing, and that is E's own call** (2026-09-12, verbatim:
*"I will push the device passes off until after the next block."*). E was asked for both passes —
Reduce Motion OFF then ON — at the close of `-4`, and chose to do them after THIS block instead.
**Do not re-ask at the start of this session, and do not treat `-4` as unverified work to redo.**
The app is installed on the phone from `main` and `-4` is landed and green.

**What that means for this block, and it is the operative consequence:** `-5` adds reduced sites of
its own (the still confetti field under Reduce Motion), so when E does sit down with the phone they
will be judging **both blocks at once**. Ask for the two passes at the close of this block covering
`-4`'s nine pops AND `-5`'s milestones together, in ONE message, and say which sites belong to which
block so a failure can be attributed. Until E answers, BOTH blocks' Verified-paths lines read
*"Reduced: run on sim (injected); NOT on device."*

The app code is `main` @ `5d472cb`; check `git log --oneline -1 origin/main` for today's tip rather
than trusting a SHA written here.

**E's standing instruction: each block is built in a FRESH Claude Code terminal session.** This
file is how that session starts.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes" (it has a
   celebrations entry), and **§7** — especially **§7.3's RM-on device pass**, which `-4` was the
   first block to owe and which this block owes too if it adds or changes a reduced site (it does:
   the still field under Reduce Motion).
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-fifth edition) — THE outstanding list. §A holds
   `-4`'s pending verdict, **the accessibility announcement this block must decide**, E's cooldown
   call, and a new question about whether the Celebrations switch should gate pops. §B.00 lists
   five things `-4` leaves this block; **§B.00b becomes REACHABLE in this block**.
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: **§3's
   triggers** (inbox zero, the streak, the daily goal), **F3/F7/F8**, and **R-a** (a discard never
   counts), **R-b** (exactly 7), **R-c** (Confirm stamps the cooldown), **R-d** (the centre plays
   `.success` for the daily goal), **R-g** (held bursts drop at 60 s), **R-h** (a downgraded
   milestone gets the fallback pop where the site had none).
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-5` under `# ⚠ CLAUDE CODE ADDITIONS`.
5. `screenshots/cta-celebrations-block-4/README.md` — the probe technique, and the two traps in
   "How to rebuild the probes". You will be rendering a milestone over the empty inbox.

## The block — `F-CTACelebrations-5`

Three of E's four full-screen milestones (the fourth, a routine completed, is `-6`). Each is the
every-Confirm celebration: the done-green glow, 120 rain + 100 cannon confetti, 5.4 s, plus the
site's own haptic.

- **Room first, its own commit.** `CaptureInboxService.swift` is at **397** of SwiftLint's 400. The
  design names the move: `:266-310` → `CaptureInboxService+Notes.swift`. **Run the full SUITE after
  it, not just lint and the build** — `-3` and `-4` both proved a room-first move can pass both and
  still break a call-site test that reads the file it emptied. Read the tests that name the file
  BEFORE moving anything; that is how `-4` caught its one.
- **Inbox zero** — a new `CaptureInboxService+Celebrations.swift`, after `removeCapture(id:)` in
  `sort`, `logToJournal` and `promoteToTask`. Not `discard` (R-a). The Home and Journal capture
  doors build a service with no list, so there the answer is one fetch.
- **The streak on 7** — `NudgesService.dismiss` after `replace(updated)`, via a new pure
  `NudgeStreak.landsOnSeven(before:after:asOf:)`. Exactly 7 (R-b).
- **The daily goal** — `HomeView`: `ringCount`, `ringSettled`, `DailyGoalTracker`, and a per-ACCOUNT
  day marker (a per-device key would let a second account inherit the first's "already celebrated
  today"). The centre plays `.success` for this one, because no site does (R-d).
- Both services take `celebrate:` as a defaulted `init` parameter from their hosts, so a service
  test injects a recording fake.

## The five things `-4` leaves this block — do not rediscover them

- **§B.00b's latent defect becomes REACHABLE here, and this block is where it should be fixed.**
  `CelebrationCenter.request(_:at:)` stamps `lastFullScreenAt` and fires the `chime` hook when the
  outcome is `.fullScreen` — **before** the held branch — and `releaseHeld()` sets neither. Inbox
  zero via the Create Task path is exactly the held case, so from this block on: a held burst
  stamps the cooldown before it plays, and a held burst dropped at 60 s stamps a cooldown for a
  celebration nobody saw, which can silence a real milestone after it. Move the stamp and the chime
  to the moment a burst actually STARTS, so a held release and a direct enqueue go through one
  place. **`CelebrationCenterTests` has no test of held-burst stamp or chime timing** — closing that
  gap is part of the fix.
  **And note the new interaction:** `-4` added `CapturePromoteSheet.popHold = 0.45`, so the sheet
  now lingers 0.45 s after a successful promote before dismissing. A held inbox-zero burst is
  therefore released 0.45 s after the pop the same tap threw, not immediately. Read the held path
  with that timing in mind.
- **The accessibility announcement (register §A) is owed BEFORE the first milestone ships.** A
  full-screen celebration is `accessibilityHidden`, which `-4`'s HIG pass confirmed is right for all
  nine of its sites — each has a haptic and a real on-screen change. It is NOT right for a milestone
  whose site has neither, and R-h names the ring and the Completed button as exactly those. The
  house precedent is `TaskDetailFormSections.swift`'s
  `UIAccessibility.post(notification: .announcement, …)`, queued behind what VoiceOver is already
  reading. Decide it with E, do not ship silently either way.
- **Do NOT "correct" `-4`'s two deviations.** `TaskRow` uses `.celebrationPopOrigin` + `@State` +
  a request in its shared `close()`, **not** `CelebrationPopSource` — its circle and its swipe share
  one `close()`, and the wrapper would move the origin to the middle of the row instead of the
  circle E approved by looking. `CreateTaskButton` pops **after** the await, inside `if succeeded`,
  because a create can fail. Both are pinned by name in `CelebrationPopCallSiteTests`.
- **The cooldown stays 5 s** (register §A). E is undecided and will rule on the phone after this
  block. Do not change it, and do not remove it.
- **`CelebrationPopCallSiteTests` counts.** It asserts the app wraps exactly **9** controls in
  `CelebrationPopSource` and records exactly **2** pop origins by hand. R-h's fallback pop at the
  ring and at the Completed button will move those numbers — update the counts and their messages
  deliberately, in the same commit, rather than treating a red count as noise.

## Harness lessons worth a run each, from blocks 1–4

- **A wrong RED PREDICTION may be a defect in the guards, not a bad forecast.** `-4` predicted 17
  assertion failures and got 20; the three extra were guards that anchored on
  `Button { Haptics.play(…)` and then asserted the haptic was inside the slice — which starts AFTER
  its anchor, so they could never have gone green. Investigate a miss before accepting it.
- **A review pass over the diff sees what the suite cannot.** `-4`'s one real defect was a 0.45 s
  window in which an already-succeeded sheet stayed interactive; no assertion in 2,824 tests could
  have seen it, and `feature-dev:code-reviewer` did. Run it before the PR.
- **Check how a site is PRESENTED before trusting its celebration will be seen.** The per-surface
  architecture fails silently. `-4` traced all ten sites to their presenters before the PR; every
  detail screen turned out to be a `navigationDestination` push. Thirty seconds.
- **Prove the render harness deterministic BEFORE any pixel claim**, and give every "identical"
  claim a control that shows the comparison can see a real difference. `TimelineView` draws at the
  REAL instant, so a burst dated in the future renders an empty canvas — and two empty canvases
  agree with each other.
- **To render the real feature and not a picture of its drawing, let the handle escape the
  wrapper's body**: `CelebrationPopSource { handle in … .onAppear { box.handle = handle } }`.
- **Guess bounds last.** A control bound written as `> 100_000` failed at 62,996 with the code
  entirely correct.
- **A `minHeight`-flexible row eats the whole screen in a probe.** `.fixedSize(horizontal: false,
  vertical: true)` on the card.

## Then, strictly in order, one per review

`F-CTACelebrations-6` (the routine Completed flow; render the congratulation first; it REVERSES
leave-ends-run, so update the pinning tests by name) → `-7` (the chime; E picks by ear). Then
`F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with the emulator up and 0 `127.0.0.1:9099` hits; the sim build; in-situ renders or a
  probe (removed before commit); the PR; the phone from `main`; E's verdict; the register rewritten
  at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards.
- Use the installed skills, MCPs and subagents (E's standing ask): the TDD skill, a
  `feature-dev:code-reviewer` pass over the diff before the PR, and an `apple:hig-reviewer` pass
  over any finished user-facing surface. `SendUserFile` for renders.
- **Ask for both device passes in ONE message** (Reduce Motion off, then on) so E flips the setting
  once. The "Verified paths" line may only say *"Reduced: run on sim (injected) + E's phone (RM
  on)"* if E actually toggled and said so.

## Environment notes

- **Open Xcode on the project BEFORE starting the session** or the `xcode` MCP bridge is absent for
  the whole session with no recovery. `RenderPreview` has now failed on this project twice; **do not
  sink time into it** — the run-loop-pumping probe is the sanctioned fallback and is documented in
  `screenshots/cta-celebrations-block-4/README.md`.
- **A stale `TestResults.xcresult` fails the suite before a single test runs.** It is gitignored;
  `rm -rf` it as part of the run. It was present at the start of the last two sessions.
- **The emulator may ALREADY be running from a previous session.** `curl -s 127.0.0.1:4400/emulators`
  tells a live harness from a broken one; E's instruction is to use the running one if you can.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.** None was run in `-4`.
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro).
  **Its dev profile expires 2026-09-17**; when an install fails, E re-signs in Xcode → Settings →
  Accounts. Install recipe:
  `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **Baseline at close** (`050e3b4`, merged as `1b80cee`): suite 2,824 / 0, lint 0 / 780, app
  coverage 27.29 % (12,949/47,457).
