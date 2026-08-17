# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Bootstrapped — SwiftUI app shell created in Xcode, no feature code yet. When a feature has been designed (see Workflow below), implement it per the TODO; don't invent architecture ahead of that.

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
  -enableCodeCoverage YES -resultBundlePath TestResults.xcresult
xcrun xccov view --report TestResults.xcresult   # coverage report (threshold: 70%)

xcodebuild build -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Test destination note (2026-07-30):** this machine has only the iPhone 17 family on iOS 26.5
installed — there is no iPhone 15 Pro simulator, so the previously documented destination was not
runnable. If `xcodebuild` reports the destination is unavailable, run
`xcrun simctl list devices available` and use an installed device rather than guessing.

A feature isn't done until `swiftlint lint`, the test suite (≥70% coverage), and the build all pass — and the real terminal output has been pasted for review, not just a "done" summary.

## Version Control

Repo: https://github.com/digdiggydigger/es-life-os-mobile (private, branch `main`).

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

- SwiftUI, Swift, targeting iOS (minimum version TBD in `docs/ARCHITECTURE.md`).
- Backend: same Supabase project as the Es_Life_OS web app (Postgres + Auth), reached via `supabase-swift`. No local persistence layer (no Core Data) — Supabase is the source of truth.
- Supabase migrations are applied manually by E via the SQL Editor, same as the web project — Claude Code has no CLI auth to do this itself.
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
- **Zero Hex Declarations**: Never inject hardcoded color strings or static RGB code paths.
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
