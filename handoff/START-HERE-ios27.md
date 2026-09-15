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

## ✅ DECIDED — the Xcode 26.6 rollback is SKIPPED. Do NOT re-offer it.

**E was given the full brief and decided on 2026-09-15:** *"lets skip the rollback for now but make sure
that this decision is logged in memory so ONLY IF NEEDED, we can return back to this point."*

**Start Phase D. Do not open this question again unless the one trigger below fires.**

**THE ONE TRIGGER, and it is narrow:** Xcode 27 producing a bad *artifact* rather than a compile error —
a build that is clean and green but misbehaves **on the device** in Phase F. That is the only thing 26.6
would diagnose, by rebuilding the same commit on the old toolchain and comparing. **A test failure, a
warning, or a simulator oddity is NOT the trigger** — those reproduce without it.

The reasoning and the five recovery steps are kept below because they are the record, not a task.

### What the rollback would achieve

Xcode 27.0 installed **over the top** of 26.6 at `/Applications/Xcode.app`, so 26.6 is gone. The plan had
called for keeping it side by side as `Xcode-26.6.app` and switching with `DEVELOPER_DIR`. The rollback
would restore **the ability to build this app with the previous toolchain**.

### ⚠ BUT THE CASE FOR IT IS NOW MUCH WEAKER THAN WHEN IT WAS RAISED — say so plainly

It was raised while the app had **never been compiled** under Swift 6.4, when the real fear was "Xcode 27
breaks something and there is then no way to build at all." That fear is now retired:

1. **The migration is green.** 3,011 / 0 on **both** runtimes, 0 errors, lint clean.
2. **THE CODE IS FULLY BACKWARD-COMPATIBLE — this is the decisive fact.** The entire Swift 6.4 change was
   two `actor` → `final class … @unchecked Sendable` conversions plus dropping one now-redundant
   `nonisolated`. **That pattern was already used THREE TIMES in the same file before the migration** —
   `FakeDailySummaryStore`, `FakeDailySummaryDataProvider` and `ToggleableDailySummaryGenerator`, all
   present at the pre-upgrade baseline `4e4ec1c`. So it compiles under Swift 6.3 too: **if 26.6 were
   reinstalled, current `main` would build on it unchanged.** The rollback is therefore NOT insurance
   against "our code is now 27-only" — that risk does not exist.

**So the only scenario it still covers** is Xcode 27 itself producing a bad *artifact* rather than a
compile error — something that builds clean but misbehaves on device in Phase F. Rebuilding on 26.6 to
compare would be the diagnostic. Real, but unlikely, and recoverable later since Apple keeps old Xcode
releases available.

### If E says yes — what E does (all of it is E's; none is Claude Code's)

1. developer.apple.com/download/all → search "Xcode 26.6" → download the `.xip`
   (sign in with the Apple ID; it is a developer-portal download, not the App Store).
2. **Download it to `/Volumes/Es-SSD`**, not the internal disk. Internal is at **26 GiB free** and was 96%
   full a day ago; the SSD has ~219 GiB.
3. Expand the `.xip` there (double-click, or `xip --expand`). Expansion needs roughly 2× the archive.
4. Rename the result **`Xcode-26.6.app`** and leave it on the SSD. **Do not put it in `/Applications`** —
   that is how 27.0 replaced 26.6 in the first place.
5. Tell Claude Code it exists. Switching is then per-command and never global:
   ```bash
   DEVELOPER_DIR=/Volumes/Es-SSD/Xcode-26.6.app/Contents/Developer xcodebuild ...
   ```
   **Never `xcode-select`** — that changes the machine's toolchain globally and a stray command could
   silently move the whole project back a version mid-arc.

**Cost:** one large download, ~10 GB on the SSD, and E's time. **No boot-volume cost.**
**Note:** the iOS 26.5 runtime is already installed and 26.6 would use it, so no extra runtime download.

### The recommendation E acted on

**Skip it, and revisit only if Phase F turns up a device-only problem.** — **E AGREED, 2026-09-15.** The code is backward-compatible,
the build is green on both runtimes, and Apple keeps old Xcode releases — so this decision can be deferred
at no cost, which is exactly what makes deferring it safe. **It is E's call, not Claude Code's**, and if E
wants the safety net, steps 1–5 above are the whole job.

---

## ⬛ STATE AT 2026-09-15 — PHASES A, B, C AND THE FIREBASE FIX ARE ALL DONE AND LANDED

**Everything measurable says nothing broke.** Read this section; the baseline table below is kept as the
"before" it was captured to be, not as current state.

| | iOS 26.5 runtime | iOS 27.0 runtime |
|---|---|---|
| Suite | **3,011 / 0** (57.9 s) | **3,011 / 0** (90.7 s) |
| Errors | 0 | 0 |
| Emulator cases | 58 / six classes | 58 / six classes |

**Toolchain:** Xcode **27.0 (27A266a)**, Swift **6.4**, iOS **27.0 SDK**, licence accepted.
**Both runtimes installed:** 26.5 (23F77) and 27.0 (24A434). Deployment target **unchanged at 16.0 / 16.1**.
`Package.resolved` verified unchanged on every single run — the SDK was the only variable throughout.

**Landed, newest first:**
- `c5e6e2c` — `OS=` mandatory in destinations + the app runs on iOS 27
- `cd56e71` — **`F-iOS27-C-SDK`**: builds and passes on Swift 6.4. Two test-double lines, **zero app code**
- `cfdb250` — **`F-FirebaseKeychainFix`**: firebase-ios-sdk 12.17.0 → **12.19.1** (silent random sign-outs)
- `4e4ec1c` — the pre-upgrade baseline

