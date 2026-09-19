# ADHD UX audit — code-side findings (sub-agents, read-only), 2026-09-19

Condensed from four read-only sub-agent reports. "read" = read in code; "inf" = inferred. To be
verified visually on the iPhone 18 Pro / 27.0 sim before any option goes to E.

## A. HIG sweep (apple:hig-reviewer)

- **MODAL-1 (Critical, read):** `Capture/QuickCaptureView.swift:117,129`, `Journal/LogComposerView.swift:117`,
  `Tasks/TaskCreateView.swift:73` — Cancel → `dismiss()` and swipe-down discard typed text; no draft path.
  Breaks E's Q4 ("never lose input"). HIG `modality.md › Best practices`.
- **MODAL-2 (Critical, read):** `Places/PlaceActionsSection.swift:88` sheet → `PlaceActionsEditorView.swift:66,72`
  sheets (contact/app picker) = depth 2. Breaks Q4 max-1.
- **MODAL-3 (High, read):** camera `.fullScreenCover` over already-presented composer/detail sheets:
  `QuickCaptureView.swift:150` (inside sheet from `CaptureInboxView.swift:117`), `CaptureDetailView.swift:88,101`,
  `CaptureRowView.swift:37`. Depth 2 (system camera — arguably a system picker).
- **MODAL-4 (High, read):** `Tasks/TaskDetailView.swift:100-116` custom back button, back-swipe disabled,
  blocking "Discard changes?" alert ("Your unsaved edits to this task will be lost.") instead of autosave.
  HIG `file-management.md` ("automatically perform periodic saves").
- **UNDO-1 (Critical gap, read):** 0 hits for soft delete. Hard deletes w/ confirm: `TaskDetailView.swift:117-129`,
  `TagEditorDetailView.swift:117`, `LifeAreaEditorDetailView.swift:154`, `PlacesListView.swift:151-158`,
  `CaptureDetailView.swift:107`. Q3 = full build (Firestore rules → E republishes).
- **UNDO-2 (compliant):** `Capture/CaptureInboxUndoSections.swift` triage undo persists until next action — the
  pattern to reuse.
- **WRITE-1 (High):** "Overdue" at `Tasks/TaskRowPresentation.swift:72`, `LifeAreaDetail/AreaTaskRow.swift:92`,
  `Tasks/MomentumTaskBuckets.swift:67` (text is `.secondary`, not red).
- **WRITE-2 (Medium):** streak copy `Home/MomentumScoreboard.swift:246-252`, `Focus/WeeklyFocusSummaryWidget.swift:81`
  ("Day Streak"), `Home/MomentumScoreboardViews.swift:145-159`.
- **REACH-1 (High):** top-bar primary action in sheets: `Nudges/NudgesView.swift:281`, `TagEditor/TagEditorListView.swift:35,171`,
  `TagEditorDetailView.swift:77`, `LifeAreaEditor/LifeAreaEditorListView.swift:36,197`, `LifeAreaEditorDetailView.swift:135`,
  `Capture/CaptureDetailView.swift:213`, `Places/PlaceEditorView.swift:66`, `Places/PlaceActionsEditorView.swift:53`,
  `Focus/FocusSprintDetailView.swift:51`. Q8 wants bottom.
- **REACH-2 (compliant template):** bottom `safeAreaInset` primary in `QuickCaptureView.swift:125`,
  `LogComposerView.swift:112`, `TaskCreateView.swift:69`, `Auth/LoginView.swift:97`, `CaptureInboxView.swift:145`.
- **GEST-1 (compliant):** `Tasks/TaskRow.swift:52-182` swipe-to-close is a bonus; 44pt tap circle primary + a11y actions.
- **GEST-2 (High):** `Places/PlacesListView.swift:151-158` delete is swipe-only. Breaks Q7 hard rule.
- **GEST-3 (Medium, inf):** `.onMove` in `Home/HomeAccessoryStrips.swift:23`, `Places/PlaceActionsSection.swift:63` —
  no Move up/down a11y action confirmed.
- **FOCUS-1 (High):** `Focus/FocusSprintDetailView.swift:63-77` sprint sheet = checkpoint banner + countdown + identity +
  `FocusSprintTimelineCard` (timeline+inspector+phases) + `FocusCadenceEditorCard` + controls. vs Q2 "ONLY".
