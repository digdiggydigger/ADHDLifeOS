# Open items register — 2026-09-17 (fifty-fourth edition; **THE LANDSCAPE FAB OVERLAP IS FIXED AND MERGED — `F-LandscapeFabOverlap`, reproduced first, red-checked, passing on 26.5 and 27.0. Owed: E's device verdict on the side-by-side arrangement — the build IS on the phone. The tab-pill inset options are the session's second half.**)

*Close-out of the session that opened the iOS 27 arc on the day iOS 27 shipped, researched it to
primary sources, and captured the pre-upgrade baseline.
Supersedes the forty-five earlier editions. **Everything the forty-fifth recorded still stands** —
nothing in any merged block is owed to E, and the three older device looks are still owed.*

> ## ⏸ EVERYTHING BELOW IS ON HOLD — E's instruction, 2026-09-13
>
> E paused the whole queue to start **a curated colour scheme for the app**: *"can we hold on
> starting any of those above tasks. I would like to create a properly curated & developed colour
> scheme that we will implement throughout the LifeOS application. lets start that planning in a
> fresh claude code terminal session."*
>
> **Nothing in §A, §B or §C should be started, or offered, until E lifts the hold.** Nothing about
> those items changed except priority — they are still accurate and still outstanding. The three
> device looks in §A and the photosensitivity blocker in §D are unaffected as FACTS; they are
> simply not to be chased.
>
> **THE HOLD STANDS, AND E RE-CONFIRMED THE ORDER ON 2026-09-14: iOS 27 FIRST, colour arc still
> held.** Asked directly where iOS 27 sat against it, E chose *"iOS 27 first, colour arc stays
> held"*. There is a real dependency, and the research since has confirmed it: Apple's HIG
> *Branding* page was revised **2026-09-09** to say brand colour belongs *"in the content layer,
> where it scrolls beneath Liquid Glass controls and gets picked up dynamically"*. The curated
> palette should be designed against iOS 27's guidance, not iOS 26's.
>
> The colour arc's opener has moved to **`handoff/archive/START-HERE-colour-scheme.md`** so this
> folder keeps exactly ONE live opener (CLAUDE.md: *"If `handoff/` ever holds two live
> `START-HERE-*` files, one of them is a trap"*). **Nothing about the arc changed — only the
> pointer.** Its measured inventory of the 63 colorsets and the five questions for E are intact in
> the archive, and it gets a fresh opener when E lifts the hold. It is still PLANNING first.

**This file is THE outstanding list.** It is rewritten at every close-out (CLAUDE.md,
"Session handoff"), and whenever E asks what is outstanding, so it is the thing to read and to
update rather than improvising a list in chat.

## State

**Measured 2026-09-17 on `feature/landscape-fab-overlap` @ `11224c9` (Xcode 27.0, iOS 26.5 runtime,
emulator UP, freshly started this session):** suite **3,025 / 0** (3,011 + the 14 tests of
`F-LandscapeFabOverlap`), **0** `127.0.0.1:9099` hits, **58** emulator cases across the six classes,
SwiftLint **0 / 819**, `** BUILD SUCCEEDED **` (**37 distinct warnings**, the Phase C figure, 0 errors),
coverage **27.67% (13,399/48,433)** — numerator +43 on a denominator +76 (the layout file and the
overlay's new lines), i.e. comparable and the new code is covered. `LandscapeAwayCardUITests`
**PASSED on 26.5 light and 27.0 dark** (both sims erased after). `firestore.rules` untouched —
**nothing for E to republish**. **The phone is ON MAIN at `5c322e5`** (Swift identical to `7e85ec6`): E connected it after the
close-out report, and the device build, `devicectl` install and launch all succeeded in one pass
(0 signing tells in the log, `codesign --verify --deep --strict` exit 0, profile valid to
**2026-09-17T19:25:02Z — it expires TONIGHT**, so the app needs a reinstall after that). **The
fix IS on E's phone; the landscape verdict can be given.**

**`main` @ PR #131 — Phase D landed** (`4e4ec1c` was the baseline). Measured for Phase D on
2026-09-15 (Xcode 27.0, iOS 26.5 runtime, emulator UP): suite **3,011 / 0**, **0** `127.0.0.1:9099`
hits, **58** emulator cases across the six classes, SwiftLint **0 / 814** (the sweep harness is the
814th file), `** BUILD SUCCEEDED **`, coverage **27.62% (13,356/48,357)** — bit-identical to Phase C,
as it must be: the block adds a UI-target file and evidence, and no app code. `firestore.rules` untouched — **nothing for E to
republish**. **No app SWIFT code has changed since `598da3b`**; `F-FirebaseKeychainFix` moves a
dependency pin and adds a test, nothing else.

**Measured on the bump (2026-09-15, Xcode 26.6, emulator UP):** suite **3,011 / 0** in 26.3 s
(3,008 baseline + 3 new floor tests), **0** `127.0.0.1:9099` hits, **58** emulator cases across the six
classes, SwiftLint **0 / 813**, `** BUILD SUCCEEDED **` **70 warnings / 0 errors** (identical breakdown
to baseline), coverage **27.56% (13,356/48,454)** — bit-identical, as it must be.

**THE iOS 27 BASELINE — measured 2026-09-14 at `855759c` on Xcode 26.6 / iOS 26.5 SDK, against a
FRESHLY RESTARTED emulator.** This is the discriminator for the whole arc: without it, no
post-upgrade failure is attributable to the SDK rather than to something already broken.
- unit suite **3,008 / 0**, `** TEST SUCCEEDED **`, **49.7 s**, emulator UP, **0** `127.0.0.1:9099` hits;
- **58 emulator-backed cases ran across SIX classes** (not the four CLAUDE.md records — see §F);
- SwiftLint **0 violations, 0 serious, 812 files**;
- sim `** BUILD SUCCEEDED **` — **70 warnings, 0 errors, and ALL SEVENTY ARE CONCURRENCY WARNINGS**
  (13 of them already say *"this is an error in the Swift 6 language mode"*). See §F;
- coverage, app target **27.56% (13,356 / 48,454)** — up from 24.72% (11,114/44,961) on 2026-09-07,
  and **comparable**: the denominator moved because the TREE GREW (380 → 423 Swift files,
  46,978 → 53,093 raw lines), not because the measurement extent changed. Numerator +20.2% against
  a denominator +7.8%, so coverage grew ~2.5× faster than the code;
- **both UI journeys GREEN** (run for `-6`; not re-run for `-Surfaces`, which touches no UI, nor
  for `-Corners`, which changes a shape no UI test asserts);
- **device: ON MAIN at `560d068`, REINSTALLED 2026-09-16 — E's phone is on iOS 27.0 (24A437) and
  the build is running on it.** `** BUILD SUCCEEDED **`, 0 errors, installed and launched via
  `devicectl`; **app (pid 869) AND `FocusTimerWidgetExtension` (pid 843) both running as processes**.
  Bundle `LifeOS 1.3 (1)`, `DTSDKName iphoneos27.0`, `MinimumOSVersion 16.0`.
  **This is the SAME APP CODE as step 1's `b47aad5` build** — `git diff b47aad5..HEAD -- '*.swift'`
  is **0 files**, the only change being this register — so step 2's "same build, re-checked on 27"
  is satisfied exactly. The reinstall was needed only because the erase-and-restore to reach 27
  removed the app; step 1's PASS at 26.4 was observed before that and is unaffected.
  Two mechanics worth keeping: a restored phone has **Developer Mode OFF** and `xcodebuild` fails at
  destination resolution until E enables it; and the **first launch was denied for `Security`
  (untrusted profile) and the immediate RETRY succeeded** — the transient denial already recorded in
  the device-build notes. (Was `b47aad5`, installed 2026-09-15 for step 1; `1920536` from 2026-09-13.) **ALL FOUR blocks have passed on the phone**: `-6`, `-7`,
  `-Surfaces` (*"you can mark a PASS"*) and `-Corners` (*"they look okay"*, with two screenshots
  filed). **Nothing in any merged block is owed to E.**

**The emulator was restarted on E's instruction and it mattered.** The running instance had been up
since **Sun 13 Sep 03:48 — 1 day 19 hours**. E: *"if there's a stale or old emulator running then
I'd suggest closing it and starting a fresh one … purely because it has been running for so long."*
Correct call: a baseline is only worth having if the environment under it is clean. The old one was
on the right project and rules, but the whole point of Phase A is that nothing underneath it is
suspect. Cycled cleanly (SIGTERM to the parent, ports released in 3 s, the Firebase **MCP** left
untouched) and the suite re-run against the fresh one.

### Landed this session

**`F-LandscapeFabOverlap`** (PR #137, `main` @ `7e85ec6`) — see §B's first item: the landscape FAB
overlap, reproduced first, fixed with a `Layout` that keeps the portrait stack byte for byte,
red-checked, passing on 26.5 and 27.0. Owed: E's verdict on the side-by-side look (the build is on the phone).

**The pill-inset options** (this edition) — rendered, not chosen; §B's second item.

**`F-CTACelebrations-6`** — C6–C9: the routine Completed flow wired (PRs #106–#109). See the
forty-first edition's detail; nothing about it is outstanding.

**`F-CTACelebrations-7`** — the chime (PR #110). E's F5, and the block that made a switch true:
"Celebration sounds" had been in Settings since `-3` storing a choice nothing read. Five candidates
went to E as `.wav`, peak-normalised to the same −3.0 dBFS so the comparison was of timbre; E picked
the first ElevenLabs generation by ear and **reserved the second for future use**. (NEW)

**`F-CTACelebrations-Surfaces`** — hold a celebration behind any unknown sheet (PR #112). E's
design call, taken before a line of it was written: asked to choose between a house modifier on all
26 `.sheet`/`.fullScreenCover` presenters and asking UIKit, **E chose asking UIKit**, plus holding
behind alerts / dialogs / system pickers and leaving a pop alone. `KeyWindowPresentationProbe`
walks the key window; `isBlocked` is the single predicate behind the hold and the release; a hold
watch replaces the `onDismiss` an untracked sheet never sends, and R-g is enforced by time rather
than by the next dismissal. **It is a PREVENTIVE block** — the five milestone sites were traced and
none of them can be reached from inside an untracked sheet as the tree stands, so what it closes is
the class rather than a live defect. **PASSED ON DEVICE 2026-09-13** (E: *"you can mark a PASS to
'the celebration hold' checklist item"*). Nothing outstanding. (NEW)

**`F-FocusCard-Corners`** — the collapsed card's bottom corners (PR #116). E's *"Round them"* was
a word, not a number, so the four radii went to E as a render and E chose **24 — "match the top"**
("leave it square after all" was offered and not chosen). `FocusBarCardOutline` now cuts BOTH the
fill and the keyline from one silhouette, so they cannot disagree about where the corner is; the
`Bool` became a `CGFloat` on `animatableData`. **PASSED ON DEVICE 2026-09-13** (E: *"they look
okay"*, two screenshots filed). Nothing outstanding. (NEW)

### What this session established

- **"Owed a device check" and "the code is on E's phone" are DIFFERENT FACTS, and conflating them
  wastes E's time.** Both blocks were reported as owing a device verdict while the phone was still
  on `eade58a`, two PRs behind. E looked, saw nothing, and reported it — *"i cant see any change on
  my iphone"* — about a change that was correct and simply not installed. The `device-build-lag`
  note already said *"after a device-affecting block, push a device build too"*. **Install as part
  of the close-out, and write the SHA the phone carries.**

- **A GREEN test suite can leave the one thing users depend on unproven.** Every test in
  `CelebrationSoundTests` injected `loadAsset`, so none of them touched the asset catalog —
  and `assetutil` on the built `Assets.car` proves the bytes SHIP, not that `NSDataAsset(name:)`
  resolves or that `AVAudioPlayer` accepts them. A dataset can be present and unreadable by name.
  **One test using the DEFAULT loader closes it**, and the test target hosts the app so it costs
  nothing. Generalises past audio: whenever a seam is injected everywhere for testability, ask
  what exercises the REAL implementation. (NEW)
- **Reversing a test is now a three-times-proven habit, and once it was the test NAME that lied.**
  `testTheFeedbackFooterExplainsBothSwitchesAndSaysTheSoundIsNotLiveYet` had the reversed claim in
  its own name. Also loosened — not deleted — a mount guard anchored on `CelebrationCenter()`'s
  empty parentheses, in its ARGUMENTS only, so what it is really about (the App owning the centre)
  stayed pinned. (NEW)
- **Footer prose is checked by no compiler, and it had drifted twice.** The Settings footer said
  the sound switch "does nothing until the chime arrives" AND that the milestone celebrations were
  "still to come" — the second stale since `-4`, nothing to do with this block, and nobody had
  noticed. **When a block touches user-facing copy, read the whole paragraph, not the clause.**
  (NEW)
- **E reserved a rejected candidate, which is a case the "no dead assets" rule does not cover.**
  `05-generated-b` is kept in the evidence folder as `.wav` and a ready-to-ship `.caf`, and
  deliberately NOT in the asset catalog: an asset with no call site is weight in every build. Kept
  where it is findable, added when a site exists. (NEW)
- **The provisioning "fastest check" FALSE-ALARMED** — `defaults read … DVTDeveloperAccountManagerAppleIDLists`
  returned an EMPTY `IDE.Identifiers.Prod` and the device build signed perfectly. On Xcode 26 that
  key is not evidence of anything; run the build and read its LOG. (NEW)
- **GitHub can report a merge as unmerged for the better part of an hour.** PR #109's merge landed
  (`4451326`) while `gh pr merge` returned 502; the PR read `merged=false` through ~40 s of polling
  and two more write attempts failed with 504/GraphQL errors. It reconciled itself later. **Verify
  against `origin/main` — `git merge-base --is-ancestor` — and do not re-run `gh pr merge`**, which
  would have put a second empty merge commit on `main`. (NEW)

## ⓪ · THE iOS 27 ARC — LIVE, and the next move is E's

**Opened 2026-09-14, the day iOS 27 shipped.** E: *"i need to look at updating the LifeOS application up to
the most recent iOS version that was released today - iOS 27. This must be done safely to ensure that nothing
breaks."* Plan: `/Users/ethan/.claude/plans/okay-claude-i-need-melodic-origami.md`.
Opener: **`handoff/START-HERE-ios27.md`** — the single live opener.

**E's three decisions, 2026-09-14:**
1. **Phone holds at iOS 26.4**, Automatic Updates off, until Xcode 27 is installed.
2. **Scope = move to the 27 SDK AND prove nothing broke AND adopt worthwhile 27 APIs** behind `#available`
   with complete iOS 16 floors. **The 16.0 deployment target does not move.**
3. **iOS 27 first; the colour arc stays held.**

- [x] **Phase A — the baseline. DONE 2026-09-14.** Figures in "State" above. This is the discriminator for
      every later phase. (NEW)
- [ ] **⛔ Phase B — THE GATE, and it is E's. Nothing from Phase C on can start until this is done.**
      - **Automatic Updates OFF on the phone; hold at 26.4.** (E has been asked.)
      - **Free the boot volume — it had 12.2 GB.** `~/Library/Developer/CoreSimulator/Devices` is **11 GB**
        and regenerates safely. `iOS DeviceSupport` is 5.5 GB but is **entirely E's phone at 26.4**.
      - **Xcode 27 onto `/Volumes/Es-SSD`** — E's instruction, and it works for the `.xip` and the app.
        **BUT the iOS 27 simulator runtime (~8 GB) CANNOT go there**: runtimes are MobileAsset cryptex disk
        images under `/System/Library/AssetsV2/`, on the system volume, with no supported relocation. That
        8 GB of boot volume is unavoidable. **This is the one place E's instruction cannot be followed
        literally, and E has been told.**
      - **Keep Xcode 26.6 as `Xcode-26.6.app` — the rollback.** Switch with `DEVELOPER_DIR`, never
        `xcode-select`.
      - **DO NOT delete the iOS 26.5 runtime** (7.9 GB, deletable): Phase D needs both runtimes.
      - **`brew upgrade swiftlint`** — 0.65.0 may not parse Swift 6.4.
      - **Optional, and it will never be cheaper:** the older simulator runtime §A has wanted since
        2026-09-11 is the same Components screen. (NEW)
- [x] **Phase C — build on the 27 SDK. DONE 2026-09-15 (`F-iOS27-C-SDK`).**
      **The app compiles and the whole suite passes under Xcode 27.0 / Swift 6.4 / iOS 27.0 SDK**, run on
      the iOS 26.5 runtime (target is 16.0, so the 27 runtime is not needed for this and is deliberately
      not installed — it is a Phase D need). `Package.resolved` verified **unchanged** on every run, so
      the SDK was the only variable.

      **Exactly TWO compile errors, both in TEST DOUBLES, none in app code.** `DailySummaryGenerating`
      is implicitly `@MainActor` because the app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
      and **Swift 6.4 began enforcing that an `actor` cannot conform to a global-actor-isolated
      protocol** — which broke `GatedDailySummaryGenerator` and `GatedFailingDailySummaryGenerator`.

      **A wrong turn worth recording, because it looks right: marking the PROTOCOL `nonisolated` does
      not fix it.** That propagates `nonisolated` to conformers, and an actor cannot be `nonisolated`
      either — the error simply moves. Reverted; app code ended up untouched. The fix is the two doubles
      becoming `final class … @unchecked Sendable`, following `ToggleableDailySummaryGenerator` ten lines
      below them in the same file. **Nothing is lost semantically:** the mid-flight hold is the `Gate`
      actor's doing, not the generator's own isolation, so `generate` still suspends and "generating"
      remains a state a test can stand in.

      **App-target build warnings: 33 → 37, and the +4 is two NEW Swift 6.4 diagnostics**, not decay.
      Every pre-existing category is unchanged to the count (14, 8, 5, 2, 2, 1, 1). The new ones are
      **3 × `[#IsolatedConformances]`** and **1 × `[#ImplicitStrongCapture]`**.
      ⚠ **Count DISTINCT warnings.** The "70" in the forty-sixth edition was a raw `grep -c`; the log
      repeats each warning, and the distinct figure was always 33. Same doubling trap as the emulator
      count — both are now corrected. A `test` run's warning count is NOT comparable to a `build` run's,
      and neither is comparable across incremental builds, since only recompiled files emit.

      Suite **3,011 / 0** in 57.9 s · **58** emulator cases across the six classes · **0**
      `127.0.0.1:9099` hits · SwiftLint **0 / 813** · `** BUILD SUCCEEDED **`, 0 errors · coverage
      **27.62% (13,356/48,357)** — numerator BIT-IDENTICAL; the denominator moved 48,454 → 48,357 with
      no source change, i.e. Swift 6.4 attributes executable lines slightly differently. (NEW, CLOSED)

- [ ] ~~Phase C~~ — superseded above. Still outstanding from its trap list:
      **add an explicit `,OS=` to CLAUDE.md's documented destinations**, which becomes load-bearing the
      moment the iOS 27 runtime is installed and two `iPhone 17 Pro` sims exist. (NEW) Traps enumerated in the opener. The load-bearing ones: decline
      "update to recommended settings"; keep `SWIFT_VERSION = 5.0`; **first build on the committed
      `Package.resolved`, unchanged, then `git diff` it**; add explicit `,OS=` to every destination and
      update CLAUDE.md's Commands section. (NEW)
- [x] **THE APP RUNS ON iOS 27.0 — verified 2026-09-15.** Not merely built against the SDK: the full
      suite executed on the **iOS 27.0 (24A434)** runtime. **3,011 / 0**, 0 errors, 58 emulator cases,
      0 `127.0.0.1:9099` hits, `Package.resolved` unchanged. Both runtimes are now green:
      **26.5 → 3,011/0 (57.9 s)** and **27.0 → 3,011/0 (90.7 s)**. (NEW)

- [x] **The iOS 27 runtime is INSTALLED, and the failure on the way in is worth keeping.** Xcode's
      Components download sat on "Preparing…" all night: **it was DISK**, not a network or Xcode fault.
      "Preparing" is the decompression step, the boot volume had 8.4 GB, and the asset needs ~7.5 GB plus
      room to expand — **Xcode does not error in that state, it spins indefinitely.** After freeing space
      the download completed but then reported ***"Failed — Registering simulator runtime with
      CoreSimulator failed."***, **caused by me `pkill`ing a parallel `xcodebuild -downloadPlatform` when
      E's GUI download started.** Recovery needed no re-download: the asset was intact at
      `/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/<hash>.asset/AssetData/Restore/*.dmg`
      and `xcrun simctl runtime add <dmg>` registered it, **at zero disk cost** — same volume, so simctl
      cloned rather than copied (27 GiB free before and after). **Do not run two runtime downloads at
      once**, and if registration fails, re-add the local image rather than re-downloading. (NEW)

- [x] **Disk: 8.4 GiB → 35 GiB free** (2026-09-15). The internal Data volume was **96% full** — this was
      never an Xcode problem. Dev caches took it to 15 GiB (`iOS DeviceSupport` 5.5 GB, swiftpm 619 MB,
      Homebrew 614 MB — all regenerate); **E then asked for Steam (11 GB) and EVE Online (9.3 GB) to be
      deleted**, which was safe on inspection: Steam's `userdata` was **196 KB** and its 10 GB was six
      re-downloadable games, EVE's 9.3 GB was **entirely `SharedCache`**. (NEW)

- [x] **Phase D — the 26.5-vs-27.0 UI sweep. DONE 2026-09-15.** Evidence in
      `screenshots/ios27-compat/` (52 frames, 26 composites, 2 zooms, README with the per-band
      measurement). Thirteen surfaces × two runtimes × two appearances, the SAME binary, driven by
      `IOS27CompatSweepUITests` (committed deliberately — it is the re-runnable camera for Phase F
      and every 27.x point release). **Answer to E's question: nothing the app draws moved.**
      - **The custom tab bar is pixel-identical** — bottom band **0.00 %** on all ten plain-tab
        frames, both modes. The audit's highest-risk surface is closed.
      - **iOS 27 retunes SHEET CHROME**: bottom corners rounded and inset, a thin dark edge, on every
        sheet (promote, Settings, New nudge at both detents). Content inside unchanged.
      - **Glass capsules retuned, visible in DARK**: sheet-toolbar Cancel/Save are lighter and edged
        on 27.0. System controls, consistent with iOS 27 — **an input to the held colour arc**, not a
        defect.
      - `confirmationDialog` is a **popover on both runtimes** (no Cancel element in either tree);
        27.0 places it above the row rather than beside it.
      - The bottom search row is unchanged; frame 02's delta is iOS 27's first-run QuickPath tip
        pane where 26.5 shows the keyboard. The `.searchable` precedent did not repeat.
      - One text delta in 52 frames (the schedule summary line, dark, ~30 % dimmer on 27.0) carries
        an opacity transition and is recorded as an observation, not a finding.
      - **NOT covered: widgets and Live Activities** — see the bridge item below. Owed to Phase F.
      (NEW, CLOSED)
- [ ] **The Xcode bridge's `RenderPreview` cannot be pointed at a chosen runtime — established, not
      assumed.** The scheme was switched to `iPhone 17 Pro (26.5)` and confirmed active; the preview
      launched on `iPhone 18 Pro` (27.0) regardless — **the preview canvas picks its own device**. Both
      27.0 attempts then failed on launch timeouts (`AppLaunchTimeoutError` 15 s; then
      `CHSErrorDomain 1051 timelineReloadTimeout` for the widget extension) on this 8 GB machine with
      Xcode, the emulator and a simulator all resident. So the widget and Live Activity previews were
      NOT rendered on either runtime. **Phase F covers it on the phone**; if a sim render is wanted
      first, the route is the home-screen widget gallery driven through the simulator, not the bridge.
      (NEW)
- [ ] **Phase E — Firebase.** See the bump item below; the proof is the six emulator classes still passing.
- [ ] **Phase F — device, IN PROGRESS. Step 1 DONE 2026-09-15: the 27-SDK build is ON THE PHONE at
      iOS 26.4.** `main` @ `b47aad5` built for `wishwashwacky15` (iPhone 15 Pro, iOS 26.4 / 23E246)
      with `-allowProvisioningUpdates` (both profiles re-issued), installed and launched via
      `devicectl`; the app AND the widget extension were running as processes afterwards. The bundle
      is stamped `DTSDKName iphoneos27.0`, `MinimumOSVersion 16.0` (widget 16.1). **This is the first
      27-SDK binary on the phone, and the first build on the phone that carries the Firebase keychain
      fix** — compiled from the 12.19.1 checkout (`AuthKeychainServices.swift` has
      `isKeychainAccessible` ×3; `Package.resolved` unchanged). Note the embedded Firebase version
      string reads `12.19.0`: Firebase did not bump its core constant for the .1 patch, so the SOURCE
      is the proof, not the string. **E's look at 26.4 PASSED, 2026-09-16** (E: *"your most recent install to my iphone works
      correctly throughout the app"*) — the 27-SDK binary runs on the old OS, the floor-side half of
      the compatibility claim. **STEP 2's PRECONDITION IS MET, 2026-09-16: the phone is on iOS 27.0 (24A437)**, updated through
      the MacBook as planned. **What changed is the shape of step 2.** Getting there required an
      erase-and-restore, so the 27-SDK build is **no longer on the phone** — step 2 is a REINSTALL of
      the same `main` build followed by the device look, NOT the "re-checked on 27 without a
      reinstall" this item originally planned. **THE REINSTALL IS DONE (2026-09-16) and E's LOOK IS DONE the same evening.** `560d068` ran on
      the phone at iOS 27.0, app and widget extension both. **E's verdict: the app is correct** —
      *"LifeOS looks to be working correctly. The live activity & home screen widgets look to be
      working."* That closes the two biggest Phase D asks (**widgets and Live Activities on 27**,
      never rendered on 27 anywhere before) and the **sheet chrome**, which E photographed in both
      modes: iOS 27's lighter, edged toolbar capsules are confirmed on a physical display, content
      inside unchanged, system behaviour rather than a defect. Evidence:
      `screenshots/ios27-device-findings/` (5 files + README with the measurements).
      **The look also surfaced TWO NEW items, neither of them an iOS 27 regression — see §B.**
      Still unlooked-at from the Phase D list: **the schedule summary line's dimness in dark**. Nothing about the app or the compatibility claim changed. Note also the phone now has
      **~92 GB free** where storage was previously very limited, so the constraint that shaped step 2
      is gone. (NEW)
      Original brief: install the 27-SDK build while the phone is STILL on 26.4
      (proves the new binary runs on the old OS), then E updates to 27 and it is checked again. The
      device look now carries three specific asks from Phase D: **the Focus Live Activity and the
      Home Screen widgets on iOS 27** (never rendered on 27 anywhere yet), **the retuned sheet chrome
      and dark-mode capsules on a physical display**, and the schedule summary line's dimness in dark.
      E's phone does not yet carry the Firebase keychain fix either. (NEW)
- [ ] **Phase G — adoption.** Candidate list first, E picks, **each pick is its own FEATURE block** that
      stops for review. Possibly zero. §7.1's filter governs and `apple:modernize` does not skip the gate. (NEW)

### ⚠ THE ONE ITEM HERE THAT IS A REAL USER-FACING BUG, NOT MIGRATION WORK

- [x] **DONE 2026-09-15 (`F-FirebaseKeychainFix`). Bumped firebase-ios-sdk 12.17.0 → 12.19.1 — it fixes silent random sign-outs.**
      **Verified the FIX ITSELF is in the source we compile, not just the version string:**
      `AuthKeychainServices.swift` in the resolved checkout has `isKeychainAccessible()` at :265, called
      at :60 and :189, with the `errSecInteractionNotAllowed` remap at :65 and :194. Version numbers are a
      proxy; this is the thing.
      **Clean bump — suite 3,011/0 (3,008 + the 3 new floor tests), all 58 emulator cases across the six
      classes still pass, SwiftLint 0/813, BUILD SUCCEEDED with 70 warnings — byte-identical breakdown to
      the baseline — and app coverage bit-identical at 27.56% (13,356/48,454), which is exactly right
      because no app code changed.** Four packages moved: firebase 12.17.0 → 12.19.1 (LINKED) plus three
      transitive pins that are **not linked into any target** (googleappmeasurement, googleutilities,
      google-ads-on-device-conversion). **The prebuilt binaries did not move at all** — abseil, grpc,
      leveldb, nanopb, promises were already the newest that exist, as the research predicted.
      `FirebaseSDKVersionFloorTests` now pins the floor in BOTH places — the resolved version and the
      pbxproj `minimumVersion`, which was raised 12.0.0 → 12.19.1 so a clean resolve or a fresh clone
      cannot legally land below the fix. Red-checked before the bump: both assertions failed on 12.17.0.
      (NEW, CLOSED)

      ~~The original entry, kept because it is the reasoning:~~
      [PR #16505](https://github.com/firebase/firebase-ios-sdk/pull/16505): a known iOS 15+ bug where
      `SecItemCopyMatching` returns `errSecItemNotFound` instead of `errSecInteractionNotAllowed` on a locked
      device; FirebaseAuth trusted it and wiped the user. Reporters measured **~1% of recently active users**
      losing their session. **This app is maximally exposed**: it restores sessions with a single
      `Auth.auth().currentUser` read (`FirebaseAuthClientAdapter.swift:29` → `FirebaseManager.swift:97`) and
      has **no `addStateDidChangeListener` fallback**, so a spurious `nil` drops straight to `.signedOut`.
      **Skip 12.18.0** (app-extension `UIApplication.shared` regression, reversed in 12.19.0).
      **This is independent of iOS 27 and worth doing regardless.** (NEW)

### Facts the arc turned up that are NOT its scope

- [ ] **`UIApplication.canOpenURL` is deprecated in iOS 27** (release note 179874781). Used at
      `Places/PlaceAppInstallVerification.swift:91`; the app-directory "installed" badge and its **45
      `LSApplicationQueriesSchemes`** rest on it. Apple's advice — *"attempt to open the URL and handle any
      failure instead"* — **does not preserve the feature**, because the badge must answer "is it installed"
      *without* launching anything. It sits behind a one-method seam (`:83`) so the code blast radius is one
      function, but **what the badge becomes is a design question for E.** Not urgent: deprecated, not
      removed. (NEW)
- [ ] **No `PrivacyInfo.xcprivacy` anywhere in the project**, while the app links three SDKs on Apple's
      third-party-requirements list (`FirebaseAuth`, `FirebaseCore`, `FirebaseFirestore`) plus five listed
      transitive binaries, and uses `UserDefaults` — a required-reason API — via the App Group. **A
      submission blocker at launch**, not an iOS 27 one. Belongs with §D. (NEW)
- [ ] **The gRPC XCFramework slices are unsigned on disk** (`codesign -dvv` → *"code object is not signed at
      all"*) and gRPC is on Apple's signature-required list. **Current state under Xcode 26 too — not new**,
      but it had never been written down. (NEW)
- [ ] **`Home/FirebaseDailySummaryGenerator.swift:77,127` bypasses the adapter seam**, calling `Auth.auth()`
      and the callback `getIDToken` directly — the exact pattern `AuthBackingStore.swift:10-13` records as
      removed elsewhere because "nothing could stub it". The only Auth consumer outside `Firebase/`. (NEW)

### Corrections to CLAUDE.md this session earned

- **"The four extensions the emulator harness covers" — there are SIX.** `FirebaseManagerRoutineRunsTests`
  and `FirebaseManagerNudgeCompletionTests` joined and were never added. All six ran in the baseline
  (58 cases). (NEW)
- **`PlaceMapPicker.swift:15` says "the 40-odd `#available` gates"; the real count is 28** code sites (plus
  68 `@available` declarations, zero `#unavailable`). (NEW)
- **`ModernAPIPolicyCallSiteTests.swift:13-14` claims every other iOS 17 gate is an `if` with no `else`.**
  `VoiceCaptureRecorder.swift:74` is an iOS 17 gate **with** a full `else`. (NEW)
- **CLAUDE.md records the app target's deployment target as 16.0 only**; the widget is **16.1**, and the
  file's §7 does say so elsewhere — but the "Architecture notes" bullet does not. (NEW)

## A · Decisions only E can make — minutes each

**Every device check on the CTA-CELEBRATIONS ARC and the FOCUS CARD is clear** — E settled four at
the sitting on 2026-09-12/13, then `-6`'s and `-7`'s verdicts, then `-Surfaces`' and `-Corners`' on
2026-09-13 once the phone was finally carrying them.

**"Nothing in any merged block is waiting on E" was written here and it was TOO STRONG — corrected
2026-09-13.** Three earlier follow-on blocks (`SwipeOrigin`, `NoCooldown`, `PopScale`) still owe
device looks; they are landed, green and installed, and the first of them replaces a defect E
themselves reported, so it is the one with a known "before". The honest statement is: **nothing in
the last four blocks is owed; three older ones still are, and none is urgent.**

- [x] **`F-CTACelebrations-Surfaces`' DEVICE PASS — PASSED 2026-09-13.** E, on `main @ 1920536`:
      ***"you can mark a PASS to 'the celebration hold' checklist item"***. **Nothing in the block
      is outstanding.** The note below is kept because it is the reasoning, not the task:

      ~~**read what it is FOR before running it, because the obvious version of this check cannot
      fire.**~~ All five milestone sites were
      traced: `inboxZero`'s three doors, `streakSeven`'s "Done for now", `dailyGoal`'s ring and
      `routineFinished` are reachable only from `.root` or from the two tracked surfaces, and
      **Quick Capture creates captures rather than clearing them** — so as the tree stands today
      there is no user action that fires a milestone from inside an untracked sheet. **The block is
      preventive, not a fix for a demonstrable bug**: it closes the class (every future sheet, plus
      alerts, dialogs and iOS's own interruptions such as "Save Password?") and the composition
      test is its proof.
      **So the device check is the REGRESSION one, and it is two minutes.** Get the capture inbox
      down to one waiting capture, open it, **Create Task**, promote. Inbox zero should celebrate
      **immediately** as the sheet closes, exactly as it did before. That path is the one
      `releaseHeldIfClear` now gates on the probe, it is shipped and E-verified from
      `F-CTACelebrations-5`, and it is the only place this block could have made something worse.
      **No RM-on pass is owed** (§7.3): no `#available` site and no Reduce Motion site is added or
      changed, so the reduced path cannot look different either way. (NEW)

- [x] **`F-FocusCard-Corners`' DEVICE VERDICT — PASSED 2026-09-13.** E: ***"they look okay"***,
      with two device screenshots filed as
      `screenshots/focus-card-bottom-corners/02-device-collapsed-light.jpeg` and
      `03-device-collapsed-dark.jpeg` — the shipped 24pt corner on real glass, light and dark.
      **Nothing in the block is outstanding.** The note below is kept as the reasoning:

      ~~a look rather than a test.~~ Start a sprint, collapse the card, and look at where its bottom
      corners meet the tab bar; then expand it again. E chose 24pt from a simulator render
      (`screenshots/focus-card-bottom-corners/`), and what a render cannot show is how the notch
      between card and bar reads on glass at arm's length. **No RM-on pass is owed** (§7.3): no
      `#available` site is added, and the only Reduce Motion interaction is the existing collapse
      animation, untouched. (NEW)

- [x] **`F-CTACelebrations-7`'s DEVICE VERDICT — PASSED, 2026-09-13, both checks.** E, verbatim:
      ***"both work correctly"*** — the chime plays UNDER music without pausing it
      (`.mixWithOthers`) and stays silent with the ring switch off (`.ambient`). Neither is
      provable on the simulator. **Nothing in the block is outstanding.** (CLOSED)
      - **E reserved the runner-up sound** for use elsewhere: *"keep a hold of the sound 'el-b'
        ... there is likely other locations that [it] Could be used."* Kept at
        `screenshots/cta-celebrations-block-7/candidates/05-generated-b.{wav,caf}`, deliberately
        out of the asset catalog until a real site exists. **This is a standing item for whoever
        adds the next sound** — do not regenerate one. (NEW)


- [x] **`F-CTACelebrations-6`'s DEVICE VERDICT — PASSED, 2026-09-13, BOTH passes.** Installed at
      `4b0f0ad` (build, install, launch clean in one wireless pass). E, verbatim: ***"both work
      correctly"***, answering an ask that enumerated the two checks separately — Reduce Motion OFF
      (Close leaves the card, it reads "Finish routine", reopening offers Completed, the
      congratulation over a real fetch, a step ROW closes it) and then Reduce Motion ON. **So
      §7.3's RM-on pass is EARNED for this block**, and its Verified-paths line reads *"Reduced: run
      on sim (injected) + E's phone (RM on)"* — the second time in this arc that line is earned
      rather than owed. **Nothing in the block is outstanding.** (CLOSED)
      - **Shipped but NOT approved, and worth knowing:** under `.spring` the checklist scales down
        to 0.9 as the congratulation scales in. The plan specified the entrance only; the symmetric
        exit was the implementer's call, was flagged to E in the same message, and drew no comment
        either way. Overrulable. (NEW)

- [ ] **DEVICE CHECK OWED on the three follow-on blocks, whenever E is next on the phone.** All
      three are landed, green and installed from `main`; none is urgent, and E has already passed
      everything that came before them.
      - **The swipe's pop** (`SwipeOrigin`) — swipe a task closed and confirm the paper now leaves
        from the finger rather than off the right-hand edge. **This is the one that replaces a
        defect E reported**, so it is the only check with a known "before".
      - **The overlap** (`NoCooldown`) — clear the last capture and cross the daily goal close
        together; two full-screen celebrations now OVERLAP rather than the second being downgraded.
        That is the direct consequence of removing the cooldown and it is E's decision; it is worth
        a look only to confirm it does not read badly.
      - **Reduce Motion ON** (`PopScale`) — the still pop's scatter scaled 48 → 76.8 pt with the
        pop, so §7.3 owes it one RM-on look. Until then that block's Verified-paths line reads
        *"Reduced: run on sim; NOT on device."* (NEW)
- [ ] **PHOTOSENSITIVITY — E POSTPONED this on 2026-09-13, and asked in the same breath that it be
      brought back before public launch.** E, verbatim: *"Can we postpone this decision for later
      date? But we must come back to this before shipping to the public."*
      **So this is now a LAUNCH BLOCKER by E's own instruction, not an open polish item** — it is
      listed in §D as well, and neither entry may be closed without E.
      The finding, unchanged: the stack-clearing Confirm's 14 shells flash **5 times inside one
      second** (from ≈ 2.00 s) against **WCAG 2.3.1's threshold of 3**. Each flash is a radial
      gradient growing 40 → 240 pt at up to 0.35 alpha over 0.35 s. **Unmeasured:** whether the
      luminance delta and screen area also cross the guideline — the flash COUNT alone is what
      crosses. There is no app-readable API for iOS's "Dim Flashing Lights", so it cannot be gated
      in code. The finding does NOT extend to the pops or the milestones (both re-confirmed).
      The options remain: measure the luminance properly, thin the two clusters, or accept it with
      eyes open. (DEFERRED BY E, carried to §D)
- [ ] **Install an older simulator runtime** via Xcode → Settings → Components. E, 2026-09-11:
      *"In a number of days in the future, I will install this."* Until then every `#available`
      fallback is compile-only by policy (§7.3). (carried)
- [ ] **Optional, still not decided: an `.accessibilityHint` on the Celebration sounds row only.**
      (carried)
- [x] **THE DEVICE SITTING — DONE 2026-09-12, and BOTH blocks PASSED with Reduce Motion OFF *and*
      ON.** E, verbatim: *"both of those tests work correctly!"*, confirmed when asked precisely
      about RM. So `F-CTACelebrations-4` and `-5` are verified on device and **both blocks'
      Verified-paths lines read "Reduced: run on sim (injected) + E's phone (RM on)"** — the first
      time in this arc that line is earned rather than owed. (CLOSED)
- [x] **The milestone cooldown — E REMOVED IT ENTIRELY, 2026-09-13.** Verbatim: *"Remove the
      cooldown entirely."* It was E's own 5 s testing value from the start, so this closes the
      question rather than reversing a settled answer. Shipped in `F-CTACelebrations-NoCooldown`;
      the consequence to watch on device is the overlap, above. (CLOSED)
- [x] **The VoiceOver announcement on the streak — E: leave as shipped, 2026-09-13.** E was told
      that the premise behind the original answer was wrong (the nudge card VANISHES on dismissal,
      so day seven leaves nothing on screen that distinguishes it) and chose to keep the shipped
      behaviour anyway: the daily goal announces, the other two do not. **Decided with the correct
      facts in hand, which is what the re-ask was for.** (CLOSED)
- [x] **Whether the Celebrations switch should also gate pops — E: leave as shipped, 2026-09-13.**
      So the switch covers full-screen celebrations only, the Settings footer continues to say so,
      and a user wanting zero decorative motion has Reduce Motion (which stills the pop rather than
      removing it). Raised by the `apple:hig-reviewer` pass; E has now ruled. (CLOSED)
- [x] **An accessibility announcement for the milestones** — E chose "the daily goal only",
      2026-09-12, re-confirmed 2026-09-13 on corrected facts. (CLOSED)
- [x] **How does the reduced path get DEVICE time now that E runs with Reduce Motion OFF?** —
      **E chose (a), 2026-09-12**, written into CLAUDE.md §7.3. (CLOSED)

## B · Real work, ready to start — recommended order

- [x] ~~**🐞 THE LANDSCAPE FAB OVERLAP — a REAL user-facing bug, found on device 2026-09-16.**~~
      **FIXED AND MERGED 2026-09-17 — `F-LandscapeFabOverlap`.** The hypothesis the last session
      recorded was right in kind and wrong in one word: the bottom stack does not overflow the
      landscape screen, it FILLS it — 372 (safe height) − 100 (lift) − 186 (away card) − 8 − 60 puts
      the disc's top at **18pt**, inside the header's gear well; the expanded sprint card alone
      (148) leaves 56, eight points clear, which is why neither landscape nor the card alone ever
      showed it. **Reproduced BEFORE a line was written**: `LandscapeAwayCardUITests` raises the
      away card through the app's own UserDefaults key (argument domain, no production seam) and
      failed at its landscape assertion on the unfixed tree with the portrait control passing;
      the simulator printed the same sum to the point (381 − 100 − 196.7 − 8 − 60 = 17.3).
      **The fix keeps E's stack byte for byte in portrait.** In compact height with anything up
      the cards take the column BESIDE the disc row (`RootBottomOverlayLayout.arrangement`); the
      container is a `Layout` whose arrangement is a property — a `switch` between a `VStack` and
      an `HStack` would have re-identified the timer bar and dismissed its detail sheet on
      rotation. RED 25 compile errors → GREEN 14 / 0 → red-check exactly the 3 predicted
      call-site failures plus the journey's landscape failure → restored → PASS on 26.5 light and
      27.0 dark. Evidence: `screenshots/landscape-fab-overlap/` (host-side `simctl` frames;
      `app.screenshot()` lies on a rotated sim). **Owed: E's device verdict on the side-by-side
      arrangement** — the card bottom-left, the disc in its corner — **— the build IS on the phone
      (installed after the close-out report).** No RM-on pass owed (no reduced site touched). (CLOSED as
      a bug; verdict owed)

- [ ] **The selected tab pill's left inset — RENDERED 2026-09-17, E's pick is the only thing
      outstanding.** `screenshots/tabbar-pill-inset-options/`: the REAL `AppTabBar` at
      `floatingPaddingHorizontal` **4 (current) / 8 / 12 / 16**, Today and Tools selected, light and
      dark, rendered at E's 393pt via a temporary `ImageRenderer` probe (constant and probe both
      reverted; the bar file untouched). Measured insets 4.3 / 8.3 / 12.0 / 16.0pt. Two facts for the
      pick: **12 is off §2's grid** (ships only as a named waiver with a pinning test, the `peekStep`
      shape); **16 breaks §3's SE floor** — the unselected slot falls to 43.0pt and
      `testRestingSlots_clearTheTouchTargetFloorBesideTheWidestPillOnTheSE` fails unless `maximumRestingPillWidth` drops ≥5pt
      with it. The scrolled chip inherits the same padding. **Nothing else on the bar moves.** Once
      E says a number it is a one-constant block with one test. (RENDERED; pick owed)

~~**00. THE CTA CELEBRATIONS ARC — `F-CTACelebrations-6` is BUILT TO C5 ON A BRANCH.**~~
   **THE WHOLE ARC IS FINISHED — corrected 2026-09-13, and this entry was badly stale.** It still
   described `-6` as half-built on a branch and pointed at
   `handoff/START-HERE-cta-celebrations-6-part2.md`, which has been ARCHIVED for days; C6–C9, `-7`
   and `-Surfaces` have all landed and all passed on device since. Anyone following it would have
   gone looking for a branch that no longer exists.
   **Every block is merged:** `F-ConfirmCelebration-2` → `-1` → `-2` → `-3` → `-4` → `-5` → `-6`
   → `-7` (the chime) → `F-CTACelebrations-Surfaces`, plus `PopScale`, `NoCooldown`, `SwipeOrigin`.
   The design record — permanent, never archive — is
   `handoff/SESSION-OPENER-cta-celebrations-design.md`. **Nothing in the arc is work any more**;
   what survives it is the three device looks in §A and the photosensitivity blocker in §D.
   (CLOSED)

~~**0b. Two surfaces question, raised by the HIG pass and NOT closed.**~~ **ANSWERED BY E,
   2026-09-13 — and it is now a BLOCK, not a question.** Offered "add Quick Capture only", "hold
   behind any unknown sheet", "accept it and close the item" or "defer and ask again", E chose
   **hold a full-screen celebration behind ANY unknown sheet**. Written up as
   **`F-CTACelebrations-Surfaces`** in `TODO-CLAUDE-CODE.md`. **BUILT AND MERGED 2026-09-13**
   (`a472f28`, PR #112). The design question it flagged was settled with E FIRST, as the spec
   demanded: two options put to them with catches, misses, cost and what keeps each honest, and E
   chose the UIKit probe. R-g applies unchanged in substance, and is now enforced by time rather
   than by a dismissal that an untracked sheet never sends. **Nothing is outstanding here but E's
   device pass.** (CLOSED as a question; CLOSED as a block bar the verdict)

**0c. The daily-goal announcement is an INTERRUPT, and nothing here has been checked on a real
   VoiceOver device.** `UIAccessibility.post(notification: .announcement,)` speaks over whatever
   VoiceOver is reading, and it can fire on any tab about a second after an unrelated action; a
   second accessibility notification landing in the same beat can coalesce one away. Neither effect
   is provable from source. Worth folding into the next VoiceOver pass rather than a block of its
   own. A 17+ attributed-string announcement API with a priority option may exist in the 26.5 SDK —
   unverified — which would make this a §7.1 register candidate. (NEW)

**0d. Follow-ups to the modern-iOS pilot — only what E asks for.** (carried)
   - **RM arrival fade for the bottom furniture**, only if E likes the cross-fade.
   - **The modern-API inventory, register-only until each is a block.**
     - **Free at 16.0:** `.contentTransition(.numericText(countsDown: true))` on the sprint
       countdown and ~20 `.monospacedDigit()` counters; `.presentationBackground` (16.4) on three
       sheets.
     - **Needs 17:** `ContentUnavailableView` in four empty states;
       `.contentTransition(.symbolEffect(.replace))`; interactive widgets and routine Live Activity
       check-off; the `@Observable` migration (now 28 classes); TipKit.
     - **Needs 18/26:** `Tab`/`.tabBarMinimizeBehavior` and `.glassEffect`, both constrained by the
       custom `AppTabBar` (adoption means replacing it).
   - **Two RM sites that remove the press affordance entirely** (`AppTabBar.swift:266`,
     `AppSearchRow.swift:71`), and `RootView.swift`'s declared-but-unread `reduceMotion`.

1. ~~**E's one un-run device check: airplane mode + pull-to-refresh on Home.**~~ **RUN AND PASSED
   2026-09-13** — E: *"Airplane mode ON check has been run and was successful."* Home keeps the
   last-known task set rather than emptying it, which is what `F-HomeTasksLastKnown` (`8b5f740`)
   exists to do. **Nothing is outstanding here.** (CLOSED)

2. ~~**`F-FocusCard-Corners` — after the arc (E: "Round them").**~~ **BUILT AND MERGED 2026-09-13**
   (`598da3b`, PR #116). E chose **24pt, "match the top"** from a four-way render. Note for anyone
   reading the old line: the `animatableData` half is DONE and is currently **inert**, because
   E's radius equals the expanded one — the snap is gone because the difference is gone. That is
   recorded in the code rather than glossed. **Nothing outstanding but the device verdict** (§A).
   (CLOSED)

3. **`AppFeedback.hapticsEnabled()` and `.notificationSound()` have no test that calls them.** Two
   small tests, no production change. (carried)

4. **Two more dead design tokens, and two dead helpers.** `BarSurface` is defined, unit-tested and
   used by nothing; `AppTabBarPresentation.slotWidth` / `restingSlotWidth` have ZERO production call
   sites and disagree about their input. (carried)
5. **Accuracy-aware containment for the arrival card — ONLY if E still sees drops.** (carried)
6. **Arc 2 — first-class routines + the "at a time" trigger.** (carried)
7. **`F-Search-3-Journal`** — recommendation is still to kill the block. (carried)
8. **The Live Activity design review** E parked. (carried)

## C · Parked on E's instruction — do not start unprompted

- **A nudge-specific screen animation for EVERY "Done for now".** E, 2026-09-11. (carried)
- **14- and 21-day streak milestones** (R-b): the arc fires at exactly 7. (carried)
- **Places backgrounding dismiss bug** — waiting on E's iOS update. (carried)
- **App connections** — real two-way sync; Apple Notes has no iOS API. (carried)
- **LA interactive buttons**, **time-of-day triggers**, **smart skip**. (carried)
- **`OfflineSprintSummaryCard`** — E ruled it out of the focus-card arc explicitly. (carried)

## C2 · Noticed, below the bar — **E asked explicitly that these be KEPT, 2026-09-13**

*E, verbatim: "Don't forget Your flagged points, So we can come back to them later." So nothing in
this section is dropped for age, and none of it may be quietly closed as stale. Each is something
this session or an earlier one noticed and judged below the bar for its own block — not something
that was tried and dismissed.*


- **A fully-ticked routine that is never confirmed will be recorded as `dayEnded`, not
  `completed`.** Found while planning `-6`. An arrival run stays live until **end of day**
  (`RoutineRun.swift:96-102`) and `RoutineRunReconciliation` then stamps `.dayEnded` /
  `.windowLapsed` (`:40-42`), so R1's *"Completed can be tapped later"* has a deadline: midnight.
  Tick every step, swipe away, come back tomorrow — the Journal shows a lapsed run. **This is
  exactly what E asked for** (*"nothing is recorded as completed without the tap"*), so it is
  intended rather than a defect, but E has not seen it stated. (NEW)
- **A shared constant reaches more sites than the block that changes it.** The swipe's pop went
  off-screen because `PopScale` moved a throw distance that a DIFFERENT block had built an origin
  decision around. Fixed in `F-CTACelebrations-SwipeOrigin`, but the shape recurs: the next time a
  celebration constant moves, re-read every site that constant reaches rather than trusting the
  suite. (NEW)
- **The daily goal is the one celebration the user did not just cause with their thumb.** Raised by
  the HIG pass. Inbox zero and the streak both fire from a tap, so a wash starting under the thumb
  is no surprise; the daily goal can land about a second after ANY action, anywhere — including
  while typing in a task's notes. Hit-testing passes through, so nothing is blocked, but it is a
  real cost of E's "any tab" design (F7) rather than a defect. Worth naming at the device sitting.
  (NEW)
- **Eight of the ten pop sites are OPTIMISTIC** — they pop before the work is known to have
  succeeded. Each fires in the same closure and at the same instant as the haptic that was already
  there. The one worth a second look is **Sorted from the triage card**, where the
  `await service.sort(...)` genuinely can return false. **The three milestones are NOT optimistic**
  — each is asked for only after its write landed, which is why a failed sort celebrates nothing.
  (updated)
- **The promote sheet's celebration layer is sized to the SHEET, not the screen**, so the Create
  Task pop clips at the sheet's top edge. By design, and visible for 0.45 s (R-e). (carried)
- **Under Reduce Motion the closure card's `withAnimation(.default)` also animates the SIBLING
  sections reflowing beneath it.** A REDUCED-path effect, so E's passing verdicts did not see it.
  **The RM-on pass this sitting owes is the natural moment to look.** (carried)
- **The Feedback section's footer is a thirteen-line paragraph** covering six switches. (carried)

## D · Launch blockers — no conversation opened yet

- **Free dev account** → 7-day profiles; the current one is valid to **2026-09-17**. When a device
  install fails on it, E re-signs in Xcode → Settings → Accounts. (carried)
- **Sign in with Apple** built but dormant. (carried)
- **Photosensitivity: the stack-clearing Confirm's fireworks flash 5 times in one second** against
  WCAG 2.3.1's 3. **E POSTPONED the decision on 2026-09-13 and asked in the same breath that it come
  back before launch** — verbatim: *"Can we postpone this decision for later date? But we must come
  back to this before shipping to the public."* So it sits here by E's own instruction rather than
  by anyone's judgement, and **it may not be closed without E**. Full detail, and what is and is not
  claimed, in §A. The finding does not extend to the pops or the milestones. (DEFERRED BY E)

## E · Known, not work

- **`MILESTONE_PROBE_OUT` passed on the `xcodebuild` command line does NOT reach the test process.**
  It is taken as a build setting, and the probe falls back to `NSTemporaryDirectory()` — the
  simulator's own app-container `tmp`. Not a failure: the probe prints the path it actually wrote
  to, and the files are copied out afterwards. **Read the printed path rather than assuming the
  environment variable landed.** (NEW)
- **The `xcode` MCP bridge was NOT USED this session**, as the opener instructed; the
  run-loop-pumping probe did everything needed. (carried)
- **A stale `TestResults.xcresult` fails the whole suite before a test runs.** Gitignored, so it
  survives everything; delete it as part of the run. It was present at session start again.
  (carried)
- **A green suite cannot see a `View`'s appearance, a TIMING WINDOW, or a COORDINATE.** This block
  added the third: the fallback pop's origin was correct, its request was correct, and it was drawn
  faithfully at a point 10,000 pt off screen. Render, render the CONTROL, and prove the harness
  deterministic before any pixel claim — then ask what the numbers in the picture MEAN. (updated)
- **`Executed N tests, with M failures` counts failed ASSERTIONS, not failing TESTS.** Predict in
  both, and treat a MISS as a possible defect in the guards rather than a bad forecast — this
  session's two misses were exactly that. (carried)
- **SwiftLint's ceilings bite in two places now.** The 400-line FILE ceiling
  (`CaptureInboxService.swift` 397 → 355 this block; `PlaceRoutineScreen.swift` 384 is next), and
  the 250-line TYPE BODY ceiling, which `CelebrationCenterTests` crossed — split to
  `CelebrationCenterHeldBurstTests` on the `CaptureInboxTriageServiceTests` precedent. (updated)
- **Moving an extension to a new file ends same-file `private` access.** `replaceCapture` could not
  follow its two callers out of `CaptureInboxService.swift` — it writes `state`, whose
  `private(set)` setter keeps every writer in the type's own file — so it was relaxed to internal
  instead. (updated)
- **A UI-target run poisons the simulator; erase it before the next unit run**
  (`xcrun simctl erase 9181EBF9-0F54-4A4D-A19C-19945D1BF155`). No UI target was run this session.
  (carried)
