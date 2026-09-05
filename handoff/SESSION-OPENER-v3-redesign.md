# Session opener — Momentum v3 redesign (continue from here)

Paste everything below the line into a fresh Claude Code session started in
`/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS`.

---

Momentum v3 redesign — CONTINUATION session. Read `claudecode.md`, `CLAUDE.md` and the memory
index first, then this brief. Do not re-plan; the redesign is BUILT and in on-device review.

## Where things stand

- **Branch: `feature/redesign-v2`** (all work lands here; `main` is frozen stable V1).
  The mandatory close-out compares local HEAD to **`origin/feature/redesign-v2`**, NOT origin/main.
  Merging to main is my call, later.
- **All 13 redesign blocks are COMPLETE, committed individually, pushed, and installed on my
  iPhone** (`wishwashwacky15`). One commit per block, `F-V3-*` prefixed — read
  `git log --oneline a99aa37..` for the exact ledger. Highlights:
  F-V3-Tokens (palette/AreaPalette resolver; the widget target has its OWN catalog — palette
  changes must hit BOTH), F-V3-Today, F-V3-Areas (Areas replaced the Captures tab slot — hybrid
  five-tab IA: Today/Tasks/Areas/Journal/Nudges, my call), F-V3-AreaDetail, F-V3-Tasks,
  F-V3-Capture (fan + typed composer), F-V3-Inbox, F-V3-Journal, F-V3-Nudges (**new
  `completion_dates` field on nudge docs, E-authorised** — full-array read-modify-write, never
  arrayUnion in the codec seam), F-V3-TaskDetail-Sprint, F-V3-Settings (appearance override via
  one `@AppStorage` key `settings.appearance`), F-V3-WeekReview (AI summary moved off Today into
  the week review), F-V3-Widgets-LA.
- Also shipped mid-run: **F-SprintPersistence** (running sprint survives process death; restore
  in `FocusSessionService.restorePersistedSprint()`, UserDefaults-backed, offline-completion
  confirmation card until acknowledged).

## The current mode: on-device review loop

I am reviewing on the phone and sending notes; each note turns into a small `F-V3-*-followup`
commit with the full gates. Landed so far: capture disc FAB (v3 disc + **bottom-trailing pin** —
a `.bottom` overlay CENTRES a shrunk stack, that bug is fixed with a full-width trailing frame),
composer tags at point of capture (all five kinds incl. the fast-task path), voice transcript as
a labelled block on the capture detail (`CaptureDetailPresentation.headline/transcript`).

**Per change, non-negotiable:** failing test first for new logic → `swiftlint` (only accepted
debt: TaskDetailView file_length 424 and UITests static_over_final_class) → full unit suite
green **with the emulator up** (`./scripts/emulators.sh` in a second terminal — without it the
Firebase suites grind network timeouts for 40+ minutes instead of skipping) → sim build → commit
with `F-…: <description>` + Claude trailer → push → SHA-verify vs origin/feature/redesign-v2 →
device build+install:
`xcodebuild -destination 'platform=iOS,name=wishwashwacky15' -allowProvisioningUpdates build`
then `xcrun devicectl device install app --device wishwashwacky15 <app>` (DerivedData lives at
`/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-*`; grep `installationURL` to confirm).
Simulator destination is `iPhone 17 Pro`. Only one xcodebuild at a time (shared build DB).

## Hard-won facts a fresh session must not re-learn

- UI journeys (4, `SignedInJourneyUITests`) run deliberately, not per-block; all pass. The
  nudge journey taps `homeNudgesWaitingRow` → Nudges tab → `nudgeDismissButton-<uuid>`; it
  asserts the tab hop via tab-bar `isSelected`. **Never put the same identity in two sibling
  ForEach** — that exact bug made a LazyVStack render a stale due card while the header updated.
- `LifeArea.colour` holds an EMOJI; hues resolve via `AreaPalette.family(for:)` (emoji table +
  UUID-stable fallback; 🏠 and 💰 share gold deliberately).
- Composer machinery: `CaptureInboxService.newCaptureLifeAreaId` / `newCaptureTagIds` ride
  creation; tags attach post-create through the existing addTag seam (warn, don't fail — the
  capture already exists). Voice transcription is stored as the capture's `content`.
- The suite count is ~1,366; coverage ~22.4% (denominator grew with view code — composition,
  not regression).

## FIRST FIX, queued by E — do this before anything else

**Tag chips on the capture inbox triage cards** (the top decision card AND the "Then" rows in
`CaptureInboxView`/`CaptureInboxSections.swift`/`CaptureRowView`). The clean route:
- Tag membership lives as a `tag_ids` string array ON the capture document
  (`FirebaseManager+Tags.swift`, `tagIdsField = "tag_ids"`), which the `Capture` model
  deliberately does NOT decode today. Add `tagIds: [UUID]?` to `Capture` with CodingKey
  `"tag_ids"` (mind the split convention: captures are camelCase APART from snake_case
  exceptions — `tag_ids` is one, it is the field the arrayUnion writes) + a Firestore-codec
  round-trip test (the `NudgeCompletionCodingTests` pattern; note ids are stored as UPPERCASE
  uuidStrings).
- Then chips = one `service.fetchAllTags()` filtered by each capture's `tagIds` — zero extra
  per-row fetches. Render as small `MomentumChip`s (CardSurfaceSecondary/LabelSecondary) under
  the meta line on the top card and the Then rows.
- TDD the pure part (ids→tags resolution), full gates, `F-V3-Inbox-followup` commit, install.

## Known-open items (not bugs)

- Login/auth screens keep V1 layout (inherit the palette) — commission a block if wanted.
- The Captures ARCHIVE's proper v3 home (behind the Inbox) — interim door is Areas →
  "Handled captures".
- Nudge streak dots accrue from stamps going forward — sparse until a week of use.
- E's review notes keep coming: treat each as a followup with full gates, then install.

Pick up exactly there: wait for my next on-device review note and turn it around.
