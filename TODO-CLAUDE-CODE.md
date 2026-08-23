# TODO-CLAUDE-CODE.md

*Handoff document: Cowork → Claude Code*
*Project: **ADHD LifeOS (Es_Life_OS mobile)***

**Created:** 2026-07-17
**Status:** Xcode project scaffolded (SwiftUI, XCTest). SwiftLint + 70% coverage bar decided. No architecture doc or FEATURE blocks yet — first Cowork design session pending.

---

## How Claude Code Uses This File

See `WORKFLOW.md` for the full cycle and FEATURE block template. Quick version:

1. Before each work session: read this file top-to-bottom.
2. Pick the next `[ ] UNCHECKED` item under **Current Sprint**.
3. Read the associated docs in `/docs/`.
4. Execute the task step-by-step (TDD, per `claudecode.md`).
5. Mark as `[x] COMPLETED` when done.
6. Commit: `[Feature/Fix] Brief description`.
7. **Stop after one FEATURE block and wait for review** (one clear next action, no batching).

---

## Current Sprint

**Nothing queued, and nothing outstanding on E.** Claude Code is taking direction from E directly
(E's call, 2026-08-23). Cowork adds FEATURE blocks here when it has designed one.

The last item awaiting E — on-device confirmation of the notification-banner app icon — was verified
on 2026-08-23 and is closed below.

**The history moved.** Every shipped block and every block belonging to a deleted backend now lives
in `TODO-ARCHIVE.md` — 8,183 lines of it, covering the Supabase, Cognito/AWS and Poke eras, all of
which were removed from the app in `5244650`. It was moved rather than deleted: the reasoning in
those blocks is often the only record of why something is the way it is, and several carry
verification trails worth keeping. Nothing in the archive is a work item.

---

## FIX: Task Due-Time Nudge notifications show no app icon in the banner  [x] VERIFIED 2026-08-23

**CLOSED — E confirmed on a physical iPhone 15 Pro, 2026-08-23.** The banner now renders the app
icon (purple gradient, white arc-and-dot), matching `AppIcon-1024.png`, so it is the real icon and
not a system fallback.

Verified against a build of `main` installed that day via `devicectl`, specifically so a stale
device build could not produce a false negative — the git history for `AppIcon.appiconset` does not
show the July `sips` commit this block describes, so which build first carried the small renditions
could not be established from history alone. `assetutil --info` on that build's compiled
`Assets.car` reports discrete 60×60, 87×87, 120×120 and 180×180 AppIcon renditions alongside the
1024×1024 marketing icon.

The test went wider than the criterion required. A task due in 6 minutes with 2 countdown nudges
produced three notifications, all showing the icon:

  +2 min     "This task is due soon."   countdown nudge
  +4 min     "This task is due soon."   countdown nudge
  due time   "This task is due now."    due-moment notification

So both notification features are covered, on the lock screen and in Notification Centre. The
original diagnosis holds: the notification-banner icon path needs the classic small renditions,
which the Xcode-14+ single-size format alone does not provide.

---

**Original block follows, unedited apart from the ticked criterion:**


**Context:** Reported 2026-07-21 by E on a physical iPhone — a Task Due-Time Nudge (local
notification) banner displayed with no app icon, while the Home Screen and App Switcher icons
both rendered correctly. Investigated via `assetutil --info` against the compiled `Assets.car`:
`AppIcon.appiconset/Contents.json` used only the modern Xcode-14+ "single size" format (one
1024×1024 marketing image + dark/tinted variants, `idiom: universal`) with zero classic small
icon renditions (20/29/40/60pt). The compiled catalog's `AppIcon` asset showed only a single
1024×1024 "MultiSized Image" entry with no smaller pre-rendered sizes. Home Screen/App Switcher
render fine from this format, but the on-device notification-banner icon path is known to fail
silently without the classic small renditions present in the catalog.

**Fix (additive, no code change):** generated the eight classic iPhone icon sizes (20/29/40/60pt
at @2x/@3x) from the existing `AppIcon-1024.png` via `sips`, and added them to
`Contents.json` as `idiom: iphone` entries alongside the existing `universal` marketing-icon
entries. Confirmed via `assetutil --info` that the rebuilt `Assets.car` now contains discrete
20×20/29×29/40×40/60×60pt renditions (previously only the single 1024×1024 rendition existed).

**Acceptance Criteria:**
- [x] `AppIcon.appiconset` contains classic `idiom: iphone` renditions at 20/29/40/60pt
      (@2x/@3x), generated from the existing 1024px source — no new marketing artwork needed.
- [x] `xcodebuild build` for the physical device succeeds and signs cleanly (no asset-catalog
      compiler errors from mixing `universal` and `iphone` idiom entries in one appiconset).
- [x] Rebuilt app installed and launched on E's physical iPhone via `devicectl` for retest.
- [x] **E confirmed on device 2026-08-23**: icon renders in the banner. See the verification note
      at the top of this block.

**Implementation Checklist:**
- [x] Generate `AppIcon-20@2x.png`, `AppIcon-20@3x.png`, `AppIcon-29@2x.png`,
      `AppIcon-29@3x.png`, `AppIcon-40@2x.png`, `AppIcon-40@3x.png`, `AppIcon-60@2x.png`,
      `AppIcon-60@3x.png` via `sips` from `AppIcon-1024.png`.
- [x] Add corresponding `idiom: iphone` entries to `Contents.json`.
- [x] Run: `swiftlint lint` — no Swift touched, confirmed no new violations.
- [x] Run: `xcodebuild build ...` for the physical device — confirmed signed build succeeds.
- [x] Verify via `assetutil --info` on the compiled `Assets.car` that the small renditions are
      actually present post-build (not just declared in `Contents.json`).
- [x] Install + launch on E's physical iPhone via `devicectl` for on-device retest.

**Dependencies:**
- Needs: nothing (asset-only fix, no Swift/architecture change).
- Blocks: nothing — Task Due-Time Nudges (the feature this bug affects) already shipped;
  this is a visual-polish fix to its notification banner.

**Notes:**
- This is a plausible, well-supported diagnosis (documented real-device behavior difference
  between the single-size and classic app-icon formats specifically for the notification-banner
  icon path) but not 100% confirmed until E sees an actual nudge fire post-fix — flagged as an
  open acceptance criterion above rather than claimed as verified.
- No iPad-idiom small icons were added — the reported bug and E's test device are iPhone-only;
  `TARGETED_DEVICE_FAMILY` includes iPad (`"1,2"`) but the app has no iPad testing history yet,
  so adding iPad icon renditions here would be unrequested scope creep. Revisit if iPad testing
  ever surfaces the same notification-icon gap there.

---

## KNOWN ISSUE: Flaky sign-in UI tests on this machine (LARGELY EXPIRED — read the 2026-08-23 note first)

**Status 2026-08-23: mostly overtaken by events, kept for the diagnosis rather than the task.** The
suite this describes no longer exists. It reports 4 of 10 UI tests failing intermittently; there are
now 4 UI tests in `ADHD_LifeOSUITests` (one a launch-performance measurement), and of the three named
below, two were DELETED in the 2026-08-19 slimming —
`testCreateTask_fromTasksTab_appearsInList` and `testTaskDetail_opensWithTitleFieldPopulated_notBlank`
went with the Supabase credentials they depended on. Both have since been rebuilt against the
Firebase emulator in `SignedInJourneyUITests`, where they pass consistently (four journeys, four
passes, ~90s each).

What is still worth keeping is the DIAGNOSIS: these failures were traced to simulator/host resource
pressure on this specific Mac, not to app code. If UI tests start failing oddly, check
`sysctl vm.swapusage` before blaming a commit — a 2026-08-23 session found swap at 2.5GB of 4GB
while running the Firebase emulator's two JVMs alongside Xcode.

The one item never actioned: the 15s timeouts on the older tests were flagged twice as too short for
this machine. The new journeys use 45s throughout (`UITestSession.timeout`) and have not flaked.

**Original entry follows, unedited:**

### KNOWN ISSUE: Flaky sign-in UI tests on this machine (2 sessions running, unresolved)

**Not a code bug — logged so a future session doesn't re-diagnose it from scratch.** Across two
separate sessions (2026-07-20, 2026-07-21), `xcodebuild test`'s full UI test suite has
intermittently failed 4 of 10 `ADHD_LifeOSUITests` — always at the same point: `loginEmailField`
(or an equally early post-launch element) never appears within its wait timeout (tried up to 45s).
Which 4 tests fail is non-deterministic between runs (e.g. `testLoginForm_...` failed in the
2026-07-21 rerun after passing in the prior run). Unit tests (`ADHD LifeOSTests`, 212/212) are
unaffected and pass every time. Root cause investigated and narrowed to iOS Simulator
network/resource flakiness on this specific Mac (low free RAM + swap pressure at the time of both
failing runs; host-level `curl` to the same Supabase endpoint is consistently fast) — not the
app's sign-in code, not `TaskDetailView`'s `.onAppear` fix (whose regression test,
`testTaskDetail_opensWithTitleFieldPopulated_notBlank`, is one of the intermittently-affected
tests, meaning it has never yet cleanly exercised the code it's meant to verify). Full diagnostic
trail: `git log` for `COWORK-HANDOFF-TaskDetailView-Fix.md`'s content (deleted after triage, see
git history if needed). If this resurfaces: check `vm_stat`/`sysctl vm.swapusage` before blaming
code, and consider whether the 15s timeouts on the 3 older affected tests
(`testCreateTask_fromTasksTab_appearsInList`, `testLoginForm_rendersFieldsAndValidatesInput`,
`testSignIn_invalidCredentials_showsInlineErrorAndStaysOnLoginForm`) are worth bumping to the
file's own 45s convention — flagged twice now, not yet done without E's go-ahead.

---

## RESOLVED: Home's due-nudge dismiss buttons share one accessibility identifier  [x] FIXED 2026-08-23

**Fixed by giving each Dismiss button a per-nudge accessibility LABEL** (`"Dismiss Stretch your
back"`), leaving the identifiers untouched. `testDueNudge_appearsOnHomeAndCanBeDismissed` passes and
is no longer skipped; all four signed-in journeys are green.

The underlying defect is real and REMAINS: `dueNudgesStrip` puts
`.accessibilityIdentifier("homeDueNudgesStrip")` on the enclosing `VStack`, and SwiftUI pushes that
down over the subtree, so every per-nudge `homeDueNudgeDismissButton-<id>` is overwritten and the
buttons cannot be told apart by id. Confirmed from the accessibility tree:

```
Button, 0x113186bc0, {{310.7, 997.0}, {59.3, 20.3}}, identifier: 'homeDueNudgesStrip', label: 'Dismiss'
```

The label fix routes around it and is a genuine VoiceOver improvement in its own right — a row of
buttons all reading "Dismiss" tells a VoiceOver user nothing about which nudge they are acting on,
since the visible label lives in a separate element. The dead per-nudge identifiers are left in
place rather than removed; they cost nothing and document the intent.

**CORRECTION to an earlier claim in this file's history:** an intermediate version of this block
stated that removing the stack's identifier, or adding `.accessibilityElement(children: .contain)`,
CRASHES the app. **That was wrong.** It came from manual `simctl` runs that were confounded three
separate ways — a stale AWS-era build picked out of one of five DerivedData directories, an
unverified sign-in state, and a keychain session that survived `simctl uninstall` so the app was
signed in as a different account than the one being seeded. Nothing here crashes. If you need to
verify app behaviour, drive it through the XCUITest harness, which controls account state, rather
than by hand.

