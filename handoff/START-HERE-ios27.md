# START HERE — **the iOS 27 arc.** Phase A is DONE; the next session opens at the Xcode 27 gate

**Written 2026-09-14.** iOS 27 shipped today. E asked to move the app onto it "safely to ensure that
nothing breaks", and chose the scope, the ordering and the phone policy in the same sitting.

> **E's instruction, 2026-09-14:** *"i need to look at updating the LifeOS application up to the most recent
> iOS version that was released today - iOS 27. This must be done safely to ensure that nothing breaks."*
> Then: *"look for any clashes between the design of the UI of the top version iOS 26 compared to the new top
> level which is iOS 27"*, and *"analyze the Firebase storage and authentication services … make sure that
> they are translatable"*, and *"install it onto the external SSD that is connected currently."*

The full plan is `/Users/ethan/.claude/plans/okay-claude-i-need-melodic-origami.md`. This file is the pointer.

---

## ⚠ THREE INSTRUCTIONS BEFORE ANYTHING ELSE

1. **THE COLOUR-SCHEME HOLD IS STILL IN FORCE.** E paused the whole §B queue on 2026-09-13 for the curated
   colour scheme, then on 2026-09-14 chose **"iOS 27 first, colour arc stays held"**. Its opener has been
   archived to `handoff/archive/START-HERE-colour-scheme.md` so this folder keeps ONE live opener — the hold
   is unchanged, only the pointer moved. Do not start the colour arc, and do not offer to.
2. **DO NOT RAISE THE DEPLOYMENT TARGET.** 16.0 (app) / 16.1 (widget) stay. Only the **SDK** moves. CLAUDE.md
   §7.5 forbids the raise and no skill overrides it.
3. **E'S PHONE IS HELD AT iOS 26.4** with Automatic Updates off, by E's own decision, until Xcode 27 is
   installed. Device verification is the project's whole bar; do not suggest updating the phone before the
   toolchain.

---

## ⬛ STATE AT 2026-09-15 02:30 — THE GATE IS OPEN. Read this before the baseline table.

**Xcode 27.0 (27A266a) is INSTALLED, licence accepted, Swift 6.4, iOS 27.0 SDK present.** E installed it
on 2026-09-15. Phase B is therefore DONE, with three deviations from the plan that a later session must
know about:

1. **Xcode 26.6 IS GONE — there is no rollback.** It installed over the top at `/Applications/Xcode.app`
   rather than alongside on the SSD, so the `DEVELOPER_DIR` rollback the plan called for does not exist.
   If Swift 6.4 breaks something that cannot be fixed quickly, **there is currently no way to build this
   app at all.** Re-downloading 26.6 from the developer portal (~4 GB) is the insurance; E has been told
   and has not yet decided.
2. **The iOS 27 SIMULATOR RUNTIME IS NOT INSTALLED, and that is DELIBERATE.** Boot volume is ~12 GB free
   and the runtime needs ~8 GB on that volume (it cannot go on the SSD — MobileAsset cryptex). It is not
   needed yet: **the deployment target is 16.0, so a 27-SDK binary runs on the existing 26.5 runtime.**
   Running Phase C on 26.5 changes exactly ONE variable — the SDK — which is the whole point. The 27
   runtime is needed for **Phase D only** (the 26-vs-27 visual sweep), and by then the 5.5 GB of
   `iOS DeviceSupport` can be freed for it.
3. **macOS TCC blocks the external SSD, and this WILL bite again.** After the Xcode 27 install the volume
   remounted (00:36) and every access returned `Operation not permitted` — EPERM, not EACCES, so it is
   privacy control and NOT file permissions. DerivedData lives on that volume, so **no build can run**.
   E granted Ghostty **Full Disk Access**; reads started working immediately but **writes still require
   Ghostty to be quit and reopened**. If a build fails with "couldn't be opened because you don't have
   permission", this is it — check `touch /Volumes/Es-SSD/.test` before blaming the toolchain.

