# Start here — `F-ModernIOS-2-Celebration` (block 2 of the modern-iOS pilot)

> **STATUS 2026-09-11: BLOCK 2 IS BUILT AND LANDED — DO NOT BUILD IT AGAIN.** It merged to `main`
> (see `handoff/OPEN-ITEMS-REGISTER.md`, twenty-fourth edition, for the PR and SHA) and is waiting
> on E's two device verdicts: Reduce Motion ON (closes the block), then OFF. Everything below is the
> specification it was built from. This opener stays live only until those verdicts are in; the
> session that records them archives it with its successor.

> **E, before you launch the session:**
> - **Open Xcode on `ADHD LifeOS.xcodeproj` FIRST**, so the `xcode` MCP bridge connects. It was
>   absent for all of block 1's session because Xcode was closed.
> - **Keep the phone to hand.** This block closes on a device verdict with Reduce Motion ON,
>   followed by a second look with it OFF.

*Paste into a fresh Claude Code terminal. Written 2026-09-11 at the close of the session that
landed block 1 (`F-ModernIOS-1-Policy`, PR #63). It succeeds
`handoff/START-HERE-modern-ios-pilot.md`, now in `handoff/archive/`. The approved plan's block-2
sections are carried below verbatim, so nothing needs reading from the archive.*

**This is the ONE live opener.** If `handoff/` holds a second `START-HERE-*`, one of them is a trap.
Archive this file into `handoff/archive/` in the same move that writes your successor, at the END
of your session and never at the start.

---

## Where things stand

- **`main` is @ the merge of this handoff.** Block 1 is `0e980e5`, merged at `c2cb3a8`. The last
  APP-code change is still `d8b334b` (`F-FocusCard-4`). No branch is in flight, and `main` is the
  only branch on GitHub.
- **E answered block 1's report by asking for this opener** (2026-09-11). That is the go-ahead to
  cut block 2. No change to §7 was requested.
- **Figures, carried from block 1's run:**
  - unit suite **2,663 / 0** (emulator UP, 0 `127.0.0.1:9099`, 0 skipped)
  - SwiftLint **0 / 739**
  - sim `** BUILD SUCCEEDED **`
  - app target **26.68% (12,255/45,932)**

  Your first suite run must count 2,663 before you add anything.
- **E's phone** is an iPhone 15 Pro (`3DBC979A-3255-5456-8C30-172DB19B99B3`, paired and available on
  2026-09-11), on iOS 26, running `d8b334b`'s app code.
  - **Reduce Motion ON, and Prefer Cross-Fade Transitions ON.**
  - The provisioning profile is valid to **2026-09-17**.
- **Why this block exists:** every Reduce Motion gate in the bottom furniture is
  `reduceMotion ? nil : …`. So F-FocusCard-4's celebration opens settled under RM and has never
  once played on E's phone; E saw a hard cut plus the haptic. E is the target user and runs with RM
  on.
- **The policy this block pilots is now in force, not just planned.** CLAUDE.md §7.1–7.5 landed in
  block 1, and this celebration becomes §7.1's second two-branch exemplar. **Three report lines are
  mandatory:**
  - §7.3's **"Verified paths"** line, in the block report AND the screenshots README;
  - §7.1's **why there is no 17 tier**;
  - §7.5's **skill conflicts**, or "no design skill was run".
- **`ModernAPIPolicyCallSiteTests` exists** (block 1) and pins `View.haptic(_:trigger:)`. This block
  does not touch `Theme/Haptics.swift`.
- **Two things E owns, neither blocking you:**
  - **An older simulator runtime.** If the state gate shows one, E installed it and §7.3's line
    changes: run the fallback ON that OS and say so.
  - **The widget's `MARKETING_VERSION`** (1.0, against the app's 1.3). Xcode warns on every build.
    Leave it; version numbers are E's.

## Your job

**One block, `F-ModernIOS-2-Celebration`, built test-first on `feature/modern-ios-celebration`, as
one PR.** Then STOP for E's device verdict:
- **RM ON is the verdict that closes the block.** RM OFF is a second look.
- **Ask for the two verdicts separately.**
- **E switches Reduce Motion themself** (Settings → Accessibility → Motion). The only precedent for
  looking at E's phone settings through iPhone Mirroring is a READ-ONLY one.

