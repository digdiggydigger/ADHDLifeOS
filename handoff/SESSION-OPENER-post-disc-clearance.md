# Session opener — post reboot, post F-DiscClearance

Read `claudecode.md`, `CLAUDE.md` and the memory index first. The previous opener
(`SESSION-OPENER-post-account-name.md`) is **CLOSED** — its one real defect (the FAB overlapping
the nudges door's last row) shipped as F-DiscClearance, and `CaptureDiscMetrics.clearance` is no
longer an unused helper.

**The open-items list is no longer in this file.** It lives in `OPEN-ITEMS-REGISTER.md` beside this
one — twelve ranked items plus parked and bookkeeping, each with its evidence and what clears it.
Presentation copy: https://claude.ai/code/artifact/869693fa-400c-4e62-b830-01e1f12138c0
Read the register; this opener only carries state, the post-reboot steps, and the lessons.

## State

- **`main` at `b62aea4`**, clean, `origin/main` matches. Four commits on 2026-08-29.
- **Unit suite 1,846 / 0.** Nine UI journey tests, **9/9 green** (was 7 — F-DiscClearance added two).
- **Lint is ZERO, not two.** Both standing debts cleared: `TaskDetailView` was split (439 → 179,
  with `TaskDetailFormSections.swift` at 270), and the UITests `static_over_final_class` is gone.
  **Hold that line — zero is the new baseline.**
- **The two login tests in `ADHD_LifeOSUITests` fail in a full UI-target run and are NOT a
  regression** — see register item 5. Journeys are the number that counts.

## Do these first, before any build

The machine was rebooted to break a swap/disk feedback loop: swap had grown to **9 GB across nine
swapfiles**, on the same APFS container as the free space, while the volume sat at **97% (6.7 GB
free)**. That loop — pressure → swap grows → disk shrinks → swap cannot grow → `Cannot allocate
memory` — killed one test run outright and wedged two builds on 2026-08-29.

1. **Re-measure rather than trusting the numbers above.** The reboot should have returned ~8 GB:
   ```
   diskutil info /System/Volumes/Data | grep -i "container free"
   sysctl vm.swapusage
   ls -lh /System/Volumes/VM/swapfile* | wc -l      # expect 1, not 9
   ```
2. **Then clear the two Xcode caches — E's call, nothing deleted without it.** ~12.2 GB, both
   regenerable, and there are no Archives so nothing shipped is at risk:
   ```
   rm -rf ~/Library/Developer/Xcode/UserData/Previews                        # 6.7 GB
   rm -rf ~/Library/Developer/Xcode/"iOS DeviceSupport"/"iPhone16,1 26.4 (23E246)"  # 5.5 GB
   ```
   The second is E's own phone's symbol cache — it makes the next device install slower **once**.
   Do it anyway; a slow install beats a failed one.
3. **Restart the Firebase emulator** — it does not survive a reboot, and every journey skips
   silently without it (`./scripts/emulators.sh`, leave it in a second terminal). Confirm
   9099 / 8080 / 9199 are up before running journeys.
4. **The simulator will be shut down.** `xcrun simctl list devices available` — this machine has
   only the iPhone 17 family on iOS 26.5.

## Three lessons that cost real time on 2026-08-29

1. **Red-check every geometry assertion.** The new UI journey **passed against a build with the fix
   deliberately removed** — the screen never filled, so the row sat 420pt from the disc and the
   assertion could not fire whatever the code did. Seed enough content to SCROLL, trace frames on
   PASS as well as failure, and prove the test fails before trusting that it passes.
   See [[geometry-journey-vacuity]].

2. **Never run two `xcodebuild`s at once, and never trust `| tail` for an exit code.** The second
   build wedges at `CreateBuildDescription` on the DerivedData lock; a run that has FINISHED
   testing can still hang in coverage post-processing (`build.db` is 426 MB); and a killed build
   reported `exited with code 0` beside `** BUILD INTERRUPTED **`. Redirect to a log and echo `$?`
   separately. See [[build-machine-limits]].

3. **Below the fold is not "unhittable", it is ABSENT.** In a `LazyVStack`, `waitForExistence`
   burns its full 45s on a row that does not exist yet. This bit twice in one journey, both times
   with a true-but-misleading message ("the nudges door never opened", about a door that had).
   Scroll it into being first, and never use the row you are measuring as the arrival landmark.

## Recommended next block

**Register item 5 — isolate the two login UI tests.** Cheapest thing on the list, entirely
self-contained, and compounding: while it is broken every full UI run reports two failures that
have to be manually discounted, which is exactly how a real failure eventually gets waved through.
The cause is proven, not guessed — Firebase Auth persists its session in the simulator keychain and
those two tests only `app.launch()` without the `signOutIfSignedIn` the journeys use. After
`xcrun simctl keychain booted reset` both pass (27.2s / 25.1s).

Everything else near the top of the register needs E rather than Claude Code: the device install
(item 3), the four nudges-door stills (item 4), the Firebase console check (item 6).

## Not yet seen on a real screen

The lifted night surround (`78053ce`), the journal row's mood placement (`e7c5b7c`), the Settings
name editor (`5cca6a5`) — all installed at `a943988` — **and now F-DiscClearance itself**, which is
four commits ahead of the device. The block fixed a defect E reported *from the device*, so that
install is the natural close, and it unblocks the other three at the same time.

Renders from the simulator are in `ADHDLifeOS/screenshots/disc-clearance-block/` (Today, the nudges
screen, the task-detail Form, and the Journal as an untouched control) — but the simulator is not
the device, and the standing lesson is that three colour attempts were rejected on device before a
render loop existed.