- **FOCUS-2 (compliant):** zero repeatForever/pulse/autoreverses.
- **LA-1 (Medium):** `FocusTimerWidgetLiveActivity.swift:166-201` controls ~38pt (self-documented: LA 160pt height cap).
- **HOME-1 (High):** `ActiveGoalSelection.swift:16-33` auto-pick, no pin.
- **TYPE-1 (Low):** `.font(.system(size: 40))` emoji `LifeAreaDetailComponents.swift:26`; 4pt dot `DailySummaryResultCard.swift:122`
  (both icon-class — not real DT risks).

## B. Motion / copy / colour / Dynamic Type / spacing inventory

- **Motion at rest: CLEAN.** No repeatForever / phaseAnimator loops / repeating symbol effects / Timer.publish visuals.
  Only OS `Text(timerInterval:)` clocks, one-shot draw-on, celebration TimelineView only while bursts exist.
- **Shame/loss copy:** "One day closed. Keep it alive today." `Home/MomentumScoreboard.swift:251`; "N days closed in a row." /
  "Streak kept. Best is N." `:248,252`; "Streak" header + "Close one to start a streak." `MomentumScoreboardViews.swift:145-176`;
  **"Close it — keeps a N-day streak"** `Tasks/MomentumTaskContext.swift:27` (Task Detail primary button);
  "Overdue" ×3 (above); "N/7 days · N streak" `FocusTimerWidget/FocusStatsWidget.swift:218`.
- **Colour (a) raw system colours:** `.green/.orange/.red` `Settings/NotificationPermissionState.swift:72-74`;
  `.green` `Focus/WeeklyFocusSummaryWidget.swift:138,141`, `Focus/FocusSprintPresentation.swift:88`,
  `FocusTimerWidget/FocusActivityComponents.swift:115` (widget target lacks StateGo in its catalog).
- **Colour (b) semantic misuse:** **`Home/DailySummaryView.swift:223` StateRisk (red flame) on neutral "Nudges Due"**
  beside StateGo "Open Tasks" / StateWarn "Ideas Offloaded". "Reached/done" split StateGo vs raw `.green`.
  `AppTabBar.swift:257` StateRisk Captures badge (documented as iOS badge convention — borderline, tab bar settled).
  `UrgencyPalette` p1→StateRisk is settled (Momentum v3).
- **Colour (c) text opacity:** `Capture/CaptureFanOverlay.swift:44` `.white.opacity(0.62)` subtitle over Scrim (needs a
  token, not blind `.secondary`).
- **Dynamic Type AX3 risk (lineLimit(1), no scale):** `Tasks/TaskRow.swift:104` (meta), `Focus/FocusTimerBarContent.swift:73,219`
  (task title, whole sprint), `Focus/FocusCompletionCard.swift:112`, `Home/HomeAccessoryStrips.swift:120,344`,
  `Capture/CaptureRowComponents.swift:186`, `Journal/JournalTimelineSections.swift:119,142`, `Places/PlacesListView.swift:255`,
  `Places/PlaceAppPickerRows.swift:67`, `FocusTimerWidget/RoutineLiveActivity.swift:74`.
- **Off-grid spacing:** 35 literals / 23 files; 22 are `spacing: 2` title/subtitle micro-stacks; `spacing: 12` in
  `PlaceRoutineScreenRows.swift`, `TaskListView.swift:75`, `HomeView.swift:189`, `RemindersView.swift:22`; `.padding(12)`
  `WeeklyFocusSummaryWidget.swift:98`.

## C. Widgets / Live Activity / Dynamic Island / notifications

- **Sprint LA:** Lock Screen running = emoji badge, "FOCUS SPRINT" eyebrow, title, countdown, progress bar + checkpoint dots,
  "N of M checkpoints", Pause/Resume + Stop (~38pt, 17+). **No +5m anywhere** (Q2 names +5m / End). Extras vs Q2: badge,
  eyebrow, dots + caption. **No `.widgetURL`** on the sprint LA (routine LA has one) — tap lands wherever the app was.
  HIG `live-activities.md › Offering interactivity`: "open your app at the right location"; also "prefer limiting it to a
  single element" (two buttons).
- **DI compact:** emoji + countdown only. **DI minimal:** emoji only, **no countdown** — HIG `live-activities.md › Minimal
  presentation` cites Timer showing remaining time instead of a static icon.
- **5-min heads-up: none by design** (coincides at 15-min / 2-checkpoint default only).
- **Routine LA:** display-only; "Next: <step>" + N/M + capsule; explicit deep link — the right "way back" pattern.
- **Widgets:** FocusStats small shows Active Goal title, no time context; medium shows "15m sprint · N nudges" + streak;
  generic `adhdlifeos://widget/focus` → Home. LifeAreas → Areas tab. QuickCapture 5 discs, precise routes.
  **No Lock Screen accessory widget family at all** ("out of sight, out of mind" gap).