The specification is the plan below. **Read the two corrections first.** Both were found by checking
the plan against the tree while writing this opener, and one of them is a compile error.

## Two corrections to the plan — verified 2026-09-11 against `main` @ `c2cb3a8` (app code = `d8b334b`)

### 1. The plan's `.modern` tick expression does not compile

The plan writes `tick.transition(.asymmetric(insertion: .symbolEffect(.drawOn), removal: .identity))`.
In the 26.5 SDK, `asymmetric(insertion:removal:)` exists ONLY on `AnyTransition`. SwiftUI's
`symbolEffect(_:options:)` transition, by contrast, is declared on
`extension Transition where Self == SymbolEffectTransition`: a `Transition`-protocol (iOS 17) type,
not an `AnyTransition`.

A `swiftc -typecheck` probe settled it. It ran at `-target arm64-apple-ios16.0-simulator`, with the
tick inside an `@available(iOS 26.0, *)` struct hosted by `if #available(iOS 26.0, *) { … } else { … }`:

| form | result |
|---|---|
| `.transition(.asymmetric(insertion: .symbolEffect(.drawOn), removal: .identity))` (the plan) | **exit 1**: `type 'AnyTransition' has no member 'symbolEffect'` |
| `.transition(AsymmetricTransition(insertion: .symbolEffect(.drawOn), removal: .identity))` | exit 0 |
| `.transition(.asymmetric(insertion: AnyTransition(.symbolEffect(.drawOn)), removal: .identity))` | exit 0 |

**Use the `AsymmetricTransition(insertion:removal:)` form.** It stays in the `Transition` world with
no type erasure. The design is unchanged:
- it is still the transition form;
- it is still insertion-only;
- it is still driven by `withAnimation(checkmarkAnimation)`;
- the call-site string `.symbolEffect(.drawOn` still matches.

Also verified: `DrawOnSymbolEffect` is `@available(iOS 26.0, *)` and conforms to
`TransitionSymbolEffect` (`Symbols.swiftinterface`).

**Still unverified** is the plan's own risk: whether the draw-on runs on the spring's timing (and
honours its 0.3s delay) or on its own. Evidence it in the render rather than fighting it.

### 2. The red prediction is 5 failures, not 6, for the assertion set as listed

Checked against `FocusCompletionCelebration.swift` with comment lines stripped, which is what
`appCode` reads:
- **`testTheCelebrationCarriesBothTheModernAndTheFloorBranch` → 2.** Neither
  `#available(iOS 26.0, *) {` nor `} else {` appears anywhere in the file's code today.
- **`testTheDrawOnTickSitsBehindTheGateInItsOwnAvailableType` → 2.**
- **`testTheFloorPathIsStillTheTwoBeatBurst` → 1.** Two of its three forms are ALREADY present:
  `withAnimation(FocusCompletionCelebrationMetrics.burstAnimation)` (line 76) and
  `.scaleEffect(pose.checkmarkScale)` (line 68). Only `checkmarkAnimation(for: motion)` fails.

The count is 6 only if that third test also asserts that the old
`withAnimation(FocusCompletionCelebrationMetrics.checkmarkAnimation) {` is GONE. That is a sound pin,
because it proves the floor's tick now goes through the mode.

**Decide the assertion set, then write the prediction down before running.** Predict in TESTS (3)
and reconcile the assertion count afterwards. The suite prediction is unaffected: **2,663 → 2,672**
(6 pure + 3 string).

## Read these, in this order

1. This file, to the end.
2. `handoff/OPEN-ITEMS-REGISTER.md` — twenty-third edition, THE outstanding list.
3. `CLAUDE.md`:
   - **§7 in full** (7.1–7.5, rewritten by block 1; this block is its pilot);
   - then Workflow, Version Control (`main` is protected), Session handoff, Visual evidence, and
     UI/UX §1–§6.
4. `claudecode.md` — the TDD role definition.
5. `handoff/SESSION-OPENER-focus-card-design.md` — its POSTSCRIPT table, then block 4's section.
   Never edit the body; this block adds one postscript row.
