# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

**Feature-complete native port (as of 2026-08-19), running on E's physical iPhone.** The React
prototype (`src/`, reference-only) is fully ported to SwiftUI on Firebase: Home (Active Goal hero,
life-area grid + reorder, daily summary, focus analytics), Tasks (swipeable cards, search/sort,
detail with focus-sprint planner), Capture inbox triage, Journal, Nudges, Settings (incl. account
deletion), auth (email/password live; Sign in with Apple built but dormant — free dev account),
and the app-wide focus timer with per-task sprint config, plus a design-token layer mirroring the
prototype palette. **The unchecked items in `TODO-CLAUDE-CODE.md` predate the Firebase cutover and
are stale** — treat direct instructions from E as the work queue until Cowork writes new blocks.

## Workflow: Cowork ↔ Claude Code

This project is split across two tools with strict ownership boundaries. Full cycle detail (FEATURE block template, file ownership table, anti-patterns) lives in `WORKFLOW.md` — read it alongside this file.

- **Cowork (Desktop app)** — design phase. Writes `/docs/*.md` (architecture, data models, API/Supabase mapping, wireframes) and adds FEATURE blocks to `TODO-CLAUDE-CODE.md`. Never writes Swift.
- **Claude Code (this CLI)** — build phase. Reads `/docs/` and `TODO-CLAUDE-CODE.md`, implements via TDD, and only updates checkboxes in `TODO-CLAUDE-CODE.md`.

Full role definition lives in `claudecode.md` — read it at the start of a session, it is reference-only and should never be edited. Do not write to any file under `/docs/` — those are Cowork-owned.

**Start of session checklist:**
1. Read `claudecode.md` for role definition.
2. Read `WORKFLOW.md` if this is a new/unfamiliar session.
3. Read `/docs/ARCHITECTURE.md` for context.
4. Read `TODO-CLAUDE-CODE.md` and pick the next `[ ] UNCHECKED` item under "Current Sprint".
5. Implement test-first, then mark the item `[x] COMPLETED` when done.
6. If blocked, add a `[BLOCKED]` comment inline in `TODO-CLAUDE-CODE.md` explaining what's unclear, and stop — don't guess at unspecified acceptance criteria.

Once a TODO item (a full FEATURE block) is completed, stop and wait for user review rather than proceeding to the next item unprompted. Unless specifically stated by Ethan to bypass.

## Commands

```bash
brew install swiftlint   # one-time manual setup — E runs this, not Claude Code
xcodebuild -resolvePackageDependencies -project "ADHD LifeOS.xcodeproj"

swiftlint lint            # lint check, no errors allowed

xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:"ADHD LifeOSUITests" \
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult   # coverage report
```

UI tests are skipped in the standard run — they are credential-free and compile on a fresh clone,
but need a booted simulator and live network; run them deliberately, not per-block.

```bash

xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Test destination note (2026-07-30):** this machine has only the iPhone 17 family on iOS 26.5
installed — there is no iPhone 15 Pro simulator, so the previously documented destination was not
runnable. If `xcodebuild` reports the destination is unavailable, run
`xcrun simctl list devices available` and use an installed device rather than guessing.

A feature isn't done until `swiftlint lint`, the full test suite, and the build all pass — and the
real terminal output has been pasted for review, not just a "done" summary.

**Coverage reality (2026-08-23, re-measured):** overall coverage is **25.35% (5,272/20,794)**
over 1,168 tests. **The previously recorded "33.55%" was wrong** — a baseline run of the untouched
tree at `4c8b282` (1,099 tests, the exact suite that figure described) measures **23.40%
(4,853/20,735)** with the documented command. Both runs share a denominator, so they measured the
same thing and the older number simply cannot be reproduced. Don't restore it; re-measure instead.

The Firebase layer is now the best-covered part of the app, not the worst. Every Firebase-backed
type sits behind a per-feature `*BackingStore` protocol with a recording fake, and all twelve
`Firebase*ClientAdapter` structs plus `FirebaseAccountDeletionAdapter`, `FirebaseFocusSessionAdapter`
and `FirebaseDailySummaryDataAdapter` are covered (92–100% each). `grep "private let manager:
FirebaseManager"` returning nothing is the check that the seam is still complete — the last three
types above do NOT carry the `*ClientAdapter` suffix, so a name-based sweep misses them.

