# Test Coverage Analysis — ADHD LifeOS

**Date:** 2026-08-21
**Method:** static analysis of the Swift sources against the XCTest target (declared-type and
call-site cross-reference), plus target-membership inspection of `project.pbxproj`.

> **Caveat, stated up front:** this analysis was run in a Linux container with no Xcode, so
> `xcodebuild test` / `xcrun xccov` could **not** be run and no fresh coverage percentage was
> measured. Every claim below is derived from source and project structure, not from an
> `.xcresult`. The "~19% overall" figure quoted throughout is `CLAUDE.md`'s own recorded number
> from the Firebase cutover, not something re-measured here. Re-run the documented coverage
> command on the Mac to confirm the deltas before treating any percentage as current.

---

## 1. Baseline

| | Files | LOC |
|---|---|---|
| App target (`ADHD LifeOS/`) | 158 | 18,350 |
| Widget extension (`FocusTimerWidget/`) | 9 | 1,514 |
| Unit tests (`ADHD LifeOSTests/`) | 106 | 12,556 |
| UI tests (`ADHD LifeOSUITests/`) | 2 | — |
| Cloud Functions (`functions/`) | 3 | — |

**815 unit test methods.** That is not a thin suite — and the shape of it matters more than the
number. The pure-logic layer of this app is genuinely well covered: essentially every
`*Service`, `*Validation`, `*Presentation`, `*Scheduling`, and analytics namespace has a
dedicated test file, and the `Fake*ClientAdapting` fixtures (18 of them) show the
seam-and-fake discipline is real, not aspirational.

So the headline "~19% coverage" is misleading as a quality signal. The uncovered 80% is not
evenly smeared across the app — it is concentrated in **three structural blocks**, and only one
of them is a testing-effort problem. The other two are architecture and tooling problems that no
amount of test-writing will fix.

---

## 2. The three blocks of uncovered code

### Block A — The Firebase persistence layer (19 files, 1,720 LOC, zero tests)

This is the single largest gap and the one `CLAUDE.md` already names. What the static analysis
adds is *why* it can't be closed by writing tests:

```swift
final class FirebaseManager {
    static let shared = FirebaseManager()
    private init() { ... }          // ← no way to construct one in a test
}

struct FirebaseCaptureClientAdapter: CaptureClientAdapting {
    private let manager: FirebaseManager
    init(manager: FirebaseManager = .shared) { ... }   // ← concrete type, not a protocol
}
```

