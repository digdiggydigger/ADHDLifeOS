# START HERE — build `F-CTACelebrations-4` (the nine mini confetti pops)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built `F-CTACelebrations-3`. **The
session that writes this arc's next opener archives this file in the same move.***

**STATUS.** Blocks 1–4 of the arc are MERGED. `F-ConfirmCelebration-2`, `F-CTACelebrations-1` and
`-2` all PASSED E's device verdict. **`F-CTACelebrations-3` (the centre and the shared layer,
PR #90) is merged and INSTALLED on E's phone, and its verdict is OUTSTANDING** — register §A, first
item. The app code is `main` @ `c10813d`. Check `git log --oneline -1 origin/main` for today's tip
rather than trusting a SHA written here.

**If E has not yet given the verdict on `-3`, ask for it before building.** It is a deliberately
NEGATIVE test — nothing new is visible, and "it looks exactly like yesterday" is the pass.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes" (it now has a
   celebrations entry), and **§7** — §7.2's waiver pin changed shape in block 3 and the entry
   explains why.
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-fourth edition) — THE outstanding list. §A holds
   the pending verdict, **a photosensitivity question that is a launch-safety item**, and an
   accessibility announcement owed before `-5`. §B.00 lists **four** things block 3 leaves this
   block.
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: E's **F6**
   (the mini confetti pop, chosen over a halo and tick), **#7** (the still scatter under Reduce
   Motion), **R-e** (the Create Task sheet holds 0.45 s) and §3's list of the nine sites.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-4` under `# ⚠ CLAUDE CODE ADDITIONS`.
5. `screenshots/cta-celebrations-block-3/README.md` — the probe technique, and specifically the
   three traps in "How to rebuild the probe". You will be rendering for E's choice, so read it.

## The block — `F-CTACelebrations-4`

- **RENDER FIRST, WIRE SECOND. E picks the pop by LOOKING** (F6), on a real `TaskRow`, two or three
  count/spread variants, full and still. Send them with `SendUserFile`. Do not wire nine sites to a
  look E has not chosen.
- Then the nine sites, each wrapped in `CelebrationPopSource` with the pop line INSIDE the same
  closure as the site's haptic: `TaskRow` (circle + swipe, ONE origin), `TaskDetailFormSections`
  "Close it", `AreaTaskRow`, Best-next-move "Close it", Sorted (triage + detail), Journal it,
  Create Task (post-success), Done for now, the routine step.