6. `screenshots/focus-completion-celebration/README.md` — what block 4's render settled, the render
   technique you reuse, and the frames `.full` must match.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current                                         # expect main
git status --short                                                # must be empty
git log --oneline -1; git log --oneline -1 origin/main            # the same SHA
git log --oneline origin/main | grep -c "F-ModernIOS-1-Policy"    # ≥ 1: block 1 is on main
xcrun simctl list runtimes                                        # only iOS 26.5? §7.3 compile-only stands
lsof -iTCP:9099 -sTCP:LISTEN                                      # emulator up? else ./scripts/emulators.sh
wc -l "ADHD LifeOS/Focus/FocusCompletionCelebration.swift" \
      "ADHD LifeOS/Focus/FocusSessionService.swift"               # 190 and 394 at this writing
```

Check whether the `xcode` MCP tools loaded (`ToolSearch` for "xcode"). If they did not, say so in
your first message and carry on: pasted `xcodebuild` output is the bar either way, and a bridge
result is only a hint to confirm.

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

The DerivedData folder above is the one block 1's builds wrote to (re-checked 2026-09-11).
- **The profile is valid to 2026-09-17.**
- **A launch denied with `Security` / "invalid code signature… not explicitly trusted"** right after
  a re-issued profile is TRANSIENT: retry once.
- **A locked phone refuses the LAUNCH but not the install.**
- **An empty Xcode account list** means E must sign in via Xcode → Settings → Accounts, never
  Claude Code.

## What "done" means for this block

- **Commit before every red-check.** Restore with `git checkout -- "ADHD LifeOS/"` and prove the
  restore by rebuilding. Never `&&` a commit onto a piped build.
- **Probes are deleted before the block's commit:** `ZZFocusCelebrationRenderProbe.swift` and any
  in-situ probe.
- **`git diff --stat main` shows NO change** to `FocusCompletionCard.swift`,
  `FocusCompletionCardStack.swift`, `RootBottomOverlay.swift`, `FocusSessionService*.swift` or
  `Theme/Haptics.swift`.
- **The paperwork:**
  - TODO `[x] COMPLETED`;
  - the register rewritten as its twenty-fourth edition;
  - the design record's one postscript row;
  - `screenshots/focus-completion-celebration-modes/` with its README;
  - PR → merge → the four-line close-out pasted;
  - the phone installed from `main` and launch-verified.

  Per CLAUDE.md the block lands BEFORE E's review. The `40-`/`50-` device frames arrive with E's
  verdicts, so land them in a follow-up evidence PR if the block has merged by then.
- **The report carries:**
  - pasted lint / suite / build output, with each red-check's predicted and actual counts;
  - the Verified paths line;
  - why there is no 17 tier;
  - skill conflicts;
  - the reduced halo pinned at 1.6, flagged as E's lever;
  - how both corrections above resolved.
- **Then STOP** for E's two verdicts.

---

# The approved plan (E, 2026-09-11) — block 2's sections, verbatim

*Carried unedited from the archived opener. Block 0 (the handoff) and Block 1 (the §7 policy) are
omitted because both shipped. The two corrections above take precedence where they touch this
text.*

## Context

**What prompted it.** After F-FocusCard-4 shipped, E reported "I can't see any of the animations"
on their iPhone. Systematic debugging (2026-09-11): the celebration renders correctly in the
simulator, in isolation and in situ through the real `RootBottomOverlay` + `FocusSessionService`
(frames: empty ring while the card lands, tick + halo at ~0.7s, settled by 1.8s). A read-only look
at E's phone via iPhone Mirroring found **Reduce Motion ON** (and Prefer Cross-Fade Transitions).
Every animation in the bottom furniture is `reduceMotion ? nil : …`, and the celebration opens on
its settled pose under RM — exactly what the design record specified. **So the block-4 burst has
never once played on E's phone; E saw a hard cut plus the haptic.** Not a code defect: a product
gap. Apple's guidance under RM is to replace motion with fades, not to remove feedback. E is the
target user and runs with RM on.

**The larger direction E gave in the same session:** keep the iOS 16.0 floor, but give users on
recent iOS (the majority) the modern experience — progressive enhancement behind `#available`.
CLAUDE.md §7 currently says the opposite (it bans `PhaseAnimator` / `.symbolEffect` /
`.keyframeAnimator` / `.sensoryFeedback` outright), and a call-site test enforces the ban.

