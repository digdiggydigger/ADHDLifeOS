Momentum v3 review loop — CONTINUATION session (part 3). Read `claudecode.md`, `CLAUDE.md` and
the memory index first, then this brief. Do not re-plan; the redesign is BUILT, E's first
on-device checklist round is fully turned around, and ONE design task is queued with a
questions-first gate (below).

## FIRST TASK, gated: the Tasks page rebuild (BUG-b11, Critical)

E reviewed the proposal artifact ("Tasks Rebuild",
https://claude.ai/code/artifact/07c6b344-e759-4baa-8588-6a465988f30d) and **selects Option A —
the design frame, faithfully**: replace the tall swipe cards with the frame's dense rows
(visible tap-circle to close, effort chip, one-line meta "💼 Work & Career · P1 · deep-work",
small ▶ sprint start), section headers with counts ("Due today · 2"), closed-today rows with
their closed time, delete moving to the detail screen, swipe-right-to-close kept as a bonus
gesture.

**BUT — do not finalise or build anything yet.** E's explicit instruction: **first ask E 4-5
questions** to get a better understanding of the Tasks page's PURPOSE and USES for them
(how they actually scan it, what they come to it to do, what today's page gets in the way of,
which filters/segments they really use, where sprint-starting should live, etc. — pick the 4-5
that most change the build). Use AskUserQuestion where options fit, free-text where they don't.
Only after E answers: restate the finalised spec in a sentence or two, then build it as one
`F-V3-Tasks-rebuild` block with the full gates.

Reference material: the design HTML's Tasks frame is in
`Momentum-v3-Design-Handoff/ADHD LifeOS - Momentum - v3.dc.html` at ~char offset 17.5k-26.5k
(BEFORE the S-frames; S3 at ~112k is the task DETAIL screen, already shipped and out of scope —
E confirmed). Current implementation: `TaskListView` + `SwipeableTaskCard` +
`MomentumTaskBuckets`/`TaskGrouping`/`TaskListRefinement`/`TasksService` (the pure layers are
solid and largely reusable; the rebuild is the presentation layer).

## Where things stand

- **Branch `feature/redesign-v2`**, HEAD `91f839b`, clean, pushed, INSTALLED on
  `wishwashwacky15`. Close-out compares local HEAD to **`origin/feature/redesign-v2`**, never
  origin/main. Merging to main is E's call, later.
- Suite ~1,483 tests, 0 failures. Lint accepted debt is EXACTLY two: TaskDetailView
  file_length 424, UITests static_over_final_class. Anything else is new — fix it BEFORE
  committing (this loop once committed with lint errors and needed a paid-back followup,
  `06a71bb`; don't repeat that).
- E's first on-device checklist round (bug-tracker export, 8 bugs + 3 suggestions) is fully
  landed and E CONFIRMED on device: b10, b7+b1+b4, b9, b6, b3 tested & working; b2 (widget
  cold-launch) fixed earlier; b8 shipped with b9; b5 took two rounds (below). Only b11 remains
  (the gated task above).

## This session's ledger (all on origin/feature/redesign-v2)

- `a7079d0` b2: widget doors survive a DEAD launch — `AppDeepLink.requiresSignedInUI`;
  RootView listens on the always-mounted outer Group, stashes `pendingWidgetLink`, drains via
  `.task` on the TabView. ANY future deep link opening signed-in UI must ride this gate.
- `14de0ac` b10: Today hero shows logged focus — `MomentumScoreboard.focusLoggedTodayLabel`
  ("2 sessions · 35 min today"; sub-minute sessions COUNT, minutes floor), go-green chip on its
  own row + button relabels "Start another session". Rides `publishedHistory` (the analytics
  fetch), which refetches on `completedSprintCount` — including offline settles.
- `b1026c3` + `91f839b` b5, TWO rounds: (1) `Theme/KeyboardDismissal.swift` — Done bar +
  scroll-dismiss, applied ONCE per presentation tree (RootView + each modal content root;
  nested application doubles the Done button). (2) E: "not sufficient" → **`Theme/
  KeyboardTapAway.swift`**: ONE window-level UITapGestureRecognizer (installed idempotently
  from RootView `.onAppear`), `cancelsTouchesInView = false`, delegate ignores touches inside
  text inputs via `isInsideTextInput` (ancestor walk, tested). Covers sheets/covers too (same
  UIWindow). Both mechanisms coexist deliberately.
- `f607f3d` b7/b1/b4: **`DataChangeSignal`** — THE refresh architecture. Every FirebaseManager
  write path posts it AFTER the awaited write (generic save/delete/update funnel + batch
  commits in +LifeAreas/+Tags/+Seed; +AccountDeletion deliberately silent; grep-audited
  complete). Seven screen roots refetch via `DataChangeSignal.debouncedPublisher()` (600ms,
  coalesces bursts): Home (full pull-equivalent `refreshEverything()` incl. widget republish),
  Tasks, Areas, Journal, Nudges, Inbox (quiet `refresh()` + tags), LifeAreaDetail.
  TaskDetailView deliberately does NOT subscribe (mid-edit clobber). **Rules: any NEW write
  path posts the signal; any new screen root subscribes; and services obey the QUIET-RELOAD
  rule — `load()` never flips state back to `.loading` over loaded content (guard tested on
  all five services).**
- `ec17871` b8: Bin off the triage card (state + dialog removed; full-screen capture view's
  Discard untouched).
- `0d32de9` + `06a71bb` b9: Skip on the triage card — `CaptureSkipOrdering` (pure stage AFTER
  CaptureListRefinement, id-keyed so the signal's refetch can't undo it), `skippedIds`/`skip`
  live in the +Triage extension file (setter open on the counterweight precedent).
- `f6d4df6` b6: link field `lineLimit(1...4)` + system PasteButton ([.url, .plainText] via
  NSItemProvider; `LinkPasteNormalization` trims clipboard whitespace).
- `45d81f1` b3: FOUR explicit-only palette families (E picked all four: Green/Orange/Red/
  Slate) — four tokens each in BOTH catalogs (app + widget). **`family(for:)`'s automatic
  fallback is PINNED to the original five, never `allCases`** — growing the enum must not
  reshuffle automatic hues. Editor swatches grow via allCases automatically.

## The mode: on-device review loop (unchanged)

Per change, non-negotiable: failing test first for new logic → `swiftlint` (exactly the two
accepted debts, checked BEFORE committing) → full unit suite green with the emulator up → sim
build → commit `F-…: <description>` + Claude trailer → push → SHA-verify vs
origin/feature/redesign-v2 → device build+install:
`xcodebuild -destination 'platform=iOS,name=wishwashwacky15' -allowProvisioningUpdates build`
then `xcrun devicectl device install app --device wishwashwacky15 <app>` (DerivedData:
`/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-*`; grep `installationURL`).
Simulator destination `iPhone 17 Pro`. One xcodebuild at a time.

**Emulator:** `./scripts/emulators.sh` in a background task; "port taken" means ALREADY UP
(curl 127.0.0.1:8080 answers "Ok"). E's second terminal doesn't reliably keep it alive —
check before every suite run.

**Device storage:** E's iPhone ran out of space mid-loop once (install error
`IXRemoteErrorDomain 7` / "Not enough space"). If install fails that way, it's E's phone, not
the build — ask E to free space and retry.

## Hard-won facts a fresh session must not re-learn

- File budgets bite CONSTANTLY: 400 lines/file, 250 lines/type body. House fix: split files
  (`RootViewPreviews`, `MomentumScoreboardViewsPreviews`, `HomeWeekReviewRow`) or same-file
  extensions (exempt from type_body_length, still see `private`); cross-file extensions with a
  deliberately-open setter follow the counterweight precedent. CHECK LINT BEFORE COMMITTING.
- Test identifiers: single-letter variables are lint ERRORS in tests (identifier_name, 3+).
- Widget floor 16.1: no containerBackground, no generated colour symbols, no
  `#Preview(as: .systemMedium)`; shared app+widget files ride `membershipExceptions` in
  project.pbxproj; **palette changes must hit BOTH asset catalogs** (widget has its own copies).
- `zsh` trap: never name a shell loop variable `path` (clobbers PATH).
- Sibling-ForEach identity trap still stands. `LifeArea.colour` is an EMOJI; hues via
  `AreaPalette.family(for:)` (override → emoji table → UUID-stable fallback pinned to five).
- UI journeys (4, `SignedInJourneyUITests`) run deliberately, not per-block;
  `taskCreateTitleField`/`taskCreateSubmitButton` identifiers are load-bearing — the Tasks
  rebuild MUST keep them (or update the journeys in the same block).
- Composer/pinned bars wear `ComposerFooterSurface`; Journal's bar keeps
  `captureDiscClearance`.
- Log/journal tags are CREATE-ONLY (rules deny update on logs).

## Known-open items (not bugs)

- Login/auth screens keep V1 layout — commission a block if wanted.
- The Captures ARCHIVE's proper v3 home (interim door: Areas → "Handled captures").
- TaskDetailView's sprint PLANNER default still independent of the default-sprint-length
  setting (the one-tap starts DO use it).

Pick up exactly there: open with the b11 questions for E (4-5 of them, purpose-and-uses),
finalise the Option-A spec from the answers, then build it with full gates.
