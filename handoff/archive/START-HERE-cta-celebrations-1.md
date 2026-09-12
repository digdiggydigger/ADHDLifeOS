# START HERE — build `F-CTACelebrations-1` (the haptic tidy and the closure card's spring-in)

*A disposable pointer (CLAUDE.md, "Session handoff"): paste this path into a fresh Claude Code
terminal. Written 2026-09-12 at the close of the session that built block 1 of the CTA celebrations
arc. **The session that writes this arc's next opener archives this file in the same move.***

**STATUS.** The arc's block 1, `F-ConfirmCelebration-2` (the stack-clearing fireworks and the
light-mode dim), is BUILT, MERGED (`9a7b664`, PR #76) and **PASSED E's device verdict** (PR #78).
`main` is `4c6e157` + this opener's PR. E's phone runs `main @ 9a7b664`, which is the same app code.
E's instruction for this session: *"start F-CTACelebrations-1 in a new FRESH Claude Code Terminal"*.
No gate question is owed: E approved the design record and R-a…R-h ("yes") on 2026-09-12, recorded
in the record and the register.

## Read first, in this order

1. CLAUDE.md's start-of-session checklist: `claudecode.md`, "Architecture notes", and **§7** (the
   iOS 16 floor; §7.2 Reduce Motion — this block's spring-in is the FIRST new site of the arc, and it
   FADES under Reduce Motion by parameter, the `Capture/CaptureFanOverlay.swift:89-97` house pattern).
2. **`handoff/OPEN-ITEMS-REGISTER.md`** (thirty-first edition) — THE outstanding list. §B.00 is the
   arc; §A holds the cooldown decision (5 s, untouched until `F-CTACelebrations-5`).
3. **`handoff/SESSION-OPENER-cta-celebrations-design.md`** — the design. For THIS block: "Haptic
   only" under "What that adds up to", #8 in the answers table, and "The closure card's spring-in"
   in §3 of the design.
4. `TODO-CLAUDE-CODE.md` — the block `F-CTACelebrations-1` under `# ⚠ CLAUDE CODE ADDITIONS`
   (after the two ticked `F-ConfirmCelebration-2` entries).
5. `screenshots/confirm-celebration-block-2/README.md` — the render-probe technique and the two
   lessons below, as evidence.

## The block — `F-CTACelebrations-1`

- **Room first, own commit.** `Home/HomeView.swift` and `Home/HomeMomentumSections.swift` are BOTH
  at 399 of 400 lines. Move methods out — `HomeView.swift:360-399` → `Home/HomeView+Refresh.swift`,
  `HomeMomentumSections.swift:235-329` → `Home/HomeLifeAreasSections.swift` — stored `@State`/
  `@StateObject` properties cannot move; only methods and computed views can. Suite green, lint 0,
  commit, THEN the block.
- **The four haptic tidies (E: "Tidy all four")**, each a one-line change through
  `Theme/Haptics.swift`. Line numbers as of `4c6e157`; re-read before editing:
  - Sorted on the capture DETAIL screen: `Capture/CaptureDetailComponents.swift:287`
    `Haptics.play(.solid)` → `.success` (the triage screen already plays `.success`,
    `CaptureInboxSections.swift:147/156`).
  - "Done for now": `Nudges/NudgeDueCard.swift:35` `Haptics.play(.light)` → `.success`.
  - Save a place: `Places/PlaceEditorView.swift` `save()` (line ~275) — `.solid` AFTER the write
    lands. There is a `Haptics.play(.solid)` at line 197 already; read what it is on before adding
    a second.
  - Stop sprint: `Focus/FocusTimerBar.swift` — the Stop action gets `.light`. The `.light` at line
    178 is the expand/collapse feel, NOT the stop; find the stop's closure.
- **The closure card springs in** (`Home/HomeMomentumSections.swift:15-36`, `ClosureCelebrationCard`
  at line 22): `.transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))`
  on the card, and `withAnimation(reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8))`
  around the THREE writers of `celebratedTask` (line 35 `onNext`, line 218 in `closeTask`, line 228
  in `undoClose`). Opening-pose rule (§7.2): under Reduce Motion the first frame is at final
  geometry and only opacity travels.