**E's decisions (2026-09-11) — settled, do not re-litigate:**
1. Under Reduce Motion the celebration becomes a **cross-fade**: tick fades in, halo fades out,
   nothing scales or moves; haptic unchanged.
2. Progressive enhancement across **every tier that adds value** (17, 18, 26) above the 16.0 floor.
3. Fallback proof: **compile-only for now, clearly documented in CLAUDE.md**; prompt E at a
   natural break to install an older simulator runtime (record as an open item).
4. Rollout: **policy first (CLAUDE.md §7 rewrite), then the celebration as the pilot block.**
5. **A fresh Claude Code session does the building.** This session lands the handoff docs only.
6. The celebration tick's ladder is **16 spring / RM cross-fade / 26 draw-on — no separate 17
   tier** (the 17 symbol effects add nothing the spring lacks for this glyph; E confirmed).

**Outcome.** A written, test-enforced progressive-enhancement policy; the celebration visible to E
on their own phone under RM as a fade; on iOS 26 the tick draws itself on with today's code as the
16 path — the worked example of the policy.

## What the read-only exploration established

- **57 animation sites in the app (widget: zero); 20 RM-guarded; 19 of those are `nil` → instant
  swap.** The single fade precedent is `ADHD LifeOS/Capture/CaptureFanOverlay.swift:89-96`:
  geometry pinned to final via `appeared || reduceMotion`, opacity free, animation `.default`.
  That is the house pattern the policy names.
- **Celebration under RM:** `FocusCompletionCelebrationPose.opening(plays:reduceMotion:)`
  (`Focus/FocusCompletionCelebration.swift:105-107`) → `.settled`; `onAppear` guards
  `pose == .armed`. Blockers for a fade: `burstScale`/`burstOpacity` share `burstProgress`;
  `checkmarkScale`/`checkmarkOpacity` share `checkmarkLanded`.
- **The haptic fires under RM** — nothing in `Theme/Haptics.swift` or `Settings/AppFeedback.swift`
  consults it.
- **Existing modern/fallback exemplar:** `View.haptic(_:trigger:)` (`Theme/Haptics.swift:112-127`).
  Every other `#available(iOS 17)` in the tree is a wholesale-absent feature (Places, routine
  screen) — an `if` with no `else`. §7 must distinguish *absent* from *degraded*.
- **Toolchain:** Xcode 26.6, the only SDK/runtime is iOS 26.5; app 16.0 / widget 16.1 / Swift 5;
  `CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE`. Every 17-gate is load-bearing and never
  exercised locally.
- **SDK facts (read from the 26.5 swiftinterfaces):** `.symbolEffect(.bounce, value:)` and
  `.transition(.symbolEffect(.appear))` are 17; **`.drawOn`/`.drawOff` are `@available(iOS 26.0)`**
  and compile against this SDK. `SymbolEffectOptions` has no Reduce-Motion option — symbol effects
  do not self-gate on RM.
- **Tests pinning today's behaviour** (`ADHD LifeOSTests/FocusCompletionCelebrationTests.swift`):
  `testReduceMotionOpensOnTheFinalState` (must flip), `testAPoseReadsItsRingOffTheCurve`
  (memberwise init — new stored property needs a default). Call-site
  (`FocusCompletionCelebrationCallSiteTests.swift`): `testTheCelebrationUsesNothingAboveTheiOS16Floor`
  (the ban; deleted in block 1), `testReduceMotionIsResolvedBeforeTheCelebrationIsBuilt` (string
  `reduceMotion: reduceMotion` in the card — must survive).
- `FocusSessionService.swift` is 394/400 lines; **no service change is needed** — the
  celebration's inputs (`celebratingCompletionID`, `confirmableCompletionCount`) already exist.
- `handoff/archive/` has no `START-HERE-post-focus-card*`, so a plain `git mv` works.

## Block 2 — `F-ModernIOS-2-Celebration` (fresh session, TDD; branch `feature/modern-ios-celebration`)

**The three motion modes:**