**ALSO ALREADY DONE, ahead of the plan's order (E's call, 2026-09-15): the Firebase bump.**
`F-FirebaseKeychainFix` merged `cfdb250` (PR #123) — **12.17.0 → 12.19.1**, fixing silent random
sign-outs. And the emulator count was corrected 116 → **58** (PR #124): xcodebuild logs each case twice,
so a naive `grep -c` doubles it.

**WHAT HAS NOT HAPPENED YET:** the app has **never been compiled under Swift 6.4**. The first attempt
died on the TCC block before reaching the compiler, so **nothing is yet known** about whether it builds,
how many warnings it produces, or whether the 3,011 tests still pass. That is the very next thing to do.

**THE NEXT COMMAND**, once Ghostty has been restarted and `touch /Volumes/Es-SSD/.test` succeeds:

```bash
rm -rf TestResults.xcresult
xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -skip-testing:"ADHD LifeOSUITests" \
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
```

**Do NOT pass `-resolvePackageDependencies`**, and check `git diff` on `Package.resolved` afterwards —
it must not move. It was verified unchanged (`md5 5362cb266cc69a00bd8e0ded7ecaffa4`) through the failed
attempt, and holding it fixed is what makes a Swift 6.4 failure attributable.

---

## THE BASELINE — captured 2026-09-14 on Xcode 26.6, and this is the whole point of Phase A

**Without this, no post-upgrade failure is attributable.** Measured at `855759c`, against a **freshly
restarted** emulator (the previous one had been running 1 day 19 hours; E called it, correctly).

| Signal | Baseline |
|---|---|
| Unit suite | **3,008 / 0**, `** TEST SUCCEEDED **`, in 49.7 s |
| Emulator-retry hits (`127.0.0.1:9099`) | **0** — the poisoned-simulator tell is clean |
| Emulator-backed cases | **58**, all six classes ran (see below) |
| SwiftLint | **0 violations, 0 serious, 812 files** |
| Build | `** BUILD SUCCEEDED **`, **70 warnings, 0 errors** |
| Coverage — app target | **27.56% (13,356 / 48,454)** |
| Tree | 423 Swift files, 53,093 raw lines (app + widget) |

### ⚠ ALL 70 BUILD WARNINGS ARE CONCURRENCY WARNINGS — and this is the number that matters most

Not a mixed bag. Every single one:

```
25  call to main actor-isolated initializer in a synchronous nonisolated context
24  call to main actor-isolated static method in a synchronous nonisolated context
11  main actor-isolated static property can not be referenced from a nonisolated context;
      THIS IS AN ERROR IN THE SWIFT 6 LANGUAGE MODE
 4  converting non-Sendable function value may introduce data races
 2  main actor-isolated static property can not be referenced from a nonisolated context
 2  main actor-isolated property can not be referenced from a nonisolated context
 2  main actor-isolated global function cannot be called from outside of the actor;
      THIS IS AN ERROR IN THE SWIFT 6 LANGUAGE MODE
```

**Thirteen of the seventy already announce themselves as Swift 6 errors.** The project is on
`SWIFT_VERSION = 5.0` with `SWIFT_APPROACHABLE_CONCURRENCY = YES` and
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target only) — so it is sitting on the edge of the
Swift 6 model already, and **Swift 6.4 is what Xcode 27 ships**.

**This is the single most likely thing to move in Phase C.** Diff the count and the breakdown, not just
"did it build". A rise here is the expected outcome, not a surprise; what matters is whether any of them
becomes an *error*. **Keeping `SWIFT_VERSION = 5.0` is what stops that** — which is why the plan forbids
flipping it in this arc.

**The six emulator-backed classes all RAN** — this is the Firebase proof, and it must still hold after the
SDK move:

```
FirebaseManagerTagsTests             19     FirebaseManagerSeedTests            13
FirebaseManagerAccountDeletionTests  13     FirebaseManagerStorageTests         10
FirebaseManagerRoutineRunsTests       2     FirebaseManagerNudgeCompletionTests  1
```

**Count DISTINCT test-case names, not log lines.** `xcodebuild` logs each case twice — once
`' started'` and once `' passed'` — so a naive `grep -c` reports exactly double. An earlier edition of
this file and of the register said "116"; the real figure is **58**, and the doubling is the reason.

⚠ **CLAUDE.md says "the four extensions the emulator harness covers". There are SIX.**
`+RoutineRuns` and `+NudgeCompletion` joined and were never added to the doc. Corrected here.

### Coverage: the denominator moved, and here is WHY (CLAUDE.md's standing rule)

`44,961 → 48,454`. The move is **tree growth**, not a change of measurement extent: 380 → 423 Swift files,
46,978 → 53,093 raw lines. Both runs measured 100% of the app target, so **the figures ARE comparable**:

- numerator **11,114 → 13,356 (+20.2%)**
- denominator **44,961 → 48,454 (+7.8%)**
- ratio **24.72% → 27.56%**

Coverage grew roughly two and a half times faster than the code. That is a real gain, not an artefact.

---

## WHAT THE RESEARCH ESTABLISHED (all of it primary-sourced; do not re-derive)

**1. There is no emergency.** Every documented iOS 27 behaviour change is worded *"In apps built with the
iOS 27.0 SDK…"*. The build E is running keeps working when their phone reaches 27. The deadline is
**April 2027**, when the iOS 27 SDK becomes the App Store Connect minimum.

**2. The Liquid Glass cliff does not apply to this app.** `UIDesignRequiresCompatibility` is **absent from
the project** — it was never set, so the app has rendered Liquid Glass since it was first built against the
26 SDK. Apple's doc is explicit that the key *"is ignored when you build for iOS 27 or later"*; that cliff is
behind us, not ahead. **This is the single biggest reason the arc is low-risk.**

**3. Almost every iOS 27 breaking change misses this codebase.** Checked against the tree:

| Change | Here? |
|---|---|
| `@State` is now a macro (TN3211) — decl-value + `init` assignment fails to compile | **no instances** of the `_x = State(…)` pattern across 219 sites |
| `TabView` crashes on hidden selection | **N/A** — zero `TabView`; the bar is `AppTabBar` |
| `containerRelativeFrame` safe-area calc | **0 uses** |
| `scrollEdgeEffectStyle(.soft)` | **0 uses** |
| `PreviewProvider` deprecated | **0 uses** (all `#Preview`) |
| MetricKit symbol/type change → launch crash | **0 uses** |
| `FileDocument` deprecated | **0 uses** |
| `controlSize` / `ButtonBorderShape` reset in sheets | **2 sites** — check |
| `.textSelection` gains gestures | **1 site** — check |

**4. Two that DO land:**
- **`UIApplication.canOpenURL` is deprecated in iOS 27.** Used at `Places/PlaceAppInstallVerification.swift:91`;
  the app-directory "installed" badge and its 45 `LSApplicationQueriesSchemes` depend on it. Apple's suggested
  replacement ("open the URL and handle failure") **does not preserve the feature**. It is behind a one-method
  seam, so the blast radius is small — but **what the badge becomes is E's design call, not a refactor.**
- **Presented VCs now inherit traits by walking the superview chain** (release note 170005251). That is exactly
  the hierarchy `CelebrationPresentationProbe` walks — the UIKit probe E chose in `F-CTACelebrations-Surfaces`
  and passed on device on 2026-09-13. **Highest-value regression check in the arc.**

**5. The subtlest one, and it affects the FLOOR not iOS 27:** the `@State` macro's lazy-init behaviour
**back-deploys to iOS 17**. Recompiling with Xcode 27 changes runtime behaviour on iOS versions the app
already supports. With 219 `@State` and 55 `@StateObject` sites, this is the likeliest silent regression —
and the reason the baseline above exists.

**6. Reduce Motion, `symbolEffect`, `PhaseAnimator`, `keyframeAnimator`: NOTHING CHANGED.** Apple's
Accessibility and Symbols Updates pages have no 2026 sections; the iOS 27 release notes have zero
accessibility-behaviour entries. **§7.2 and the celebration ladder are untouched.** A clean negative.

**7. Firebase — and this outranks the migration.** The iOS floor is **unchanged at `.iOS(.v15)`** in both the
pinned 12.17.0 and the latest 12.19.1, so **16.0 is safe**. The binary deps are already the newest that exist.
BUT: **12.19.0 fixed a keychain bug that silently signs users out** — `SecItemCopyMatching` returning
`errSecItemNotFound` on a locked device, which FirebaseAuth trusted (PR #16505; reporters measured ~1% of
active users). **This app restores sessions with a single `currentUser` read and no
`addStateDidChangeListener` fallback**, so it is maximally exposed. Target **12.19.1**; **skip 12.18.0**
(app-extension regression, reversed in 12.19.0).

**8. Two HIG revisions dated 2026-09-09 point at this app:** *Layout* now says use a scroll edge effect rather
than a solid background beneath controls (the app has **zero** `scrollEdgeEffect` uses and a custom bar with
its own background), and *Branding* says move brand colour into the content layer "where it scrolls beneath
Liquid Glass controls". **That second one is a direct input to the held colour arc** — and the concrete reason
doing iOS 27 first was the right order.

---

## THE GATE: what E must do before Phase C can start

**Xcode 27 requires macOS 26.6+ and Apple silicon. This Mac is an M1 on 26.6.1 — it qualifies.**

| Component | Size | Where |
|---|---|---|
| Xcode 27 `.xip` download + expansion | ~12–16 GB transient | **`/Volumes/Es-SSD`** ✅ (E's instruction) |
| `Xcode-27.app` | ~4 GB | **SSD** ✅ |
| **iOS 27 simulator runtime** | **~8 GB** | **BOOT VOLUME — cannot be moved** ❌ |

**Why the runtime is the exception, and it is not negotiable.** Runtimes are no longer folders inside Xcode.
The installed 26.5 runtime is a *Patchable Cryptex Disk Image* under
`/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/…`, mounted at
`/Library/Developer/CoreSimulator/Volumes/iOS_23F77`. MobileAsset-managed, system volume, no supported
relocation. **So ~8 GB of boot-volume space is unavoidable however Xcode is installed.**

**Boot volume had 12.2 GB free.** Reclaim: `~/Library/Developer/CoreSimulator/Devices` is **11 GB** and
regenerates safely. `~/Library/Developer/Xcode/iOS DeviceSupport` is 5.5 GB but is **entirely E's phone at
26.4** — taking it costs one slow re-extract.

**DO NOT DELETE THE iOS 26.5 RUNTIME** (7.9 GB, `Deletable: YES`). Phase D's whole comparison needs both.

**Keep Xcode 26.6 as the rollback** — rename to `Xcode-26.6.app`, switch with **`DEVELOPER_DIR`**, never
`xcode-select`, so a stray command cannot change the global toolchain mid-arc.

**Also E's, and time-boxed:** the **dev profile expires 2026-09-17**; `brew upgrade swiftlint` (0.65.0 may not
parse Swift 6.4).

---

## PHASE C, WHEN THE GATE IS OPEN — the traps, in order

1. **Xcode 27 will offer to "update to recommended settings"** (`objectVersion = 77`, `LastUpgradeCheck = 2660`).
   **Decline.** Take any change one at a time with a suite run between.
2. **`SWIFT_VERSION` stays 5.0.**
3. **First 27 build uses the committed `Package.resolved` UNCHANGED** — no `-resolvePackageDependencies`, and
   `git diff` it afterwards to prove it did not move. The pin is `upToNextMajorVersion` from 12.0.0, so it will
   drift on its own and make Xcode-27-vs-Firebase indistinguishable. Bump Firebase as its own step.
4. **Destinations now need explicit `,OS=`** — two `iPhone 17 Pro` sims will exist. Update CLAUDE.md's
   Commands section in the same change.
5. **Confirm the two hard gates on the first build**: scene-based lifecycle and a launch-screen key. Both
   should already be satisfied (SwiftUI `App` + `WindowGroup`; `UIApplicationSceneManifest_Generation` and
   `UILaunchScreen_Generation` are both `YES`) — but the failure mode is "does not launch", so confirm.
6. **Concurrency errors, if any, land here first:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set on the
   **app target only**. Look at `Places/CoreLocationTriggerMonitor.swift` (6 `nonisolated`) and
   `CoreLocationFixProvider.swift` (3), then the widget-shared attribute files, which meet two different
   isolation defaults.
7. **27 `*CallSiteTests` read Swift source as TEXT and pin exact literals** — `ModernAPIPolicyCallSiteTests`
   pins `"if #available(iOS 17.0, *) {"` *including the brace*, in order. **Reformatting a gated call site
   breaks tests that have nothing to do with behaviour.** Do not tidy gates as a drive-by.

**Three dead gates** (below the 16.0 floor, may start warning): `ADHD_LifeOSApp.swift:74` (14.0),
`NotificationCenterFocusNudgeAdapter.swift:45` (15.0), `TaskSearchSurface.swift:214` (16.0).

**What will NOT happen:** the 31 old-form `onChange(of:perform:)` calls will not warn. Deprecation warnings
fire against the **deployment target**, not the SDK, and that stays 16.0. Same for `CLCircularRegion`. Do not
let a skill claim otherwise.

---

## DO THIS FIRST, IN THIS ORDER

1. Read `claudecode.md`, then CLAUDE.md **§7.1–7.5**.
2. Read the plan file named at the top.
3. `git checkout main && git pull --ff-only`, then confirm the gate: `xcodebuild -version` must say **27.x**.
   If it still says 26.6, the gate is not open — **stop and tell E what is outstanding**, do not start Phase C.
4. Re-run the baseline commands and diff **every** number against the table above before changing anything.