**The only thing Swift 6.4 actually broke:** it enforces that an `actor` cannot conform to a
global-actor-isolated protocol. `DailySummaryGenerating` is implicitly `@MainActor` via the app target's
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which broke two gated test doubles.
**⚠ Marking the PROTOCOL `nonisolated` does NOT fix it** — that propagates to conformers and an actor
cannot be `nonisolated` either, so the error just moves. The fix was `final class … @unchecked Sendable`
on the doubles. App-target build warnings went **33 → 37**: +3 `[#IsolatedConformances]`,
+1 `[#ImplicitStrongCapture]`, both new Swift 6.4 diagnostics. Every pre-existing category unchanged.

**⚠ COUNT DISTINCT.** `xcodebuild` prints each warning AND each test case twice, so `grep -c` doubles
both. "70 warnings" was really **33**; "116 emulator cases" was really **58**. Both were wrong in earlier
editions and are corrected. A `test` run's warning count is not comparable to a `build` run's, nor across
incremental builds — only recompiled files emit.

---

## ▶ THE NEXT BLOCK: PHASE D — the 26.5-vs-27.0 visual sweep

**This is the block E actually asked for**, verbatim: *"look for any clashes between the design of the UI
of the top version iOS 26 compared to the new top level which is iOS 27."* Everything else so far has been
the groundwork that makes it possible.

**Both runtimes exist now, so this is a measurement rather than an opinion.** Render the design-sensitive
surfaces on **26.5 and 27.0**, put them side by side, and look.

**Mechanism — establish which works BEFORE building the folder around it.** The Xcode MCP bridge's
`RenderPreview` is preferred but **it is unverified whether it can be pointed at a chosen runtime**, and
note the `xcode` MCP server has been failing to connect this session. The fallback is already in the repo:
`ADHD LifeOSUITests/RenderHarnessUITests.swift`, driven once per `OS=` destination. Say in the README
which one produced the images.

**Point the camera here, in this order:**
1. **`AppTabBar` / `AppTabContent`** — highest risk in the app. `AppTabContent.swift:108` parks hidden tabs
   **10,000 pt off-screen** via `.offset(x:)`, and `CelebrationPopSource.swift:43,57` compensates in
   `.global` coordinates. A custom bar above the safe area plus a global-coordinate hack is exactly what a
   new SwiftUI release disturbs.
2. **Sheets** — `AccountDeletionSection:156`, `CapturePromoteSheet:92`, `NudgesView:300`, plus
   `CelebrationPresentationProbe`, which walks `connectedScenes → keyWindow`. **iOS 27 changed presented-VC
   trait inheritance to walk the superview chain** (release note 170005251) — that is the probe E shipped
   in `F-CTACelebrations-Surfaces` and passed on device, so it is the highest-value regression check.
3. **`.searchable`** — precedent that matters: iOS 26 rendering it as a capsule is *the entire reason the
   bottom-search arc exists* (`Theme/AppSearchScope.swift:11`). This app has been visually broken by an OS
   bump before.
4. **Materials / toolbars**, then **widgets and Live Activities**.

**What the research already settled, so do not re-derive it:**
- **No new Liquid Glass APIs in 27, none deprecated.** The glass was *retuned* though — secondary reporting
  describes darker edges and brighter speculars, plus a new user-facing **Settings → Appearance → Liquid
  Glass** transparency slider. **Whether an iOS-26-SDK binary receives the refreshed material is not stated
  by any primary source — that is what looking settles.**
- **Nothing changed in Reduce Motion, `symbolEffect`, `PhaseAnimator` or `keyframeAnimator`.** §7.2 and the
  celebration ladder are untouched by this release. A clean negative.
- **Nothing found about changed safe-area insets or home-indicator height** — the things that would move
  `AppTabBar`.
- **HIG *Layout* (2026-09-09)** now says use a scroll edge effect rather than a solid background beneath
  controls; the app has **zero** `scrollEdgeEffect` uses. **HIG *Branding* (same date)** says put brand
  colour in the content layer "where it scrolls beneath Liquid Glass controls" — **a direct input to the
  held colour arc.**

**Deliverable:** `screenshots/ios27-compat/` with the mandatory README in the `tag-editor-ui` house style —
environment line, what driving the real screens caught that tests could not, and a table of
**filename → what it proves**, numerically prefixed.

---

## ⏭ AFTER PHASE D

- **Phase F — device.** Install the 27-SDK build while **E's phone is still on 26.4** (proves the new
  binary runs on the old OS), *then* E updates to 27 and it is checked again. E's phone does **not** yet
  carry the Firebase keychain fix.
- **Phase G — adoption.** Candidate list first, E picks, each pick its own FEATURE block. Possibly zero.

## ⚠ STILL OPEN, AND E HAS NOT DECIDED

- **THERE IS NO XCODE 26.6 ROLLBACK.** 27.0 installed over the top at `/Applications`. Less pressing now
  the build is green, but if Phase D or F turns up something ugly there is no way back. ~4 GB to
  re-download.
- **E's phone is HELD at iOS 26.4** with Automatic Updates off — correct until Phase F step 1 is done.
- **Disk: 27 GiB free** after clearing ~27 GB (dev caches, plus Steam and EVE at E's request). No longer a
  constraint, but the internal volume was 96% full and will creep back.

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