| mode | when | tick | halo |
|---|---|---|---|
| `.full` | not RM, OS < 26 — **the 16 path, unchanged** | scale 0.6→1 + opacity 0→1 on `spring(0.4, 0.6).delay(0.3)` | scale 1→1.6, opacity 0.8→0 on `easeOut(0.9).delay(0.3)` |
| `.reduced` | RM on, any OS | geometry pinned at 1; opacity 0→1 on `easeOut(0.4).delay(0.3)` | geometry pinned at **1.6**; opacity 0.8→0 on today's `burstAnimation` |
| `.modern` | not RM, iOS 26+ | `if landed { tick.transition(.asymmetric(insertion: .symbolEffect(.drawOn), removal: .identity)) }` driven by the same `withAnimation(checkmarkAnimation)` | same as `.full` |

Why: `.drawOn` (26) is the celebratory idiom the system now uses and E's phone can show it; a 16
spring cannot do it. **No 17 tier for the tick** — `.appear` is a scale-in without overshoot (less
than the spring), and `.bounce` fires at the state change with no delay; neither passes the
adds-value filter (say so in the report). Halo stays on `withAnimation` in every tier
(`PhaseAnimator(trigger:)` cycles back to phase one — wrong for a one-shot; `keyframeAnimator` gains
nothing visible). Reduced halo pinned at 1.6 not 1, because at 1 it is coincident with the ring and
fades nothing (block-4 frame `00`) — flag as E's lever. Metrics numbers and the 0.3s land delay are
unchanged in every mode. Transition form (not the indefinite `isActive` form) so the delay is
honoured by the transaction; insertion-only so Confirm / `.id(celebrates)` rebuilds never draw off.

**Pure types → NEW `ADHD LifeOS/Focus/FocusCompletionCelebrationPose.swift`** (move
`FocusCompletionCelebrationPose` and `FocusCompletionCelebrationMetrics` here, add):
- `enum FocusCompletionCelebrationMotion: CaseIterable, Equatable { case full, reduced, modern;
  static func resolve(reduceMotion: Bool, drawOnAvailable: Bool) -> Self }` — RM wins
  unconditionally, then `drawOnAvailable ? .modern : .full`.
- `Pose` gains `var geometryPinned = false` (default keeps the memberwise init compiling),
  `static let armedInPlace` (progress 0, not landed, pinned), `var isArmed: Bool` (replaces the
  `== .armed` guard), and `opening(plays:motion:)` replacing `opening(plays:reduceMotion:)`: not
  playing → `.settled`; `.reduced` → `.armedInPlace`; else `.armed`. Derived:
  `burstScale = geometryPinned ? burstScaleEnd : curve`;
  `checkmarkScale = geometryPinned || landed ? 1 : checkmarkScaleStart`; opacities unchanged.
- `Metrics` gains `checkmarkFadeDuration: TimeInterval = 0.4` and
  `static func checkmarkAnimation(for:) -> Animation` (`.reduced` → `.easeOut(0.4).delay(delay)`,
  else the spring). `Animation` is `Equatable`, so it is assertable.

**The view (`Focus/FocusCompletionCelebration.swift` — keep the name; call-site tests read it by path):**
- `init(plays:reduceMotion:)` **keeps its signature** (card untouched, string pin survives) and
  delegates to an internal `init(plays:motion:)` used by tests and the probe. Resolution via
  `resolve(reduceMotion:, drawOnAvailable: Self.drawOnAvailable)` where `drawOnAvailable` is the
  `placesSupported` shape (`if #available(iOS 26.0, *) { true } else { false }`).
- Tick as a `@ViewBuilder`: `if motion == .modern, #available(iOS 26.0, *) {
  FocusCompletionDrawOnTick(landed:) } else { today's Image .scaleEffect(pose.checkmarkScale)
  .opacity(pose.checkmarkOpacity) }`. `@available(iOS 26.0, *) private struct FocusCompletionDrawOnTick`
  at the bottom of the same file (~20 lines).
- `onAppear`: `guard pose.isArmed`; `withAnimation(Metrics.burstAnimation) { burstProgress = 1 }`;
  `withAnimation(Metrics.checkmarkAnimation(for: motion)) { checkmarkLanded = true }`.
