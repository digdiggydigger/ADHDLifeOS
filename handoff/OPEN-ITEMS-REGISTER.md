# Open items register — 2026-09-11 (twenty-third edition; F-ModernIOS-1-Policy LANDED — block 2 waits on E's review)

*Written at the close of block 1 of the modern-iOS pilot, by the fresh session the twenty-second
edition queued. `F-ModernIOS-1-Policy` rewrote CLAUDE.md §7 and swapped one test. It is merged to
`main` and **waiting on E's review. Block 2, `F-ModernIOS-2-Celebration`, is not cut until E has
seen block 1** (the opener's order). Supersedes the twenty-two earlier editions.*

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

Every figure below was measured this session unless marked (carried).

## State

**`main` @ the `F-ModernIOS-1-Policy` merge (PR #63). The last APP-code change is still `d8b334b`**
(PR #58, `F-FocusCard-4`). Block 1 changed CLAUDE.md, two test files and the app's marketing
version, and no line the app target compiles.
- **The modern-iOS pilot is HALF DONE:** block 1 is on `main`, and block 2 waits for E's review.
  The live opener is still **`handoff/START-HERE-modern-ios-pilot.md`**, which now opens with a
  status line saying block 1 has landed.
- **Verified this session:** unit suite **2,663 / 0** (emulator UP, **0** `127.0.0.1:9099` hits,
  0 skipped; the 2,663 → 2,663 prediction held), SwiftLint **0 / 739**, sim
  `** BUILD SUCCEEDED **`, app target **26.68% (12,255/45,932)**.
- `firestore.rules` untouched, so there is **nothing for E to republish**. Every `.xcresult` was
  deleted after its figures were read.
- **No branch in flight:** `main` is the only branch on GitHub.

**E's phone still runs `d8b334b` (installed 01:48 on 2026-09-11), which IS `main`'s app code.** It
was not reinstalled because block 1 changed no app code. The only build-visible change on `main`
since then is E's `MARKETING_VERSION` 1.2 → 1.3.

**Coverage: app target 26.68% (12,255/45,932), byte-identical to block 5's figure.** This is the
trivially comparable case: no app-target line moved, so neither did the numerator or the
denominator. The test target moved because its files did (one test out, one in, one new file).

```
ADHD LifeOS.app              26.68%  (12255/45932)  ← identical to block 5
ADHD LifeOSTests.xctest      95.27%  (42130/44220)  ← was 95.30% (42100/44176)
ADHD LifeOSUITests.xctest     0.00%  (0/2962)       ← skipped in the standard run by design
FocusTimerWidgetExtension    10.30%  (228/2214)     ← read the 233-line testable surface, not this
```

### Landed this session

- **E's `MARKETING_VERSION` 1.2 → 1.3** (`4052c52`, its own commit on the block-1 branch). E made
  the edit in Xcode before the session and confirmed it in chat. Xcode also re-sorted the widget's
  `membershipExceptions` list alphabetically, which changes nothing.
- **`F-ModernIOS-1-Policy`** (`0e980e5`, PR #63). CLAUDE.md §7 is now "The iOS 16 floor, modern
  APIs, and Reduce Motion":
  - **7.1:** the best API per site, with a complete 16 branch beside it. *Degraded* sites always
    have an `else`; *absent* is for whole features only; feedback is never absent.
  - **7.2:** Reduce Motion fades and never removes feedback.
  - **7.3:** compile-only by policy, plus the "Verified paths" report line.
  - **7.4:** tests over two paths.
  - **7.5:** the old skill-precedence section, extended to the `apple:*` / `apple-skills:*`
    plugins, with `apple:modernize` explicitly barred from skipping the gate.
  - **Touch-ups** in Architecture notes, §2, §3 and §5.

  `testTheCelebrationUsesNothingAboveTheiOS16Floor` is deleted.
  `ModernAPIPolicyCallSiteTests.testTheHouseHapticHelperIsTheTwoBranchExemplar` is added. It reads
  the gate, `.sensoryFeedback(`, `} else {` and `Haptics.play(feel)` **in order** inside
  `haptic(_:trigger:)`, because `} else {` alone is the commonest line in Swift. **Red-checked** on
  a committed tree: changing `} else {` to `} else  {` in `Theme/Haptics.swift` gave a full suite of
  `Executed 2663 tests, with 1 failure`, and it was exactly that test. The file was restored with
  `git checkout --` and the restore proved by the green rebuild.

### What this session established

- **The 25-test gap is NOT tests that `xcodebuild` skips.** `ADHD LifeOSTests` defines exactly
  **2,663** `func test…` and the run executed **2,663**, so every defined unit test runs. The gap is
  not unit + UI either: the UI target defines 30, which would make 2,693. The bridge's 2,688 is its
  own enumeration and could not be re-run, because **the `xcode` MCP server was down all session**
  (Xcode was not running at session start, the documented trap). Re-check `GetTestList` the next
  time the bridge is up. It is not a defect.
- **The widget/app version mismatch is a live build warning on every build:**
  `The CFBundleShortVersionString of an app extension ('1.0') must match that of its containing
  parent app ('1.3')`. It was already 1.0 against 1.2 before E's bump. This is E's call (§A).
  Confirm against an actual upload report before calling it a launch blocker.

### What the planning session established — the Reduce Motion root cause (2026-09-11) (carried)

- **E's phone runs Reduce Motion ON (and Prefer Cross-Fade Transitions ON).** This was read off the
  phone via iPhone Mirroring, read-only. Every animation in the bottom furniture is
  `reduceMotion ? nil : …`, and the celebration opens on its settled pose under RM, exactly as the
  design record specified. So **the block-4 burst has never once played on E's phone.** E saw a
  hard cut plus the success haptic, which does fire under RM.
- **This is not a code defect.** The celebration renders correctly in the simulator, both in
  isolation AND in situ through the real overlay + service. It is a product gap: Apple's guidance
  under RM is to replace motion with a fade, not remove feedback, and this app removes it (19 of
  its 20 RM-guarded sites are `nil`; the one fade is `Capture/CaptureFanOverlay.swift:89-96`).
  **CLAUDE.md §7.2 now says so.**
- **E's decisions, settled:**
  - RM gets a cross-fade celebration.
  - Progressive enhancement across every tier that adds value above the 16.0 floor.
  - Fallback proof is compile-only for now, documented (§7.3).
  - Policy first (landed), then the celebration as the pilot.
  - A fresh session builds.
  - The tick's ladder is 16 spring / RM fade / **iOS 26 `.drawOn`**, with no 17 tier.
- **`.drawOn`/`.drawOff` are `@available(iOS 26.0)`** in the 26.5 SDK's swiftinterfaces, and E's
  phone is on 26, so it is a tier E can see. `SymbolEffectOptions` has no RM option: symbol effects
  do not self-gate, so RM must be resolved before the tier.
- **What "compile-only" means, precisely:** the 16 branch's CODE runs on the 26.5 simulator
  whenever the motion mode is injected as `.full`. What cannot be exercised is its *selection* on a
  16–25 OS. Report per tier, and never write "works on iOS 16".
- **Harness lessons:**
  - An `async` XCTest pumping `RunLoop.main` cannot drain the queue SwiftUI's updates land on. The
    in-situ frames froze mid-transition until the probe became a synchronous test driving
    `finishCurrentSprint` → pump → `pushUnconfirmedCompletion`.
  - The block-4 render was the card in isolation. The first in-situ render came only when E
    reported the gap.

### What block 4 established, beyond the animation (carried)

- **`drawHierarchy(afterScreenUpdates: false)` from a test host renders BLANK WHITE.** Use `true`
  and a scene-attached `UIWindow`. It then captures in-flight SwiftUI animation frames, so motion
  can be evidenced by render too.
- **`accessibilityReduceMotion` is not writable via `.environment(\.)`.** Render the leaf with the
  flag as a parameter, and hold the parent's pass-through with a call-site test (now §7.2).
- **A listener on a view inserted in the same update that changes its trigger misses that
  change.** The haptic lives on the persistent overlay for exactly this reason.
- **`FocusSessionService.swift` is at 394/400** after moving two accessors out.

### What the peek work established (2026-09-10), and it is worth more than the constant (carried)

- **The lever ordering this register carried was BACKWARDS.** It named `opacityStep` the blunt
  instrument, but opacity moves the keyline only **1.30:1 → 1.35:1**, which is invisible, because
  the layer behind already draws at 0.85.
  - **What the eye reads is the sliver's HEIGHT**, so `peekStep` is the lever.
  - `scaleStep` 0.10 actually *lowers* keyline contrast to 1.21:1, dropping more of the line onto
    the corner curve.
  - **A contrast ratio answers whether an edge can be DISTINGUISHED, never whether anyone will
    NOTICE it.** Render the options before ranking levers.
- **`peekStep = 14` is the app's ONLY sanctioned off-grid spacing value.** §2 is 4/8/16/24; E was
  offered the on-grid 16 explicitly and chose the value they had approved by sight. The waiver is
  written into **`CLAUDE.md` §2** and pinned by `testThePeekStepIsTheValueEChoseByLooking`.
  **Do not "correct" it.**

## A · Decisions only E can make — minutes each

- [ ] **E's review of `F-ModernIOS-1-Policy`** (PR #63, merged). Read CLAUDE.md §7.1–7.5. Block 2's
      branch is cut after this. (NEW)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. iOS 17.x proves
      the 17 gates select and 16.x proves the floor. It is ~7 GB on the external SSD and **E's GUI
      job** per the manual-step convention. Until then every `#available` fallback in the app is
      compile-only **by policy (CLAUDE.md §7.3, now landed), not by oversight.** Asked at block 1's
      stop, which is the natural break the last edition named. (carried; asked 2026-09-11)
- [ ] **The widget extension's `MARKETING_VERSION` is 1.0; the app's is 1.3.** Xcode warns on
      every build (see "established" above). Match them or leave it: version numbers are E's.
      (NEW)
- [ ] **Do the collapsed card's square BOTTOM corners still earn their keep?** (carried) A "look
      again next time you are in there", not a defect.
- [ ] **Should the widget's view-only files be made testable at all?** Recommendation is still to
      leave it. (carried)
- [ ] **E's SECOND change — still not described.** Ask once the arc reaches a natural stopping
      point. (carried; E's *first* change was the focus card arc.)

## B · Real work, ready to start — recommended order

**0. `F-ModernIOS-2-Celebration`: the pilot's second block, NEXT, once E has reviewed block 1.**
   - **Where it is specified:** the live opener, **`handoff/START-HERE-modern-ios-pilot.md`**,
     "Block 2", which carries E's approved plan verbatim.
   - **Branch:** `feature/modern-ios-celebration` off `main`. Block 1 is on `main`, so the order
     holds.
   - **The design:** three motion modes (`.full` 16 spring unchanged / `.reduced` RM cross-fade /
     `.modern` iOS 26 draw-on), with the pure types split to
     `FocusCompletionCelebrationPose.swift`.
   - **Tests first:** the string tests are predicted red at 3 tests / 6 failures, and the suite
     goes 2,663 → 2,672.
   - **Evidence:** rendered in all three modes + in situ.
   - **Closes on E's phone with RM ON**; RM OFF is a second look.
   - **Now binding:** every report carries §7.3's "Verified paths" line.

**0b. Follow-ups the pilot deliberately leaves out — pick up only after E's verdict:**
   - **RM arrival fade for the bottom furniture** (`RootBottomOverlay`'s three nil animations +
     the card's unconditional `.move + .opacity` transition), only if E likes the pilot's
     cross-fade. The reflow must NOT tween under RM, so the card's transition would split.
   - **The modern-API inventory, register-only until each is a block.** `apple:modernize`'s
     suggestions land here too, per §7.5.
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint
       countdown (`FocusTimerBarContent.swift:194`) and ~20 `.monospacedDigit()` counters;
       `.presentationBackground` (16.4) on three sheets.
     - **Needs 17:**
       - `ContentUnavailableView` in `TaskListView`, `CaptureInboxView`, `TagEditorListView` and
         `TaskSearchSurface`.
       - `.contentTransition(.symbolEffect(.replace))` for pause/play and the disclosure
         chevrons.
       - Interactive Home Screen widgets (`Button(intent:)`) and step check-off on the routine
         Live Activity.
       - The `@Observable` migration (27 classes).
       - TipKit for the card's undiscoverable gestures.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it, not augmenting it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift:63`'s declared-but-unread `reduceMotion` beside
     two unguarded animations. These are §7.2's first sweep candidates.

   The focus card design record (`handoff/SESSION-OPENER-focus-card-design.md`, permanent) opens
   with a postscript table of everything that shipped against it; block 2 adds one row.

1. **E's one un-run device check: airplane mode + pull-to-refresh on Home.**
   `F-HomeTasksLastKnown` (`8b5f740`) should keep the last-known task set rather than emptying it.
   This is unrelated to the focus card. E ran checks 1–3 on 2026-09-11 with nothing reported wrong:
   Confirm doesn't reopen a collapsed card, a tap opens the detail, and `F-TabBar-NoScrollDrop`.
   (carried)

2. **Small defects in the card, none blocking:**
   - **`FocusBarCardShape.roundsBottomCorners` is a `Bool` with no `animatableData`**, so the
     corner morph SNAPS inside the 350ms spring while the inset, offset and padding all tween.
     Fixing it means a `CGFloat` bottom radius and per-corner arcs. (carried)
   - **The card's `.accessibilityAction(named:)` may attach to nothing.** It wants an Accessibility
     Inspector pass: this bar is the app's only door to `FocusSprintDetailView`. (carried)
   - **`FocusTimerBarContent` has no `#Preview` of its own**, unlike the other content-split
     files. (carried)
   - **A slow location fix delays the completion CARD, not just the write.** Correct as built, but
     worth knowing if E ever reports the card appearing late. (carried)
   - **The stack has no UI journey** and probably cannot have a useful one. The evidence is the
     render plus E's device shots, which is what the design record anticipated. (carried)

3. **Two more dead design tokens, and two dead helpers.**
   - `BarSurface` is a colorset that is defined and unit-tested, and used by nothing.
   - `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call sites and
     **disagree about their input**.

   (carried)

4. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops after #32.**
   (carried)
5. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
6. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
7. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of this arc explicitly. The collision is real
  and documented, not fixed: it shares `RootBottomOverlay`'s VStack with the completion stack. So
  an old unacknowledged app-was-dead completion and a new unconfirmed sprint can be on screen
  together in two different visual languages. `F-FocusCard-5` records it. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. (carried)
- **Sign in with Apple** built but dormant. (carried)

## E · Known, not work

- **Xcode's MCP bridge (`xcrun mcpbridge`, server `xcode`) is documented in CLAUDE.md under
  Commands, and it was DOWN this whole session.** The connection closed at startup because Xcode
  was not running: open Xcode BEFORE the session. Its `GetTestList` count of 2,688 against 2,663
  executed is reconciled as far as it can be without the bridge: every defined unit test runs, and
  unit + UI would be 2,693, so 2,688 is the bridge's own enumeration. (updated)
- **A green suite cannot see a `View`'s appearance, and the focus card arc proved it four times.**
  - Block 1's `layoutPriority` compression reached E's device.
  - Block 2's was caught by a render.
  - Block 3's was the cards behind **ghosting through `.regularMaterial`**.
  - The peek's own quietness was invisible to every layout assertion, all of which held.

  **Render the view to PNG from a unit test before the device build:** `UIHostingController` +
  `UIGraphicsImageRenderer` + `drawHierarchy`, `overrideUserInterfaceStyle` for dark, hosted in a
  `UIWindow` with the run loop pumped briefly. It costs a minute and needs no signed-in simulator.
  **To vary a `static let` constant across variants, make it `var` for ONE run, then
  `git checkout --` and prove the restore with a full build.** (carried)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  TESTS, then reconcile. Names: `grep -oE "Test Case .*' failed" <log> | sort -u`. (carried)
- **SwiftLint's 400-line file and 250-line `type_body_length` ceilings are one TEST away.** The
  fix is a thematic file split with its own `private` doubles. (carried)
- **A `devicectl` launch denied with `Security` / "invalid code signature… not explicitly trusted"
  right after a re-issued profile is TRANSIENT — retry once before escalating to E.** It reads
  exactly like the free-account provisioning blocker. Check the embedded profile's
  `ExpirationDate` against `date` and run `codesign --verify --deep --strict`: valid and freshly
  minted means retry, not E. Three species share that one error surface, separated only by the
  failure reason:
  - `Locked`: unlock the phone.
  - `Security` + a valid profile: retry.
  - `Security` + an expired profile or "No Accounts": E signs in via Xcode → Settings → Accounts.

  (carried)