- **Notifications:** one per trigger, no stacking, sound off by default, no guilt copy — good. **No app-wide daily cap.**
  Nudge tap routing not traced.

## D. Interaction inventory (pending — gestures, targets, modal map, drafts, destructive/undo, sheet placement, taps-to-sprint)

## D. Interaction inventory (apple:swift-generalist) — COMPLETE

- **Gestures:** TaskRow swipe-right close has a 44pt circle twin, BUT a full swipe (75pt threshold) commits close with
  **no confirm, no undo** (`TaskRow.swift:170-181`). Places `.swipeActions` delete: **no tap twin anywhere** (not in
  PlaceEditorView either). `.onMove` life areas (`HomeAccessoryStrips.swift:13-28`) and place actions
  (`PlaceActionsSection.swift:63-66`): drag-only for sighted users. `.onDelete` place action: immediate, no twin.
  `.refreshable` ×6 (Journal, Home, Inbox, Areas, LifeAreaDetail, Nudges): **no tap Refresh anywhere**. No long-press /
  contextMenu / draggable anywhere.
- **Targets:** at the 44 floor (below 48–52): Tasks close circle, Tasks row ▶ start, Task-detail Start row,
  **floating focus bar Pause/+30s/+5m/Stop ≈44**. Meets/exceeds: Home hero Start 48, sprint sheet buttons 54/≈60,
  disc 60, Sorted 52, PrimaryActionButtonStyle ≈60, nudge "Done for now" 54. Capture "Undo" possibly <44 WIDE (inferred).
- **Modal depth:** QuickCapture (cover from RootView, or sheet from Inbox) → camera cover = 2. **Tools→Places(push)→
  PlaceEditor sheet→PlaceActionEditorSheet→Contact/App picker = 3** (17+). Settings sheet→LifeAreaEditorList(push)→
  AddLifeAreaSheet = 2; Settings→TagEditorList→AddTagSheet = 2; Settings→account-deletion Apple-ID sheet = 2.
- **Drafts:** zero persisted drafts app-wide. Swipe-down discards silently: QuickCapture, TaskCreate, LogComposer,
  PlaceEditor, AddLifeArea, AddTag, Nudges add. TaskDetail (push) blocks with "Discard changes?", edge-swipe disabled.
- **Destructive/undo:** Task delete permanent (confirm). **Task close on Tasks tab: no undo ("closing is one-way")
  vs Home hero close: undo card** — same action, two behaviours. Capture discard permanent. Capture triage undo
  persistent (matches Q3). Life area archive reversible (no hard delete). Tag/Place delete permanent. **Nudge dismiss:
  no undo.** Sprint early exit confirms (matches Q10).
- **Sheet primary placement:** bottom = TaskCreate, QuickCapture, LogComposer. CapturePromoteSheet "Create Task"
  in-scroll (can scroll away at large DT). Top = PlaceEditor, PlaceActionsEditor, AddLifeArea, AddTag, Nudges add
  (Nudges carries a comment arguing FOR top).
- **Taps to sprint:** Home hero 1; Tasks due-today ▶ 1; **other Tasks buckets 2** (row → detail → Launch); Task detail 1.

## E. VERIFIED ON THE SIM (iPhone 18 Pro / 27.0, emulator account audit@test.local)

- **Task composer (fan → Task, fullScreenCover):** swipe-down does nothing (cover); **Cancel silently discards**
  typed text ("Book the dentist before Friday" gone on reopen; no prompt). Frames `cap-02..05`.
- **Journal composer (pencil disc → sheet):** text **survives swipe-down AND Cancel** within the session (draft held
  above the sheet), but is **lost after the app is quit** (in-memory only). Frames `jr-01..06`. → HIG agent's MODAL-1
  claim for LogComposerView is WRONG for in-session; right for persistence. Composers are INCONSISTENT with each other.
- **Settings button 40×40** (<44 floor), Home. **Journal "All activity" 38×36**, filter chips 36pt tall (6 chips +
  "All areas" pop-up, scroll off-screen). **Composer chips 36pt tall** (area ×7, tag ×5), **tag "Add" 24×14pt**,
  Cancel 77×36, effort chips 118×46 (<48).
