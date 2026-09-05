# Session opener — Momentum v3 review loop, part 2 (continue from here)

Paste everything below the line into a fresh Claude Code session started in
`/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS`.

---

Momentum v3 review loop — CONTINUATION session (part 2). Read `claudecode.md`, `CLAUDE.md` and
the memory index first, then this brief. Do not re-plan; the redesign is BUILT and deep into
E's on-device review loop.

## Where things stand

- **Branch: `feature/redesign-v2`**, HEAD `1373a76`, clean, pushed, installed on
  `wishwashwacky15`. Close-out compares local HEAD to **`origin/feature/redesign-v2`**, never
  origin/main. Merging to main is E's call, later.
- The 13 original `F-V3-*` blocks plus ELEVEN review-loop followups are landed, one commit
  each — read `git log --oneline d559ae6..` for this session's ledger. What landed since the
  last opener:
  - `F-V3-Inbox-followup` — tag chips on the triage cards. `Capture.tagIds` decodes `tag_ids`
    (safe because full-document `setData` only happens at CREATE; every edit is a patch).
  - `F-V3-Journal-followup`(-2, -3) — the Journal timeline interleaves all four records of a
    day (entries, closed tasks, sprints at `ended_at`, captures at `created_at`), newest-first
    EVERYWHERE (E's ordering call — one monotonic scroll), sub-minute sprints hidden
    (`JournalTimeline.minimumVisibleSprintSeconds`), day headers name focus totals, the week
    eyebrow counts sprints, every row is a door (tasks/sprints → TaskDetailView, captures →
    `JournalCaptureDoor`, which is reusable and Home now uses it too). **Log/journal entries
    take tags — CREATE-ONLY**: `firestore.rules` denies update on logs, so `tag_ids` rides the
    create payload and an entry can never be re-tagged (deliberate, documented).
  - `F-V3-Composers`(+followup) — TaskCreateView and LogComposerView are dedicated S1-style
    screens (guide: S1 in the design HTML + shipped QuickCaptureView; shared leaves in
    `Theme/ComposerChips.swift`; due chips = tested `TaskDueChoice`, "Today" = startOfDay).
    `FlowingChips` is now a TRUE flow (`Theme/ChipFlowLayout.swift` — the `Layout` protocol IS
    iOS 16.0; the old "no Layout on iOS 16" comment was wrong). Every pinned bottom bar wears
    `ComposerFooterSurface` (bar material + CardBorder hairline top edge) — E's green-line
    note; apply it to any future pinned bar.
  - `F-V3-AreaColour` — `LifeArea.palette` stores an AreaPalette wire key
    (work/health/admin/growth/hobby); `AreaPalette.family(for:)` honours it BEFORE the emoji
    mapping and is the single choke point every surface reads. Editor swatches (Blue/Teal/
    Gold/Purple/Pink + Automatic) staged behind Save; Automatic ERASES the field via
    `FieldValue.delete()` built in `FirestoreFieldPayloads` (the one place allowed the
    sentinel — the adapter/test target cannot import Firebase).
  - `F-V3-HomeWidgets` — two medium widgets: Life Areas (versioned `LifeAreasWidgetSnapshot`
    published from Home's choke point; palette stems pre-resolved app-side) and Quick Capture
    (five static `Link`s). Deep links: `adhdlifeos://widget/areas` and
    `/widget/capture/<kind rawValue>`, parsed by `AppDeepLink` (unknown → plain launch, NEVER
    the auth layer), handled by RootView's own `.onOpenURL` beside the App-level auth one.
  - `F-V3-Today-followup`(-2) — Today carries the design's inbox module: 📥 header, count as
    warn chip, three 44pt peek rows that open THEIR capture, "and N more", a go-green
    "N handled today" line (ungated — the scoreboard toggle governs the RING only), and the
    "Clear the deck" CTA. Pure half in `HomeInboxPeek`. The peek rides the badge's existing
    fetch; returning from a pushed capture refreshes it.
  - `F-V3-Settings-followup` — nothing on Settings is a placeholder: About = real version &
    build (`AboutInfo`); new Focus section (daily focus goal 10–120 min, default sprint length
    5–120 min) and Feedback section (haptics + notification sounds). All four ride
    `MomentumPreferences` (decode-tolerant defaults at old behaviour: 30 / 15 / on / on);
    `AppFeedback` gates haptics + notification sound at FIRE time. Preference sections live in
    `SettingsPreferenceSections.swift`.

## The mode: on-device review loop (unchanged)

E reviews on the phone and sends notes; each note becomes a small `F-V3-*-followup` commit.
**Per change, non-negotiable:** failing test first for new logic → `swiftlint` (accepted debt
is EXACTLY two: TaskDetailView file_length 424, UITests static_over_final_class) → full unit
suite green **with the emulator up** → sim build → commit `F-…: <description>` + Claude trailer
→ push → SHA-verify vs origin/feature/redesign-v2 → device build+install:
`xcodebuild -destination 'platform=iOS,name=wishwashwacky15' -allowProvisioningUpdates build`
then `xcrun devicectl device install app --device wishwashwacky15 <app>` (DerivedData:
`/Volumes/Es-SSD/Xcode_External/DerivedData/ADHD_LifeOS-*`; grep `installationURL`).
Simulator destination `iPhone 17 Pro`. One xcodebuild at a time.

**Emulator:** E keeps it running in a second terminal. If `./scripts/emulators.sh` fails with
"port taken", it is ALREADY UP (curl 127.0.0.1:8080 answers "Ok") — use it, don't fight it.

## Hard-won facts a fresh session must not re-learn

- Suite ~1,453 tests; coverage ~22% (denominator keeps growing with view code — composition,
  not regression).
- **Widget target**: deployment floor **16.1** — no `containerBackground`, no generated colour
  symbols, and NO `#Preview(as: .systemMedium)` timeline macro (iOS 17+; plain view previews).
  New shared app+widget files must be added to the `membershipExceptions` list in
  `project.pbxproj` (the `FocusWidgetSnapshot` arrangement). The widget catalog now carries its
  OWN copies of 22 Area*/On*/StateGo colorsets — **palette changes must hit BOTH catalogs**.
- The Life Areas widget shows its empty state until the app is opened once post-install
  (needs one publish).
- File budgets bite constantly: 400 lines/file, 250 lines/type body. The house fix is a
  sections/previews split file (`CaptureInboxSections` pattern): this session produced
  `JournalTimelineSections`, `JournalViewPreviews`, `SettingsPreferenceSections`, and same-file
  extensions on `HomeView` (extensions are exempt from type_body_length; same-file extensions
  still see `private`).
- Equal-height bento pairs: children `.frame(maxHeight: .infinity)` inside the HStack + a
  shared minHeight (see `AreaGridCard`).
- `TagChipsRow` (renamed from CaptureTagChipsRow) is the shared value-fed chip strip; tag
  resolution is always ids→already-fetched-list (`CaptureRowPresentation.tags`,
  `JournalTimeline.tags`) — never per-row fetches.
- The composer footers and any pinned bar: `ComposerFooterSurface`. The Journal composer bar
  additionally keeps `captureDiscClearance` (60+16+8) so the global FAB doesn't cover it.
- UI journeys (4, `SignedInJourneyUITests`) run deliberately, not per-block; they type into
  `taskCreateTitleField` and tap `taskCreateSubmitButton` — those identifiers are load-bearing.
- Sibling-ForEach identity trap still stands. `LifeArea.colour` is an EMOJI; hues via
  `AreaPalette.family(for:)` (override → emoji table → UUID-stable fallback).
- Deep-link contract: the widget target writes URL strings by hand (it cannot see
  `CaptureKind`); `AppDeepLinkTests` locks the contract from the app side — keep them in sync.

## Known-open items (not bugs)

- Login/auth screens keep V1 layout — commission a block if wanted.
- The Captures ARCHIVE's proper v3 home (interim door: Areas → "Handled captures").
- TaskDetailView's sprint PLANNER still resolves its default duration independently — the new
  "default sprint length" setting feeds the one-tap starts (Best-next-move, task cards, widget
  active goal) but not the detail screen's staged planner default. Small follow-up if E notices.
- Log/journal tags are create-only (rules deny update on logs) — say so if E asks for editing;
  it would need a rules change E must republish.
- Lint accepted debt is exactly two items; anything else is new and must be fixed.

Pick up exactly there: wait for E's next on-device review note and turn it around.