- **Tests:** `CTAHapticTidyCallSiteTests` — five prose tests reading the four sites and the
  spring-in, both Reduce Motion branches BY STRING (the `.opacity` fade AND the spring), loud
  call-site guards (the `ConfirmCelebrationCallSiteTests.appCode` shape). Written red prediction:
  5 / 5. Red-check on the committed tree.
- **Evidence:** `screenshots/cta-celebrations-block-1/` with README — the card at ~0.1 s, full
  beside reduced (a render probe with Reduce Motion as a PARAMETER, one render per mode), light and
  dark. **Device verdict by feel**: E taps Sorted on a capture's detail screen, Done for now, saves a
  place, stops a sprint, and closes a task from Home's best-next-move.

## Two lessons from block 1 that will save this session a run

- **A render probe that drives the app on the real clock must be a SYNCHRONOUS XCTest method.** An
  `async` test runs inside a main-queue block, so a nested `RunLoop.main.run(until:)` cannot drain
  the main queue and a `Task { await … }` never runs; the frames show nothing happening. Pump ~1.0 s
  before a reference capture so the tab bar's selection spring settles.
- **"Pixel-identical to the previous block" is rendered from a `git worktree` at the previous
  merge**, not from this tree with the feature off. A diff against your own tree proves only that
  the gate is closed.

## Then, strictly in order, one per review

`F-CTACelebrations-2` (the two switches; Celebrations live on Confirm) → `-3` (`CelebrationCenter`
+ `CelebrationLayer` per surface; the shared frame now has to carry the fireworks and the dim too —
`ConfirmCelebrationScene.fireworks`, `ConfirmCelebrationDim`, `ConfirmFireworksDrawing`; the waiver
pin lists SIX Confirm files) → `-4` (the nine pops; render on a real `TaskRow` FIRST, E picks) →
`-5` (inbox zero, streak on 7, daily goal; E's cooldown call) → `-6` (the routine Completed flow;
render the congratulation first; reverses leave-ends-run, update the pinning tests by name) →
`-7` (the chime; E picks by ear). Then `F-FocusCard-Corners`.

## How to run each block

- Test-first with a written red prediction; red-checks on a committed tree; `swiftlint lint` 0; the
  full suite with `./scripts/emulators.sh` up and 0 `127.0.0.1:9099` hits; the sim build; in-situ
  renders or a probe (removed before commit); the PR; the phone from `main`; E's verdict; the
  register rewritten at close-out. Every report carries a Verified-paths line (§7.3).
- Tokens only (§4), the 4/8/16/24 grid (§2), haptics through `Theme/Haptics.swift`, prose test
  names, loud call-site guards. **The cooldown constant stays 5 s** (register §A).
- Use the installed skills, MCPs and subagents (E's standing ask, 2026-09-11): the TDD skill, the
  `xcode` bridge's `RenderPreview` for stills, a `feature-dev:code-reviewer` pass over the diff
  before the PR, `SendUserFile` for renders.

## Environment notes

- **Open Xcode on the project BEFORE starting the session**, or the `xcode` MCP bridge is absent all
  session (it was UP on 2026-09-12).
- Start the emulator (`./scripts/emulators.sh`) before the suite; it is NOT left running.
- **Test simulator:** iPhone 17 Pro `9181EBF9-0F54-4A4D-A19C-19945D1BF155` (iOS 26.5, the only
  runtime). **A UI-target run poisons it — erase before the next unit run.**
- **E's phone:** `3DBC979A-3255-5456-8C30-172DB19B99B3` (`wishwashwacky15`, paired and available on
  2026-09-12). **Its dev profile expires 2026-09-17**; when an install fails, E re-signs in Xcode →
  Settings → Accounts. Install recipe: `xcodebuild build -destination 'platform=iOS,id=<udid>'
  -allowProvisioningUpdates`, then `xcrun devicectl device install app --device <udid> "<…>.app"`
  and `… process launch --device <udid> --terminate-existing com.ethananthony.ADHD-LifeOS`.
- **A stray untracked `AGENTS.md`** (a Codex copy of CLAUDE.md) sits in the repo root. E,
  2026-09-12: *"ignore the codex copy files for now."* Never `git add -A`; add paths explicitly.
- **Baseline at close** (`29c6267`): suite 2,741 / 0, lint 0 / 757, app coverage 27.07 %
  (12,635/46,678).