`FirebaseManager`'s own four extensions are covered too, as of the emulator harness below:
`+Tags` 97.30%, `+Seed` 98.29%, `+Storage` 95.83%, `+AccountDeletion` 90.20% — each previously ~0%.

What is still uncovered, and why the 70% bar stays out of reach for now:
- **SwiftUI view bodies (~7,000 lines at ~0%)** — `TaskDetailView`, `FocusTimerBar`,
  `TaskListView`, `CaptureInboxView` and peers. Unit tests are the wrong tool; this is UI-test
  territory, and the UI tests are deliberately skipped in the standard run.

## Firebase emulator (integration tests for `FirebaseManager`'s own extensions)

`FirebaseManager+Seed`, `+Tags`, `+AccountDeletion` and `+Storage` make real Firestore/Auth/Storage
calls, so they are tested against the **Emulator Suite** rather than a fake:

```bash
./scripts/emulators.sh    # leave running in a second terminal
```

Then run the suite as normal. **With the emulator down these tests SKIP, never fail** — the standard
run stays green on a machine that has never started it.

- **firebase-tools 15.x needs Java 21+**, not the "Java 11+" earlier notes claimed. Homebrew keeps
  JDKs keg-only, so `java -version` reporting 1.8 tells you nothing about what is installed;
  `scripts/emulators.sh` sets `JAVA_HOME` to `/opt/homebrew/opt/openjdk@21` itself. Do **not**
  `brew link openjdk@21` — that changes the machine's default Java for everything else.
- The emulator loads `firestore.rules` and `storage.rules`, so these tests exercise the **real
  security rules**. A rules regression fails them — which is the cheapest rules check available,
  given publishing is manual and E-only.
- **Safety, and it is the reason the harness is shaped the way it is.** `deleteAllUserData()`
  erases every document its signed-in user owns; aimed at the live project by accident it would do
  that to E's real account. So: `FirebaseEmulatorSettings` turns emulator mode on ONLY for an
  explicit, well-formed `LIFEOS_FIREBASE_EMULATOR_HOST` and resolves anything malformed to *off*
  rather than falling back to a default; the shared scheme sets that variable on the **Test action
  only** (`shouldUseLaunchSchemeArgsEnv = "NO"`, so running the app is unaffected); and
  `FirebaseEmulatorHarness.requireEmulator()` **fails loudly** if the emulator is reachable but the
  app is not pointed at it — the one state where tests could otherwise touch production.
- **Trap:** Firestore's `useEmulator(withHost:port:)` sets only the *host* — read `FIRFirestore.mm`,
  it does not disable TLS. The client then speaks TLS to a plaintext emulator and retries forever
  with `WRONG_VERSION_NUMBER`, which reads like a broken install rather than a client bug. So
  `FirebaseManager+Emulator` sets `host`, `isSSLEnabled = false` and `MemoryCacheSettings()`
  explicitly. Auth and Storage's same-named methods DO handle their own transport.

The operative rule is unchanged: every piece of NEW pure logic ships with tests written first (TDD
below), and no block may claim the 70% bar is met.

## Version Control

Repo: https://github.com/digdiggydigger/ADHDLifeOS (private, branch `main`).

To guarantee no work is ever lost:
- Commit after every completed FEATURE block (the same moment you mark it `[x] COMPLETED` in `TODO-CLAUDE-CODE.md`), before waiting for review.
- Push to `origin/main` immediately after each commit — don't batch multiple features into one push.
- Never end a session with uncommitted or unpushed changes. If a session ends mid-feature, commit what exists with a `WIP:` prefix rather than leaving it unstaged.
- Commit message format: `<FEATURE-ID>: <short description>` (e.g. `F2-AuthPersistence: add token refresh on launch`).

