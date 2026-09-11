# Start here — the modern-iOS pilot (F-ModernIOS-1-Policy, then F-ModernIOS-2-Celebration)

*Paste into a fresh Claude Code terminal. Written 2026-09-11 at the close of the session that
debugged "I can't see any of the animations", found the root cause on E's phone, and planned this
pilot with E. E's instruction: **a fresh session builds it** — the session that planned it landed
only this handoff.*

**This is the ONE live opener.** If you find a second `START-HERE-*` in `handoff/`, one of them is
a trap. Archive this file into `handoff/archive/` in the same move that writes your successor, at
the END of your session, never at the start. Its predecessor, `START-HERE-post-focus-card.md`, is
already in `handoff/archive/`.

---

## Where things stand

**`main` @ the block-0 merge; the last CODE change is `d8b334b`** (PR #58, `F-FocusCard-4`). The
focus card arc is CLOSED. **E's phone runs `d8b334b`, which IS `main`'s code.** No branch in flight;
`main` is the only branch on GitHub. Verified figures (carried from the twenty-first register):
suite 2,663 / 0 (emulator UP), lint 0 / 738, app target 26.68% (12,255/45,932).

**The root cause, and why this pilot exists.** E reported seeing no animations after a natural
sprint completion. The celebration renders correctly in the simulator, in isolation AND in situ
through the real `RootBottomOverlay` + `FocusSessionService`. A read-only look at E's phone via
iPhone Mirroring found **Reduce Motion ON** (and Prefer Cross-Fade Transitions). Every animation in
the bottom furniture is `reduceMotion ? nil : …`, and the celebration opens on its settled pose
under RM — exactly as the design record specified. **So the block-4 burst has never once played on
E's phone; E saw a hard cut plus the haptic.** E is the target user and runs with RM on. Apple's
guidance under RM is to replace motion with fades, not remove feedback. The app removes it.

## Your job

**Two blocks, strictly in order, each its own PR. Block 2's branch is not cut until block 1 is on
`main`.** Stop after each for E's verdict (block 2's is a device verdict, with RM ON).

1. **`F-ModernIOS-1-Policy`** — rewrite CLAUDE.md §7 into the progressive-enhancement policy, plus
   the one test deletion and one test addition that keep the suite consistent with the prose.
2. **`F-ModernIOS-2-Celebration`** — the pilot: the celebration across three motion modes
   (16 spring / RM cross-fade / iOS 26 draw-on), test-first, rendered in all three, verified on
   E's phone with Reduce Motion ON and then OFF.

**The full approved plan is below — it is the specification.** Read it whole before doing anything.

## Read these, in this order

1. This file, to the end.
2. `handoff/OPEN-ITEMS-REGISTER.md` — twenty-second edition, THE outstanding list.
3. `CLAUDE.md` — Workflow, Version Control (`main` is protected), Session handoff, Visual evidence,
   UI/UX §1–§7. **§7 is what block 1 rewrites**; read it as it stands first.
4. `claudecode.md` — the TDD role definition.
5. `handoff/SESSION-OPENER-focus-card-design.md` — read its POSTSCRIPT table, then block 4's section.
6. `screenshots/focus-completion-celebration/README.md` — what the block-4 render settled, and the
   render technique block 2 reuses.

**Do NOT read `docs/`.** It is an archive describing a deleted Supabase backend.

## State gate — run before anything

```bash
git branch --show-current            # expect main
git status --short                   # must be empty
git log --oneline -1                 # and compare to origin/main
```

## Device reinstall recipe

```
xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS,id=3DBC979A-3255-5456-8C30-172DB19B99B3' -allowProvisioningUpdates
xcrun devicectl device install app --device 3DBC979A-3255-5456-8C30-172DB19B99B3 \
  "/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-etcfckccqnfwduaoegzziavhdjel/Build/Products/Debug-iphoneos/ADHD LifeOS.app"
xcrun devicectl device process launch --terminate-existing \
  --device 3DBC979A-3255-5456-8C30-172DB19B99B3 com.ethananthony.ADHD-LifeOS
```

**The profile is valid to 2026-09-17.** A launch denied with `Security` / "invalid code signature…
not explicitly trusted" right after a re-issued profile is TRANSIENT — retry once. A locked phone
refuses the LAUNCH but not the install. An empty Xcode account list means E must sign in via
Xcode → Settings → Accounts, never Claude Code.

---

# The approved plan (E, 2026-09-11) — verbatim


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

## Block 0 — THIS session, docs only, then STOP

Branch `chore/modern-ios-pilot-handoff`, one commit, `gh pr create` → `gh pr merge --merge
--delete-branch` → the four-line close-out check pasted. Verification for a docs-only PR: `swiftlint
lint` and `git diff --stat main` showing zero `.swift` files; say in the PR body the suite was not
re-run because no executable line changed (block-5 precedent).