- **This is the FIRST block that owes an RM-on DEVICE pass** (§7.3, E's call 2026-09-12). Ask for
  both passes in ONE message — RM off, then RM on — so E flips the setting once. The "Verified
  paths" line may only say *"Reduced: run on sim (injected) + E's phone (RM on)"* if E actually
  toggled and said so.

## The four things block 3 leaves this block — do not rediscover them

- **`CelebrationPopSource` and `CelebrationRecipes.pop` / `.stillPop` EXIST and nothing calls
  them.** They were built because block 3's file list named them, and they are at 0 % coverage for
  the view wrapper and 100 % for the recipes. **Block 4 is where the reachability guard belongs** —
  `CelebrationPopCallSiteTests`, one prose test per site, plus "the swipe and the circle pop from
  one origin". Tests prove correctness, never REACHABILITY; grep the call sites.
- **The still pop has NO hold at full opacity.** `CelebrationStillField.fadeIn` 0.3 + `fadeOut` 0.7
  = `CelebrationQueue.popLength` 1.0 exactly, so it rises and immediately falls. The
  `apple:hig-reviewer` pass flagged it as probably intentional rather than a typo. **Say so when E
  looks at the render** — "rise then fall, no hold" — so E judges it rather than assuming a bug.
- **A pop's origin is GLOBAL**, recorded by `.celebrationPopOrigin(_:)` and converted into the
  drawing layer's own space by `CelebrationStage`. A `TaskDetail` Form row is drawn by the ROOT
  layer, which is exactly what beats row clipping — do not add a layer to the Form.
- **The centre's ordinal is not a haptic trigger.** It drives SwiftUI identity and the confetti seed
  only; the focus service's own ordinal still drives the Confirm haptic. Keep them apart.
- **The first pop on `TaskSearchSurface` is ALSO a wiring check.** Block 3 proved the layers draw,
  but both its probes injected the environment themselves — nothing has yet shown at runtime that a
  layer inside a `fullScreenCover` inherits the centre from `RootView`. The call-site test pins the
  position of the two `.environment(...)` lines; your pop is the first thing that exercises it.
- **There is a LATENT defect in `CelebrationCenter` waiting for `-5`/`-7`, register §B.00b:** the
  cooldown stamp and the chime hook fire at REQUEST time, before the held branch, and `releaseHeld`
  sets neither. Not yours to fix unless you make it reachable — read the register item before
  touching the centre.

## Harness lessons worth a run each, from blocks 1–3

- **Run the SUITE after a room-first commit, not just lint and the build.** Block 3's room-first
  move passed both and broke two call-site tests that read the file it moved members out of.
- **Prove the render harness is deterministic BEFORE any pixel claim** — one scene rendered twice in
  the same run must come back identical. Then, if two runs differ, measure WHERE and BY HOW MUCH
  before concluding anything: block 3's "109,847 pixels differ" was every one of them off by a
  single 8-bit level, and the decisive control was rendering the *same unchanged code* in another
  process.
- **`TimelineView` draws at the REAL instant.** A burst dated in the future renders an empty canvas,
  and two empty canvases agree with each other — which is how block 3's Reduce Motion comparison
  passed vacuously on its first run. Every "identical" claim needs a control that shows the
  comparison can see a real difference.
- **Guess bounds last.** A control bound written as `> 100_000` failed at 62,996 with the code
  entirely correct.
- **Write the red prediction in TWO parts when the block introduces a symbol.** A test naming a
  symbol that does not exist cannot fail — the target cannot BUILD and the harness prints no count.
- **A call-site guard must be scoped to its CLOSURE, not its file**, and if it is anchored on a
  one-line modifier it will break the moment that modifier gains an argument and rewraps. Block 3
  had to make two such guards read the source flattened.

## Then, strictly in order, one per review

`F-CTACelebrations-5` (inbox zero, streak on 7, daily goal; **room first** —
`CaptureInboxService.swift` is at 397; E's cooldown call; **and the accessibility announcement
register §A owes before the first milestone ships**) → `-6` (the routine Completed flow; render the
congratulation first; reverses leave-ends-run, update the pinning tests by name) → `-7` (the chime;
E picks by ear). Then `F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with the emulator up and 0 `127.0.0.1:9099` hits; the sim build; in-situ renders or a
  probe (removed before commit); the PR; the phone from `main`; E's verdict; the register rewritten
  at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards. **The cooldown constant stays 5 s** (register §A).
- Use the installed skills, MCPs and subagents (E's standing ask, restated 2026-09-12): the TDD
  skill, the `xcode` bridge, a `feature-dev:code-reviewer` pass over the diff before the PR, and an
  `apple:hig-reviewer` pass over any finished user-facing surface — **block 4 HAS one** (nine real
  sites), unlike block 3, so that pass matters more here than it did last time. `SendUserFile` for
  renders.

## Environment notes

- **Open Xcode on the project BEFORE starting the session** or the `xcode` MCP bridge is absent for
  the whole session with no recovery. It was open in block 3's session and the bridge was healthy —
  but `RenderPreview` still returned "The data couldn't be read because it is missing." for both
  preview indices it was asked for, twice. **Do not sink time into it**; the run-loop-pumping probe
  is the sanctioned fallback and is fully documented in
  `screenshots/cta-celebrations-block-3/README.md`.
- **A stale `TestResults.xcresult` fails the suite before a single test runs.** It is gitignored;
  `rm -rf` it as part of the run.
- **The emulator may ALREADY be running from a previous session.** `curl -s 127.0.0.1:4400/emulators`
  tells a live harness from a broken one; E's instruction is to use the running one if you can.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.** None was run in block 3.
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, an iPhone **15** Pro).
  **Its dev profile expires 2026-09-17** — five days from this writing; when an install fails, E
  re-signs in Xcode → Settings → Accounts. Install recipe:
  `xcodebuild build -destination 'platform=iOS,id=<udid>' -allowProvisioningUpdates`, then
  `xcrun devicectl device install app --device <udid> "<…>.app"` and
  `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **Baseline at close** (`2a441db`, merged as `c10813d`): suite 2,810 / 0, lint 0 / 778, app
  coverage 27.42 % (12,949/47,221).