### Commit + push is Claude Code's job, and it is not done until it is VERIFIED (E's standing rule, 2026-07-30)

**Claude Code owns git for this repo. Every block ends with a real, landed commit AND a real,
landed push — performed by Claude Code, in the same session, without being asked.** Never hand E a
git command to run. Never report "committed and pushed" from the fact that you typed the command.

**Mandatory close-out, run at the end of every block before you write your report:**

```
git status --short          # must be empty
git log --oneline -1        # local HEAD
git log --oneline -1 origin/main   # must be the SAME SHA
```

Paste that real output in the report. **If local HEAD and `origin/main` differ, the push did not
land and the block is NOT done** — fix it, don't report it. This rule exists because a "Pushed"
has silently failed to land in this project more than once, and because a commit command was once
handed to E as text and never verified.

**Sandbox limitation, and the lock files it leaves behind.** Cowork's sandbox has no GitHub
credentials — it can commit but **cannot push** (`could not read Username for 'https://github.com'`),
and a failed push there leaves stale `.git/HEAD.lock` / `.git/index.lock` that the sandbox has no
permission to delete. **If any git command fails with `Unable to create '.git/index.lock'` or
similar, clear them first** — `rm -f .git/HEAD.lock .git/index.lock` — then re-run. Also check on
session start whether local is ahead of `origin/main` (a Cowork-side commit may be sitting
unpushed) and push it as your first action if so.

## Architecture notes