- Header rewritten (floor is a floor; the ladder; why no 17; RM resolved by the caller). Previews
  gain `.reduced` and `.full` pairs via `init(plays:motion:)`. Sizes after the split ≈ 200 + 150
  lines, no type near 250. `.id(celebrates)` unchanged.
- **No change** to `FocusCompletionCard.swift`, `FocusCompletionCardStack.swift`,
  `RootBottomOverlay.swift`, `FocusSessionService*.swift` — confirm with `git diff --stat`.

**Tests — changed** (`FocusCompletionCelebrationTests.swift`): `testACardThatPlaysOpensArmed` →
`opening(plays: true, motion: .full/.modern) == .armed`; **`testReduceMotionOpensOnTheFinalState`
FLIPS** → `testReduceMotionOpensWithGeometryAtRestAndOnlyOpacityToTravel` (`== .armedInPlace`;
`burstScale == burstScaleEnd`; `checkmarkScale == 1`; `checkmarkOpacity == 0`;
`burstOpacity == burstOpacityStart`; doc comment records the old "opens settled" was the cut E lived
with); `testACardThatDoesNotPlayOpensSettled` loops `allCases`. Everything else unchanged. Surviving
call-site pins: `reduceMotion: reduceMotion`, `FocusCompletionCelebration(`, `.haptic(` absent from
card/stack, `celebrates: layer.record.id == celebratingID`, `latestConfirmableCompletion =` once.

**Tests — new, red first:**
- `ADHD LifeOSTests/FocusCompletionCelebrationMotionTests.swift` (pure; red by non-compilation —
  stub the enum and new members first so the red is countable): `testReduceMotionWinsOverEveryTier`,
  `testTheFloorGetsTheBurst`, `testIOS26GetsTheDrawOnTick`,
  `testTheReducedFadeEndsOnTheSameFrameAsTheBurst`, `testTheReducedTickFadesOnAPlainEaseAfterTheSameDelay`
  (`checkmarkAnimation(for: .reduced) == .easeOut(duration: 0.4).delay(0.3)`; full == modern),
  `testBothArmedPosesHaveSomewhereToGoAndSettledDoesNot`.
- `ADHD LifeOSTests/FocusCompletionCelebrationModernPathCallSiteTests.swift` (strings; **predicted
  red: 3 tests / 6 failures**): `testTheCelebrationCarriesBothTheModernAndTheFloorBranch`
  (`#available(iOS 26.0, *) {`, `} else {`), `testTheDrawOnTickSitsBehindTheGateInItsOwnAvailableType`
  (`@available(iOS 26.0, *)`, `.symbolEffect(.drawOn`), `testTheFloorPathIsStillTheTwoBeatBurst`
  (`withAnimation(FocusCompletionCelebrationMetrics.burstAnimation)` present today,
  `checkmarkAnimation(for: motion)` absent, `.scaleEffect(pose.checkmarkScale)` present).
- Suite 2,663 → **2,672**. Red-checks after, one at a time, commit first: delete `} else {` → 1
  test; make `resolve` ignore RM → 2 tests; default `geometryPinned = true` → 2 tests.

**Not in this block:** the RM fade for the card's *arrival* (`RootBottomOverlay`'s three nil
animations + the unconditional `.move + .opacity` transition). Those govern VStack reflow on every
tab; a non-nil animation would tween geometry under RM. The pilot hands E one variable to judge.
Register it as the next block, conditional on E liking the cross-fade.