- **Tasks tab first-run:** eyebrow "3 OPEN · 0 OVERDUE" but the default Momentum view lists ONE task (2 undated open
  tasks hidden until "Open"). "0 OVERDUE" printed even at zero.
- **Home first-run:** 3 screens long; "Nothing open or closed this week" ×4 (Home) and ×4 (Areas) — repeated noise;
  life areas shown BOTH on Home and in the Areas tab; primary CTA on the hero is solid green "Close it" above
  secondary "Start session".
- **Capture Inbox empty state:** big "Capture something" button duplicates the + disc on the same screen.
- **Fan copy vs Task copy contradict:** fan says "Everything goes to the inbox — you decide what it is later";
  the Task tile then says "Skips the inbox — this one goes straight to your list."
- **Settings:** footers are walls of text (Feedback footer ~12 lines); **Notifications card has a large empty gap**
  between "System Permission / Not requested yet" and "Open iOS Settings" (layout defect, frame fr-settings-p3);
  "Life Areas" entry appears in Settings AND Tools.
- **Sign-in:** segmented control labels do not scale at AX3; "Forgot password?" low-contrast grey (measure from
  colorset); primary at bottom (good).
- **Tab bar:** selected "Captures" pill truncates to "Captu…" at default size (tab bar is SETTLED — name the tension
  only).
- **Q3 verified (seeded account):** (1) Tasks-tab ○ close → immediate, **no undo** ("Order repeat prescription" →
  Closed today; frames q3-02/10/11). (2) Full right-swipe → green "CLOSE" reveal → **commits with no confirm and no
  undo** ("Return the Amazon parcel"; q3-20/21). (3) Home nudge "Done for now" → card vanishes, "Nothing due — all on
  time.", **no undo** (q3-30/31/32). Home hero close DOES offer undo (code) — same action, two behaviours.
- **Notification prompt** fires from `NudgesService.swift:182` when an active nudge is scheduled — normally right
  after the user creates one; it appeared "cold" only because seeding pre-created nudges. NOT a finding.
- **Sim hazard (not an app finding):** after an idb LOCK the sim display auto-dimmed (idb input does not reset the
  idle timer); a LOCK→HOME→swipe cycle clears it. My tap on the lock screen landed on the LA's **Pause** — the
  LA's Pause/Stop sit where a user unlocking/tapping would also hit them (note for the LA review).
- **Tasks tab default view:** Due today mixes overdue rows (meta "Overdue") under the "DUE TODAY" header.
- **Sprint surfaces:** the card's gesture model (tap = open sheet; swipe/grabber = collapse/expand) — the 44pt grabber
  overlaps the collapsed card's title centre, so a tap there toggles collapse instead of opening the sheet.

## F. CONTRAST (computed from colorset hex, `scratchpad/contrast.py`, WCAG sRGB; light / dark)

- **LabelSecondary fails 4.5:1 small text in LIGHT on every surface** (3.92–4.25; dark 5.13–5.55 passes).
- **LabelTertiary fails even 3:1 everywhere** (1.85–2.33, both modes).
- **Placeholders** (`What needs doing?`, `What's on your mind?`) 1.69 / 2.43 (inferred: system placeholderText).
- **StateWarn text** on PageBackground 2.72 / 8.72 (fails 3:1 light — the inbox "4" count, footnote warn text);
  on CardSurface 3.02 / 7.93 ("quiet since Tuesday", "Four are still sitting here…"); warn on its 0.16 wash 2.56 light.
- StateGo on PageBackground 2.82 light (fails 3:1); StateRisk on Page 3.79, on Card 4.21 light.
- AccentColor on PageBackground 3.55 light / 4.92 dark; on CardSurface 3.93 / 4.47 — **links/"Forgot password?"
  (3.55) fail small text**; "Task it" white-on-accent 3.65 both modes (passes only as 17pt bold).
- Area label hues: 5 of 9 families fail light small text (AreaAdmin 2.79 on page).
- Tab badge white on StateRisk 4.21 light / **3.41 dark** (code comment claims ~4.2, only light checked).
- PASS: LabelPrimary everywhere (13–19:1); "Close it"/Go buttons (6–9:1); urgentBentoCard text 12–17:1;
  Journal paper ink 9.5/10.3; fan subtitle `.white.opacity(0.62)` on Scrim 5.65/7.71.
- **0 of 63 colorsets carry an Increase Contrast ("high contrast") variant; no code reads `colorSchemeContrast`** —
  Increase Contrast does nothing for the custom palette.
- Dead tokens: `BarSurface` (no call site), `OnStateWarn` (no call site).