- SwiftUI, Swift, `IPHONEOS_DEPLOYMENT_TARGET = 16.0` — any iOS 17+ API must be
  `#available`-gated (see §7's `.sensoryFeedback` precedent).
- **Backend: Firebase** (Auth + Firestore + Storage, project `adhdlifeos-acb49`;
  `GoogleService-Info.plist` is committed — private repo, client identifiers only). The Supabase
  and AWS layers this doc previously described were deleted at E's direction in commit `5244650`
  ("cut all services over to Firebase"). No local persistence layer — Firestore is the source of
  truth. Everything goes through per-feature `Firebase*ClientAdapter` structs over the shared
  `FirebaseManager` (`ADHD LifeOS/Firebase/`).
- **Adapters depend on a per-feature `*BackingStore` protocol, never on `FirebaseManager` directly**
  (E's 2026-08-23 call). `FirebaseManager` is a `final class` with a `private init` and a `shared`
  singleton, so an adapter holding it concretely cannot be tested at any price. Each adapter gets
  its own narrow protocol — never one protocol over the manager's ~40 methods — which `FirebaseManager`
  satisfies via a one-line extension, with a recording fake in tests. When a store needs a partial
  write, add a *named* wrapper on the manager (`updateLifeArea(id:fields:)`) rather than exposing the
  generic `update(id:fields:in:)`, so a store cannot address another collection.
- **Hand-written Firestore field dictionaries live in `FirestoreFieldPayloads`, never inline.** They
  are not derived from `Codable`, so no round-trip test reaches them, and a wrong key raises nothing
  — it writes a field nothing reads. Two conventions coexist and disagree on purpose: **tasks are
  fully snake_cased (`life_area_id`), captures are camelCase apart from `created_at` (`lifeAreaId`)**.
  Tests assert the wrong spelling is *absent* as well as the right one being present.
- Firebase SDK error mapping goes through `FirestoreErrorMapping` / `AuthErrorMapping`, which expose
  the SDK's domain and code so tests can build a genuine error. **The unit-test target deliberately
  does not link the Firebase SDK** — these are static products, and linking one into both the app and
  its hosted test bundle realises every Objective-C class twice. `FirestoreDocumentCoder` is the
  codec seam for the same reason.
- Schema: per-user subcollections under `users/{uid}` (tasks, life_areas, tags, logs, captures,
  nudges, reminders, focus_sessions); document IDs are UPPERCASE `uuidString`.
- Security rules live in-repo (`firestore.rules`, `storage.rules`) but are published manually by
  E in the Firebase console — Claude Code has no Firebase CLI auth. A rules change is not live
  until E republishes; say so in the block report.
- Manual-step convention (same as web project): anything requiring the Xcode GUI beyond CLI builds — code signing, provisioning profiles, App Store Connect/TestFlight — is E's job, never attempted by Claude Code directly.
- Lint: SwiftLint, config at `.swiftlint.yml` (default ruleset unless a rule is explicitly flagged as too noisy and adjusted).
- Tests live in `ADHD LifeOSTests/` (XCTest), UI tests in `ADHD LifeOSUITests/`.
- TDD is mandatory: write the failing test before the implementation for every feature, per `claudecode.md`.
- No placeholder/TODO-comment code — implementations must be complete and production-ready when a feature is marked `[x] COMPLETED`.
- Cowork's sandbox has no macOS/Xcode — it cannot independently run any build/test/lint command for this project (stricter than the web project, where root `src/` at least ran in-sandbox). All verification depends on Claude Code's pasted terminal output.

## UI/UX & Apple HIG Architecture (ADHD-Focused)

Implement layouts as an elite Apple Design Engineer. Every view must look handcrafted, premium, fluid, and highly accessible according to Apple's Human Interface Guidelines (HIG). Minimize cognitive overhead, prevent visual distraction, and maximize micro-interaction feedback. Do not write generic AI layouts or raw opacity soup.

### 1. Typography, Visual Hierarchy & Readability
- **Sizing Contrast**: Anchor views with strong, distinct hierarchy. Use heavy semantic headers (`.font(.largeTitle).bold()`) contrasted sharply against functional labels (`.font(.footnote).foregroundStyle(.secondary)`).
- **Premium Kerning**: Apply custom tracking to large titles to achieve a high-end native look: `.tracking(-0.5)`.
- **Layout Safety**: Text elements must never clip or truncate unexpectedly on smaller layouts. Use dynamic sizing elements such as `.minimumScaleFactor(0.8)` or explicitly configure `.layoutPriority(1)`.

### 2. Spacing Grid (Strict Base-4/Base-8 Tokens)
- **Zero Raw Margins**: Do not inject unmapped integers like `.padding(13)` or `Spacer(minLength: 22)`.
- **Layout Tokens**:
  - `4pt`: Micro positioning, inside asset-to-text gaps.
  - `8pt`: Inter-element bounding spacing within a component wrapper.
  - `16pt`: Outer screen container margins and canvas boundaries.
  - `24pt`: Macro group-to-group layout separation.
- **Structural Wrappers**: Use native `ScrollView` systems nested with `LazyVStack` or `LazyHStack` along with custom pinned segment controls over stock, standard `List` containers unless outputting basic Settings structures.

### 3. Hit Targets & Input Interaction
- **Physical Bounds**: Ensure all touch interactions, custom buttons, and action cells maintain a minimum touch targets metric of `44x44pt`. Bind custom view hierarchies with `.contentShape(Rectangle())` to make entire container zones tap-responsive.
- **Physical Sensory Feedback**: Deliver instant behavioral confirmation to reassure ADHD focus paths. Attach native tactile triggers to view interactions using `.sensoryFeedback(.impact(flexibility: .solid), trigger: bindingState)`.
- **Button Visual States**: Write explicit custom primitive `ButtonStyle` structures to scale interactive objects (e.g., scale down slightly to `0.97` upon active press). Raw opacity filters are prohibited.

### 4. Semantic Color Assets & Accessibility
- **Zero Hex Declarations**: Never inject hardcoded color strings or static RGB code paths **in
  Swift**. The one sanctioned home for hex is the asset catalog's colorsets (E's 2026-08-19
  design-token direction): the prototype palette lives there with light+dark variants, and views
  consume it via the generated symbols / `Theme.swift` helpers (`.bentoCard()`, `UrgencyPalette`,
  `sectionLabel()`, `Color.cardSurface`/`.pageBackground`/`.cardBorder`, coral `AccentColor`).
  Do not bypass the token layer with new inline colors — extend it.
- **Adaptive Semantic Colors**: Use dynamic system assets natively (`Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color.primary`, `Color.secondary`).
- **Contrast Ratios**: Maintain high WCAG contrast safety thresholds. Prefer semantic styling methods such as `.foregroundStyle(.secondary)` over `.opacity(0.5)` to align with active system accessibility overrides.

### 5. Intentional Micro-Animation & Depth
- **Smooth Spring Profiles**: Basic linear or rigid standard easing transitions are banned. Deploy custom physical spring curves: `.animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: bindingState)`.
- **Layer Architecture**: Separate layout information depths cleanly using native material types: `.background(.ultraThinMaterial)`.
- **Soft Diffusion Shadows**: Prevent heavy, muddy shadow rendering. Apply delicate light diffusion styling paths: `.shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)`.

### 6. Implementation Architecture
- **Unified Screen State**: Contain screen presentations and local state controls contextually using standard state enumerations: `enum ViewState { case loading, success, error(String) }`.
- **Data Execution Lifecycles**: Manage asynchronous operations via modern `.task` blocks instead of legacy `.onAppear` handlers.
- **Preview Support**: Every view structure must include a functioning `#Preview` block rendering Light and Dark environment variants side by side.

### 7. Design Skills — Precedence and Known Conflicts

Design-heavy blocks may mandate the installed design skills (`ui-ux-pro-max`,
`swiftui-design-principles`, `swiftui-pro`). They improve *how well* an authorised design is
executed. They never expand scope, and they never override this file.

**Precedence, absolute:** `CLAUDE.md` §1–6 and the **iOS 16.0 deployment target** beat every skill.
Never silently follow a skill over this doc, and never silently follow this doc without saying the
skill disagreed — **report every conflict in the build report.**

**Known conflicts, established 2026-07-30 in the Settings rebuild (`3f94eff`). Do not re-litigate
these per block; they are settled:**

- **`ui-ux-pro-max` — use `--stack swiftui`, ignore `--design-system` on native screens.** Its
  `--design-system` output is web-oriented and was discarded wholesale for Settings: it prescribed
  an "Immersive/Interactive Experience" pattern, "Exaggerated Minimalism" with oversized `clamp()`
  typography, a forced dark focus background, a hardcoded hex palette (`#059669`), a Google Fonts
  (Plus Jakarta Sans) import, and hover / `cursor: pointer` states. Every one of those violates §1
  (restrained SF typography), §4 (zero hex, adaptive semantic colours), or the native-iOS premise —
  and hover states do not exist on iOS at all. Its `--stack swiftui` guidance, by contrast, is
  sound and aligned with this doc ("use `Form` for settings screens", "support Dynamic Type — no
  fixed font sizes", "respect Reduce Motion", "add accessibility labels").
- **`swiftui-design-principles` spacing permits `12` and `20`. §2 wins — 4/8/16/24 only.** `12` and
  `20` are unmapped in this project and must not ship.
- **`swiftui-design-principles` pushes fixed `.font(.system(size:))` scales. §1 wins** — semantic
  Dynamic Type throughout.
- **`swiftui-pro` asserts "iOS 26 is the default deployment target" and Swift 6.2. Ignore that
  entirely — this project is iOS 16.0** (`IPHONEOS_DEPLOYMENT_TARGET = 16.0`, set in FEATURE-M2).
  Any iOS 17+ API it recommends must be `#available`-gated or not used. This is the same trap that
  made `.sensoryFeedback` need gating in `345233b` — note that §3 prescribes `.sensoryFeedback`
  without flagging that it is iOS 17+; **the target wins over §3 there.**

**`swiftui-pro`'s design / accessibility / views review passes are worth running** over a finished
view — in the Settings rebuild they correctly caught a hand-rolled `HStack` + `Spacer` title-value
row that should have been `LabeledContent` (which reflows at accessibility Dynamic Type sizes
instead of wrapping into narrow columns), and a glyph+text `HStack` that should have been a `Label`
(so VoiceOver reads it as one element and status is never conveyed by colour alone). Both are now
the house pattern for Form rows.