1. **NEW `handoff/START-HERE-modern-ios-pilot.md`** — the one live opener. Sections: where things
   stand (RM root cause; block-4 burst never played on E's phone); *your job* = block 1 then block 2,
   each its own PR, block 2 not cut until block 1 is on `main`; E's five decisions verbatim; read
   order (register, CLAUDE.md, claudecode.md, design record postscript); state gate; the block 1
   design (below); the block 2 design (below); verification bar; risks; device recipe (profile
   valid to 2026-09-17).
2. **`git mv handoff/START-HERE-post-focus-card.md handoff/archive/`** in the same commit.
3. **`handoff/OPEN-ITEMS-REGISTER.md` → twenty-second edition:** header "MODERN iOS PILOT QUEUED
   (two blocks, fresh session)"; code SHA still `d8b334b`, figures carried; new "established this
   session" bullets — the RM root cause, `.drawOn` is 26 and E's phone can show it, no 17 tier for
   this tick and why, the 16 branch's *code* runs on 26.5 by injection while the OS-level behaviour
   is compile-only; **Section A**: "Install an older simulator runtime (Xcode → Settings →
   Components, ~7 GB, E's GUI job) — until then every `#available` fallback is compile-only by
   policy (§7.3)"; **Section B item 0**: the pilot, opener path, fresh session; **Section B, after
   it**: "RM arrival fade for the bottom furniture — only if E likes the pilot's cross-fade"; the
   modern-API inventory as register-only items (`.contentTransition(.numericText(countsDown:))` on
   the countdown, `ContentUnavailableView` ×4, `.symbolEffect(.replace)` on pause/play and chevrons,
   interactive widgets, `@Observable` ×27, `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`
   constrained by the custom `AppTabBar`).
4. **`TODO-CLAUDE-CODE.md`:** new heading `## Modern iOS pilot — E's call 2026-09-11` with two
   unticked FEATURE blocks, `F-ModernIOS-1-Policy` and `F-ModernIOS-2-Celebration`, each pointing at
   the opener.
5. **Memory (outside git):** new `modern-ios-pilot.md` (decisions, root cause, the 16/RM/26 ladder,
   opener path) + index line; one sentence appended to `focus-card-arc.md`.

**Why the CLAUDE.md §7 rewrite is block 1, not block 0:** the moment §7 says "best API behind
`#available`", `testTheCelebrationUsesNothingAboveTheiOS16Floor` asserts the opposite of the house
rule — landing prose the suite contradicts across a session boundary is the trap the handoff rules
exist to prevent. The rewrite carries a test edit and a suite run, which is build work (decision 5).
"Policy first" is still honoured: block 1 merges before block 2's branch is cut.

## Block 1 — `F-ModernIOS-1-Policy` (fresh session; branch `chore/modern-ios-policy`)

**CLAUDE.md §7 becomes "The iOS 16 floor, modern APIs, and Reduce Motion":**

- **7.1 The rule.** Best available API per SITE behind `if #available` (17, 18, 26); the 16 branch
  is always present and complete (same information, feedback, end state). The one exception is a
  feature whose whole surface is above the floor (Places, routine screen): *absent*, announced by a
  flag in the `ToolsView.placesSupported` shape, may have no `else`. Exemplars: `View.haptic(_:trigger:)`
  and, after block 2, `FocusCompletionCelebration`. A modern branch longer than a few lines lives in
  its own `@available(iOS N, *)` type (the `FocusSprintControls` shape). "Every tier that adds value"
  is a filter, not a quota — a tier that adds nothing is not added, and the block report says why.
- **7.2 Reduce Motion.** Replace motion with a fade, never remove feedback. E runs with RM ON: it is
  the author's primary experience, not an edge case. `reduceMotion ? nil : …` is correct only for
  continuous re-layout; for anything that appears, disappears or celebrates it is a hard cut and
  WRONG. House pattern: `CaptureFanOverlay.swift:89-96`. Opening-pose rule: under RM the first frame
  has final GEOMETRY; only opacity travels. Haptics unaffected. Symbol effects / `PhaseAnimator` /
  `keyframeAnimator` do not self-honour RM — resolve RM BEFORE choosing a tier. Add one clause to §5:
  its ban on plain easing does not apply to an RM opacity fade.
- **7.3 Verification honesty.** One runtime here (26.5). A fallback is proved to COMPILE and to be
  REACHED (call-site tests), and its code can be RUN by injecting the mode, but never run ON a 16/17
  OS. Every block report carries a **"Verified paths"** line: `26 path: run on sim + E's phone (RM
  off). Reduced: run on sim (injected) + E's phone (RM on). 16 path: code run on 26.5 by injection;
  OS-level behaviour COMPILE-ONLY — no 16 runtime installed.` Never "works on iOS 16".
- **7.4 Tests over two paths.** Pure logic shared, tested once. Call-site tests assert BOTH
  branches by string — `#available(iOS N, *) {`, `} else {`, and the floor API name. Render probes
  render the leaf with RM as a parameter (not injectable via `.environment`).
- **7.5 Design skills — precedence and known conflicts.** Keep as is, except: the `swiftui-pro`
  bullet now welcomes a 17+ API *behind a gate with a complete 16 path*; flip the `.sensoryFeedback`
  sentence — §3 prescribes it, use it via `.haptic(_:trigger:)`, which IS 7.1's pattern.
- **Touch-ups same commit:** Architecture-notes bullet "Any iOS 17+ API must be `#available`-gated"
  → point at §7.1; §3's `.sensoryFeedback` line → "via `.haptic(_:trigger:)` (§7.1)"; §5 clause.

**Test change:** delete `testTheCelebrationUsesNothingAboveTheiOS16Floor` (its premise is repealed;
a "must be gated if used" rewrite is vacuously green). Add
`ADHD LifeOSTests/ModernAPIPolicyCallSiteTests.swift` with
`testTheHouseHapticHelperIsTheTwoBranchExemplar`: `Theme/Haptics.swift` contains
`if #available(iOS 17.0, *) {`, `.sensoryFeedback(`, `} else {`, `Haptics.play(feel)`. Own private
`appCode` helper. Suite prediction 2,663 → **2,663**. Bar: lint, full suite (emulator up), sim build,
PR, close-out. Do not touch `FocusCompletionCelebration.swift` or the design record here.

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