Every one of the 12 `Firebase*ClientAdapter` structs depends on a **concrete singleton with a
private initialiser**. There is no seam. A test cannot inject a fake, cannot construct a real
one, and cannot intercept the network (`MockURLProtocol` doesn't apply — Firestore's transport
isn't `URLSession`). These files are not *untested*; they are currently *untestable*.

This is conspicuous because it's the **only** place in the codebase where the seam stops. Every
other backend edge is a protocol (`CaptureClientAdapting`, `HomeClientAdapting`,
`TasksClientAdapting`, …), and even `FocusWidgetSnapshotStore` takes an injectable
`UserDefaults?` so its App-Group behaviour — including the no-container case — is fully tested.
The house pattern exists; Firebase is the exception to it.

**What's hiding in there that is worth testing.** This is not all thin pass-through. Real,
consequential logic lives in `FirebaseManager` and its extensions, and a silent bug in any of it
is data loss:

- **`FirebaseManager.setNullable`** — the tri-state delta encoder (`nil` = untouched,
  `.some(nil)` = clear via `FieldValue.delete()`, value = write). It is shared by *both*
  `updateTask` and `updateNudge`. Get it wrong in one direction and edits silently don't save;
  wrong in the other and fields get wiped. Zero tests.
- **The field-map builders** — `updateTask`, `updateCapture`, `updateNudge` each hand-build a
  `[String: Any]` mapping domain payloads onto snake_case Firestore keys. Every one of those
  string literals (`"life_area_id"`, `"due_date"`, `"nudges_count"`, and note `updateCapture`
  uses camelCase `"lifeAreaId"` while everything around it is snake_case) is an unverified wire
  contract. A typo is a field that silently never writes.
- **`markCaptureProcessed` / `updateCapture`'s `processed`/`status` pairing** — two fields that
  must always move together or the inbox filter desynchronises from the status badge.
- **`FirebaseManager+Seed`** — `seedLifeAreas()`, `seedTags()`, `seedTasks(...)`,
  `seedWelcomeLog()` are **pure static factories**, plus a two-layer idempotency rule
  (`seeded_at` marker *and* an "already has life areas" guard) whose entire purpose is to never
  double-seed or re-seed an existing account. Testable today with no emulator at all.
- **`FirebaseManager+Tags.removeTagEverywhere`** — computes the final `tag_ids` array
  client-side for merge (replace) vs delete (drop), including the "don't duplicate the
  replacement" case. Pure array logic wrapped in a batch call.
- **`tagUsageCounts`** — parses `tag_ids` across two collections, skipping malformed UUIDs.
- **`Collection.allCases`** — account deletion cascades over this. The comment says "a new
  collection added here is automatically included in the wipe." Nothing tests that claim, and
  App Store 5.1.1(v) compliance rests on it.
- **`deleteAllDocuments`'s 500-write batch chunking** — an off-by-one leaves documents behind
  on any collection ≥ 501 docs.

### Block B — The widget extension target (6 files, ~1,000 LOC, structurally unreachable)

`project.pbxproj` shows `FocusTimerWidget/` shares exactly **three** files into the app target:

```
membershipExceptions = (
    FocusActivityAttributes.swift,
    FocusSprintIntents.swift,
    FocusWidgetSnapshot.swift,
);
```

Everything else — `FocusStatsWidget` (356 LOC), `FocusTimerWidgetLiveActivity` (237),
`FocusActivityComponents` (188), `FocusSprintWidgetSection` (130), `FocusStatsTimeline` (52),
`FocusTimerWidgetBundle` (15) — belongs only to `FocusTimerWidgetExtension`, and **there is no
test target for that extension**. The unit test target hosts the app, so it cannot see these
files at all. They are not merely untested; they are uncoverable by construction, and they drag
the overall percentage down without that meaning anything actionable.

Of the three shared files, `FocusWidgetSnapshot` is well covered (12 tests) and
`FocusActivityAttributes` has content-state tests — but **`FocusSprintIntents` has zero**,
despite being testable right now (see §3).

### Block C — SwiftUI view bodies (32 view files)

Expected and largely fine. The project has consistently extracted decision logic *out* of views
into tested pure types (`CaptureRowPresentation`, `TagEditorPresentation`,
`FocusSprintPresentation`, `TaskDetailDirtyState`, `SwipeAction`, `LifeAreaReorderPayload`),
which is the right answer. This block is not where I'd spend effort — with the exceptions noted
in §3.

---

## 3. Proposed improvements, ranked

### P1 — Put a protocol seam in front of `FirebaseManager`

**Why first:** it is the prerequisite for testing 1,720 LOC, it is a one-time refactor, and it
restores the pattern the rest of the codebase already follows. Nothing else on this list unlocks
as much.

Extract a `FirebaseManaging` protocol carrying the ~40 methods the adapters actually call, have
`FirebaseManager` conform, and change the adapters' initialisers from
`init(manager: FirebaseManager = .shared)` to `init(manager: FirebaseManaging = FirebaseManager.shared)`.
No behaviour changes; the diff is mechanical. The 12 adapters then become testable with a
`FakeFirebaseManaging` exactly like every other feature's `Fake*ClientAdapting`, and the
adapter-level behaviour that currently has no verification at all becomes reachable:
`FirebaseCaptureClientAdapter`'s newest-first sort, its upload→createCapture ordering,
`FirebaseRemindersClientAdapter`'s error → `RemindersServiceError.fetchFailed` mapping,
`FirebaseAccountDeletionAdapter`'s `requiresRecentLogin` distinction.

**Caveat worth surfacing before committing to it:** the protocol is wide (~40 methods) and the
fake will be sizeable. An alternative is to test the manager against the **Firestore emulator**
instead — the repo already has `firebase.json`, `firestore.rules`, and the functions codebase
uses the emulator idiom. That is the higher-fidelity option (it would also test the security
rules, which nothing does today) but it needs `firebase-tools` on the Mac and an emulator
harness in the test target's setup. The two are complementary, not exclusive: the protocol seam
covers adapter logic cheaply and runs in the normal suite; the emulator covers the wire contract
and rules. **My recommendation is the protocol seam first** (fast, no new tooling, no CI
dependency), emulator second if the wire-contract risk in §P2 turns out to bite.

### P2 — Extract and test the pure logic already inside `FirebaseManager` — no seam required

Several of the highest-risk pieces need **no** refactor of the singleton at all, only that they
be lifted out of the network-calling methods into pure statics:

1. **`setNullable`** is already `static` and nearly pure — test it directly today. Three cases
   per field × the shared task/nudge usage.
2. **Field-map builders**: change `updateTask(id:payload:)` to call
   `static func taskUpdateFields(_ payload: TaskUpdatePayload) -> [String: Any]`, and the same
   for captures and nudges. The static is pure, the method becomes two lines, and every
   snake_case wire key becomes an assertion. This is the cheapest defence against the silent
   field-name class of bug, which is the most dangerous one in a schemaless store.
3. **Seed content**: `seedLifeAreas()` / `seedTags()` / `seedTasks(...)` / `seedWelcomeLog()`
   are pure statics **right now**. Assert the six areas, five tags, the `Health`/`Growth`
   lookups the task seeding depends on by *name string*, and the pre-tagged task's `quick-win`
   link. Those name lookups are silent-nil-on-rename hazards.
4. **`removeTagEverywhere`'s array computation** — extract
   `static func rewrite(_ ids: [String], removing:, replacingWith:) -> [String]`.
5. **`Collection.allCases`** — a single test asserting the set of raw values, so adding a
   collection without adding it to deletion fails a test rather than shipping an
   App-Store-compliance hole.

This is a substantial coverage gain for genuinely small, low-risk diffs, and it is
TDD-compatible in the way `CLAUDE.md` requires.

### P3 — Test `FocusSprintIntents` (testable today, zero tests)

These are the Lock Screen / Live Activity Pause and Stop buttons. The logic is a real branch
with a real failure mode:

```swift
if let pauseResume = await FocusSprintIntentActions.pauseResume {
    await pauseResume()
} else {
    await FocusActivityAttributes.endAllActivities()   // cold-launch orphan cleanup
}
```

The file is compiled into the app target, so the test target can see it. `FocusSprintIntentActions`
is a settable `@MainActor` static — trivially injectable. Worth covering: the hook fires when
installed; the fallback path is taken when nil (the cold-launched-app case, which is exactly the
scenario that's hardest to reproduce by hand on-device); and the hooks are actually installed by
`FocusSessionService.withLiveActivityMirroring`. Small file, high user-visible consequence if it
regresses — a dead Pause button on the Lock Screen.

### P4 — Add a widget-extension test target, or move the logic out

Block B is currently a permanent drag on the coverage number for no diagnostic value. Two
options:

- **Preferred, cheap:** treat the extension as pure presentation and move any remaining decision
  logic into `FocusWidgetSnapshot` (already shared and well tested). Then accept the extension's
  view code as untestable, the same way app view bodies are — and **exclude the extension from
  the coverage report** so the headline number describes code that could actually be tested.
- **Heavier:** add a `FocusTimerWidgetTests` target. Justified only if `FocusStatsTimeline`'s
  timeline-entry generation (`getTimeline`, `getSnapshot`) is judged worth pinning — it is the
  one piece of real logic in the block.

Either way, the coverage bar should be stated against a defined denominator. Right now "19%"
silently includes ~1,000 LOC that no test could ever reach and ~4,000 LOC of view bodies the
project has deliberately chosen not to test.

### P5 — Wire the test suite into CI

**There is no `.github/workflows/` directory.** 815 tests, a lint config, and a build — all of
which run only when someone remembers to run them locally, on one Mac. `CLAUDE.md` compensates
with a strict manual close-out ritual (paste real terminal output, verify the push landed),
which is a good discipline but is a human check standing in for an automated one.

Two concrete gaps this already causes:

- **`functions/` tests are invisible.** `functions/test/` has 21 tests (`capture.test.js`,
  `handler.test.js`) run via `npm test`, and `CLAUDE.md`'s command block doesn't mention them at
  all. They are not part of anyone's definition of "the suite passes." *(In this container 20
  pass and `handler.test.js` fails only because `functions/node_modules` isn't installed — a
  missing-dependency artefact of this environment, not a code defect. But nothing anywhere would
  have told you either way.)*
- **Dead test infrastructure.** `ADHD LifeOSTests/MockURLProtocol.swift` is referenced by no
  test — a leftover from the AWS/`URLSession` era that survived the Firebase cutover. Harmless,
  but symptomatic: nothing sweeps the test target.

A GitHub Actions workflow on a macOS runner (`swiftlint lint` → `xcodebuild test` →
`cd functions && npm ci && npm test`) makes the standard `CLAUDE.md` already sets *enforceable*
rather than remembered. This is arguably higher leverage than any individual test on this list,
because it protects all 815 that already exist.

### P6 — Broaden the UI test suite (lower priority)

`ADHD LifeOSUITests` has 2 real tests, both on the login form, plus a launch-performance test —
and the whole target is `-skip-testing`'d in the standard run. Given the app is feature-complete
and running on a physical device, the highest-value additions would be the flows where unit
tests structurally can't reach: capture → triage → promote-to-task, and start-sprint → Live
Activity. But these are slow, need a booted simulator and live network, and would be the first
thing to go flaky in CI. Worth doing **after** P1–P5, and worth keeping on a separate
deliberately-invoked CI job rather than the per-commit one.

---

## 4. Summary

| # | Proposal | Effort | Unlocks |
|---|---|---|---|
| P1 | `FirebaseManaging` protocol seam | Medium | ~1,720 LOC becomes testable |
| P2 | Extract pure logic from `FirebaseManager` | Small | Wire contracts, seeding, deletion cascade |
| P3 | `FocusSprintIntents` tests | Small | Lock Screen controls |
| P4 | Widget target decision + coverage denominator | Small–Medium | Honest coverage number |
| P5 | CI workflow | Small | Protects the 815 tests that exist |
| P6 | UI test breadth | Large | End-to-end flows |

The most important framing: **this codebase does not have a testing-discipline problem.** The
pure-logic layer is thoroughly and thoughtfully tested, and the seam-and-fake architecture is
consistently applied. It has one architectural exception (the Firebase singleton), one
structural artefact (an untestable widget target inflating the denominator), and no automation.
P1 + P2 + P5 address all three, and would move the real number substantially without writing a
single low-value test.