**Design record:** add ONE row to `handoff/SESSION-OPENER-focus-card-design.md`'s postscript table
(record's "iOS 16 rules out `.symbolEffect`… / RM renders the final state" → "16 / RM cross-fade /
26 draw-on ladder; RM opens with geometry at rest and fades" — E, 2026-09-11). Never edit the body.

## Verification (block 2; block 1 runs the bar minus device and evidence)

1. `swiftlint lint` → 0. `./scripts/emulators.sh` in a second terminal. Full suite on `iPhone 17 Pro`
   (`9181EBF9-0F54-4A4D-A19C-19945D1BF155`), `-skip-testing:"ADHD LifeOSUITests"`, `127.0.0.1:9099`
   hits = 0, count matches prediction; every `.xcresult` deleted after reading. Sim build. Device
   build `-allowProvisioningUpdates`, `devicectl install` + `launch --terminate-existing` on
   `3DBC979A-3255-5456-8C30-172DB19B99B3`. PR; four-line close-out pasted.
2. **Render-to-PNG, all three modes**, temporary `ZZFocusCelebrationRenderProbe.swift` deleted before
   commit: `UIHostingController` in a `UIWindow(windowScene:)` from the test host's scene,
   `makeKeyAndVisible`, **synchronous** test, `RunLoop.main.run(until:)` between captures,
   `UIGraphicsImageRenderer` + `drawHierarchy(in:afterScreenUpdates: true)` (`false` is blank white),
   `overrideUserInterfaceStyle` for dark, `CACurrentMediaTime` stamps (ordering, not timing).
   Render the leaf via `init(plays: true, motion:)` inside a `ClosureRing`: `.full` must be
   pixel-identical to block 4's frames (16-path regression proof); `.reduced` frame 1 shows geometry
   at rest, tick at 0 opacity, faint 1.6 halo, mid-frames move opacity only; `.modern` shows the
   stroke drawing on, end frame identical to `.settled`.
3. **In-situ render** through the real overlay: a `FocusSessionService` with the recording fakes,
   `pushUnconfirmedCompletion` one record, host `RootBottomOverlay(isFabOpen: .constant(false),
   showsPill: false, focusService:)`; exercises `.modern` on the 26.5 sim through card → stack →
   overlay. `.reduced` is unreachable in situ (RM not injectable) — say so in the README.
4. **Decisive — E's phone, two looks.** **RM ON** (E's real setting): finish a 30s sprint; expect a
   cut arrival, then after 0.3s the tick fading in and the outer halo fading out, no scale, no
   stroke; haptic as before. **This verdict closes the block.** Then **RM OFF**: the card slides up,
   the tick draws itself on, the halo radiates. Ask for both verdicts separately.
5. **Evidence `screenshots/focus-completion-celebration-modes/`**, JPEG, README per CLAUDE.md:
   environment; what the renders caught that tests cannot; nothing written to Firestore; a
   filename → proof table (`00-` full, `10-` reduced, `20-` modern draw-on, `30-` in-situ, `40-`
   device RM on, `50-` device RM off). The §7.3 "Verified paths" line sits in the README and the
   block report.

## Risks and gotchas (write into the opener)

- Compile-only vs runnable: the 16 branch's *code* runs on 26.5 via `motion: .full`; its
  *selection* on a 16–25 OS is compile-only; there is no 17 tier; `.modern` under RM is unreachable
  by construction (`testReduceMotionWinsOverEveryTier`). Report per tier, never "works on 16".
- Symbol effects do not honour RM — resolution happens in `resolve` before the tier. Verify on E's
  phone with RM ON that no draw-on stroke plays. Whether `.drawOn` runs on the spring's timing or
  its own is unverified — evidence it, don't fight it.
- `.drawOn` on removal: insertion-only asymmetric transition; check Confirm frames in situ for a
  stray draw-off when `.id(celebrates)` rebuilds or the card leaves.
- The pure types move to a NEW file — the new call-site tests must read the VIEW file
  (`Focus/FocusCompletionCelebration.swift`). Do not rename it.
- `FocusSessionService.swift` at 394/400 — untouched; the in-situ probe only *uses* it.
- The haptic already fires under RM; a second one on the card is banned by
  `testTheHapticListenerOutlivesTheStack`.
- `Executed N tests, with M failures` counts assertions; reconcile with
  `grep -oE "Test Case .*' failed" | sort -u`. Commit before every red-check; restore with
  `git checkout -- "ADHD LifeOS/"`; prove by rebuilding. Never `&&` a commit onto a piped build.
- `Animation` equality: if the toolchain surprises, assert the constants instead and say so.
- Erase the simulator after any UI-target run before a unit run. Provisioning profile valid to
  **2026-09-17**; a `Security` denial right after a re-issue is transient — retry once.
- Under RM OFF the card *arrival* also animates — keep E's attention on the celebration itself.
