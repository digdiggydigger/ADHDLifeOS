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

## G. apple-design review — Today + Areas (sub-agent, HIG-cited; frames s-home-*, s-areas-*, fr-home-*)

Rating **Critical issues**. Thesis: a scoreboard that leads with a task; remembered for the green ring over "Best next move".
- **HOME-01 Crit** AX3 truncation: ring "OF 5 C…" (ring fixed 126pt), hero next step "ask who o…" (lineLimit 2), upcoming
  nudge "Pla…" while "Tomorrow 18:30" keeps width (HomeAccessoryStrips:344), "Arran/ge" mid-word, "Cap-/ture/inbox" ×3 lines.
  `typography.md › Supporting Dynamic Type`, `layout.md › Adaptability`.
- **AREAS-01 Crit** Areas 2-col grid never reflows at AX3 ("Relatio…", status wraps 5 lines).
- **HOME-02/AREAS-02 Crit(house)** Settings iconWell 40×40 on both tabs.
- **HOME-03 High** only 3 of 12 sections serve the current task (hero, Due now, due-nudge); "Due now" starts ~1,175pt (1.34
  screens) down behind the ~510pt life-area list; retrospective tail (closed today/week, week review, 2 charts) ≈1.2 screens.
  Default length ≥3,100pt (3.6 screens); AX3 ≥4,700pt. ~50 numbers on the scroll, 11 on screen 1; 5–7 colour families/screen.
  `design-principles.md › Simplicity`, `layout.md › Visual hierarchy`.
- **HOME-04 High** THREE streaks, three rules: closure streak "6 days/Best is 6"; focus "2 Day Streak" (ignores the Settings
  streak switch — never passed showStreaks); nudge "best 2". Streaks default ON; no repair; "Keep it alive today". "3/7
  Active Days" (Q9's own wording) sits beside the contradicting tile. Also: days-active shown 3 ways, week focus total 3×
  ("120 focus minutes", "2h", "2h") over two different weeks, closed tasks counted in 6 places, "4" waiting captures in 3,
  three different 7-day windows, three goals (5 closes/day, 30 focus min/day "57%", per-nudge best).
- **HOME-05 High** StateWarn orange marks INACTIVE areas ("quiet since Tuesday/all week") on Home AND Areas; Growth flagged 3×;
  the same orange also means "due today" and "4 waiting" — one colour, three meanings (`color.md › Best practices`); 3.02 light.
- **HOME-06 High (code)** after ≥7 days away every area turns orange "quiet all week", ring "0 of 5", no Fresh Start.
- **HOME-07 High** loudest button is "Close it" (solid green 54pt) above "Start session" (outline 48pt); first-run hero =
  title + chip only, no next step/time; the "next step" is a free-text note clipped at 2 lines; "due today" also labels
  OVERDUE tasks; not pinned; taps-to-sprint: hero 1, Due now 2 (no ▶), Areas card 3.
- **HOME-08 High** 3 full-width prominent buttons in 2 colours with 3 finish verbs (Close it / Done for now / Clear the deck)
  + the disc. `buttons.md › Style` "Keep the number of prominent buttons to one or two per view".
- **HOME-09 High** two charts of the same focus data, different weeks (calendar Mon–Sun vs rolling Sun–Sat), 3 toggles; the
  trend line's `.catmullRom` overshoots below 0 and above 40 (draws values that never happened); fill not smoothed.
  `charting-data.md › Designing effective charts` (continuity), `› Best practices` (keep simple).
- **HOME-10 High** scores the user never set: first-run "0 of 5 closed" beside "3 items" (unreachable); "30m/day 57%";
  "peak 40m on Wed".
- **AREAS-03 High** Areas repeats Home (same 6 areas, status lines, bars, destination); "2 of 5 tasks closed" then "5 tasks"
  repeats the denominator; FOUR routes to reorder areas (Arrange, "Reorder or add an area", Settings, Tools).
- **AREAS-04 Med** "Where the week went": Home + Money share gold, segments merge with no separator (`charts.md › Color`).
- **HOME-11 Med** analytics cards use SF Mono Title-Case labels vs `sectionLabel()` everywhere else; `.padding(12)`.
- **HOME-12 Med** "Closed this week" 7×8pt bars, no labels, a11y-hidden, duplicates the dot row.
- **What works:** hero buttons 54/48pt mid-screen; Home close has a persistent Undo card; "Due now" rows neutral; honest
  zero-streak copy; charts hide when empty; nothing moves at rest; collapsible life-area list; switches exist (defaults wrong).
- Note: `fr-areas-p1/p2` are actually Journal frames (tab mis-tap) — first-run Areas unframed.

## H. apple-design review — Focus sprint, Live Activity, Tools, Settings, sign-in (sub-agent, HIG-cited)

Rating **Needs work** (no HIG-hard-minimum Criticals; many breaches of E's Q2/Q7/Q8/Q10 + §3 44pt). Thesis sound: one ring
counting down while the app stays quiet.
- **FOCUS-01 High** sprint sheet ≈14 regions, 12 before any control. Q2 "ONLY". `layout.md › Visual hierarchy` (progressive disclosure).
- **FOCUS-02 High** the sheet's controls scroll with content: "Close it" at y≈1,165pt on open (≈290pt below the fold). Q8.
- **FOCUS-03 High** green StateGo "Close it ✓" on the sheet only STOPS the sprint (then "Stop this sprint?" → destructive
  "Stop sprint"); the same label COMPLETES the task on Home/Task Detail; card + LA say red "Stop". One verb, one colour.
- **FOCUS-04 High** extensions differ: card +30s/+5m, sheet +1/+5/+10 min, LA none; "+5m" vs "+5 min".
- **FOCUS-05 High** the card's countdown is `.caption2` 11pt in a ~70pt ring; title 13pt lineLimit(1); controls 12pt.
- **FOCUS-06 High** card Pause 70×44, +30s 69×44, +5m 65×44, Stop 64×44 (unbezelled, 8pt gaps); collapsed Pause 44×44;
  sheet Done 66×36. `accessibility.md › Mobility` (~24pt padding around unbezelled). Q7.
- **FOCUS-07 High** no 5-min heads-up; the in-app checkpoint banner has no haptic (inferred). `feedback.md › Best practices`.
- **FOCUS-08 Med** card Pause/+30s/+5m play NO haptic; the sheet plays the same `.solid` for all five controls.
- **FOCUS-09 Med** 7 jargon terms (checkpoint, nudge, cadence, "Deep entry", "Flow calibration", "Sprint target", "1 of 15
  min logged"); checkpoint ≡ nudge named both ("Next checkpoint in 04:56" card vs "Next nudge in 03:04" sheet); 5 time formats.
- **FOCUS-10 Med** grabber hit region overlaps the collapsed title (tap toggles instead of opening).
- **FOCUS-11 Low** sheet Pause grey-on-grey outline reads disabled.
- **LA-01 High (code)** the Lock Screen **Stop ends the sprint with NO confirmation** (`FocusActivityKitMirror.swift:188` →
  `service.stop()`); Pause/Stop pills ≈34pt tall, 8pt apart. `live-activities.md › Offering interactivity` ("prefer limiting it
  to a single element…"). Q10, Q7.
- **LA-02 High** title truncates "Take a 10-minute w…" at default size; LS countdown has no `timerMaxWidth` (Island passes
  72/56); emoji tile + "FOCUS SPRINT" + dots + caption get space, +5m none.
- **LA-03 Med** no `.widgetURL` on the sprint LA. **LA-04 Med** minimal = emoji only (HIG: Timer shows remaining time).
- **TOOLS-01 Med** empty Routines = 17-word blurb + 35-word body; its "Set up a place" repeats the Places row; AX3: 3 items → 4
  screens. **TOOLS-02 Low** "WORKSHOP" + subtitle above two rows. Life Areas in Settings + Tools is E's recorded call (tension).
- **SET-01 High** Notifications card ≈408pt tall for two 44pt rows (~310pt empty); likely stale LabeledContent height after the
  ProgressView→Label swap (inferred). **SET-02 Med** "Not requested yet" offers only "Open iOS Settings" (no in-place ask).
  **SET-03 Med** Feedback footer ≈17 lines/150 words. **SET-04 Med** "Feedback" also holds location + Arrival nudges; Tag Editor
  after About; 10 sections / 5 screens. **SET-05 High** gear 40×40. **SET-06 Low** "palette… every token" jargon.
- **AUTH-01 High** Sign in / Create account segments don't scale at AX3 (only route to Create account). **AUTH-02 Med** no
  passkey/SIWA (dormant, free account); email field `.emailAddress` not `.username` (AutoFill to verify). **AUTH-03 Low**
  disabled buttons with no reason; "Welcome back." greets new users.
- **Craft:** during a sprint on Tasks the search row + disc + card + tab bar take the bottom ≈290pt (a third of the screen);
  disc/bar settled — the card is the piece this audit can shrink. Orange = "Due today" AND "next checkpoint".
- **What works:** Stop confirm ("Keep going", "Stopping early still logs the minutes you did"); nothing moves at rest;
  finished sprint never lands on an empty screen; collapse/expand have tap twins; separate feedback switches, sounds OFF by
  default; LA doesn't rely on colour alone; sign-in primary at bottom, right textContentType, reveal defaults hidden.
- **Phone checks:** Dynamic Island compact/minimal/expanded; LS countdown width; LA Pause/Stop real hit area + unguarded Stop;
  card haptics; checkpoint haptic/sound with silent switch both ways; Always-On dimming; Passwords AutoFill; Settings gap
  after relaunch.

## I. apple-design review — Tasks, Task detail, Capture fan + composers, Capture Inbox, Journal (sub-agent, HIG-cited)

Rating **Critical issues**. Thesis: "dump it, see it, start it"; the loop leaks.
- **TASKS-01 Crit** Tasks ○ / full swipe close = no confirm, undo or reopen (`TaskRow.swift:14` "closing is one-way" — an
  EARLIER E decision); Home hero close has undo → same action, two behaviours. Delete = hard delete. **Q3 collides with the
  earlier "one-way" call → E must reconcile.** `feedback.md › Best practices`.
- **CAPT-01 Crit** fan → Task composer (full-screen cover) Cancel discards silently (sim-verified); toolbar "+"
  `TaskCreateView` (sheet) also discards on Cancel AND swipe (code). `modality.md › Best practices`. Q4.
- **X-TGT-1 Crit** Tasks toolbar "+" drawn ~44 but hit 27×36; composer tag "Add" 24×14 (<28 HIG minimum).
- **X-AX3 Crit** rows keep side-by-side at AX3: "Amazon par…", "Priya ab…", meta "Home · P3 ·…" (due status lost), "15 min"
  → "min", "Search tas…", Journal "21:…", "cap-/tured". `typography.md › Supporting Dynamic Type` (stacked layout).
- **TASKS-02 High** "12 OPEN" header vs 6 listed in Momentum (first-run 3 vs 1), nothing points to the rest (hiding the tail is
  E's b11 call — the missing pointer is the gap).
- **TASKS-03 High** TWO "+" → two different task composers: toolbar "+" sheet (due, area, place, notes, tags; due defaults "Not
  yet" → a title-only task may not appear on the Momentum board it was added from — code, untried) vs disc → fan → Task
  full-screen cover (effort, area, tags; due FORCED to today).
- **CAPT-02 High** fast-task path hard-codes `dueDate = startOfDay(now)` (`QuickCaptureView.swift:228`) → any fast task not
  closed by midnight is "Overdue" tomorrow. Q9.
- **CAPT-03 High** Task composer shows 16 optional controls; Journal composer 15 — under "no questions asked" copy.
- **CAPT-04 High** copy contradicts: fan "Everything goes to the inbox"; Task tile "Skips the inbox"; inbox "Anything you capture
  lands here first"; a task-kind capture sits in the inbox anyway; destination named "Today" / "your list" / Tasks.
- **INBOX-01 High** "4" shown 4× (segment, "4 left", badge, "Four are still sitting here"); weekly stats twice; 10 decisions per
  card (6 areas + 4 verbs); at AX3 stats fill screen 1, no action until screen 2.
- **INBOX-02 High** pressure framing in StateWarn orange: "decide or bin them", "4 left", "oldest is 12 hours old", "INBOX
  HEALTH"; "bin" isn't on the card. Q9 (+ Fresh Start).
- **TASKS-04 High** "OVERDUE" in the eyebrow even at "0 OVERDUE"; "Overdue" row meta; "Close it — keeps a 6-day streak".
- **TASKS-08 High** detail has two save models ("applies immediately — no Save needed" above a form whose grey Save is 3 screens
  down); "Discard changes?" + swipe-back disabled.
- **JRNL-01 High** Journal keeps text in-session, loses on quit; Task composer keeps nothing — same exit, two outcomes.
- **X-TGT-2 High** <44: detail Back 36×36, composer Cancel 77×36, all 36pt chips (Tasks filters, composer area×7 / tag×5, detail
  tags, Journal filters), Journal "All activity" 38×36.
- **Medium:** TASKS-05 ▶ and ○ centres ~51pt apart (~7pt gap between start and an irreversible close); TASKS-06 Tomorrow rows
  have no ▶ (2 taps); TASKS-07 "0 OPEN · 0 OVERDUE" while loading; X-COLOR accent blue on NON-interactive labels ("TOMORROW",
  "WHERE DOES THIS LIVE?", "THEN", "INBOX HEALTH"), "Life Area" the only blue of four tappable rows; selection green in the Task
  composer vs blue elsewhere; green = Close / Closed / primary; TASKS-09 detail has two filled CTAs (green Close + blue Start) +
  6 durations from "30s" + Seconds/Minutes + nudge stepper + timeline; X-TERMS (Close it/done/Done/Closed; Focus Sprint/sprint/
  session; In-Sprint Nudges vs Nudges; checkpoint; Momentum; P1–P4; triage/Sorted/Skip/Promoted/bin/cleared; Log vs Journal
  filtered as "Written"; "append-only"; "Decide later" vs "No life area"); JRNL-02 three filter systems + three "alls";
  JRNL-03 entries append-only (no edit/delete) — Q3 names only tasks/captures; INBOX-03 disabled "Sorted" looks like enabled
  "Skip"; INBOX-04 promote sheet "Create Task" scrolls away; X-SCROLL options reachable only by horizontal scroll.
- **Low:** X-CAPS mixed button capitalisation ("Task it"/"Save entry"/"Close it" vs "Add to Today"/"Delete Task"/"Keep Editing");
  TASKS-10 `.monospaced()` for ordinary text; CAPT-05 lock glyph beside "Skips the inbox"; INBOX-05 "Capture something"
  duplicates the disc (a trade-off); JRNL-04 no tap Refresh.
- **Tensions (settled):** red Captures badge; "Captu…" truncation; disc covers ~15% of "Sorted" at rest.
- **Craft:** tracked-caps eyebrows mean four things in four colours; every tab opens with a tally before the work — remove the
  metric strips first.
- **What works:** composers pin primary at bottom + disable until text (Q8 template); every choice defaulted, nothing required;
  "One honest line about now is enough."; due-today ▶ 1-tap sprint; ○ tap twin for swipe; triage undo persists (Q3 pattern);
  informational feedback; nothing moves at rest; dark matches light.

## J. More sim-verified (after E's hand entry)

- **TASKS-03 VERIFIED:** Tasks toolbar "+" opens a DIFFERENT "New task" sheet ("When is it due? Not yet / Today / Tomorrow /
  Pick a date"); a task added there with "Not yet" ("Book an eye test") **does not appear on the Momentum board it was added
  from** — the header rose to 11 OPEN, the row is only under "Open". E, asked to use the toolbar "+", reached the disc's quick
  Task composer instead ("Renew passport" saved DUE TODAY — CAPT-02 forced date) → the two "+" doors are confusable.
- **Inbox Undo button is 34×16pt** — the one working forgiveness control is among the smallest targets; the inbox header also
  gains an undo glyph.
- **Home close → in-place green card** "… — closed · Undo | Next: 15 min" (Undo large). Two undo shapes exist: in-place card
  (Today) vs bottom text bar (Inbox).
- **Routines:** arrival notification (via the debug "Simulate arrival", which drives the real handler — sim geofencing did not
  fire from `simctl location`): "You're at Gym · 3 steps ready — Open Fitness · Text Sam Taylor · +1 more. Tap to run." One per
  crossing. Routine screen = ROUTINE eyebrow, "You're at Gym, arrived 41 secs ago", "0 of 3 done", NEXT — STEP 1 OF 3 card with
  one big "Open Fitness" + "Skip this step", later steps listed quietly — **the strongest ADHD pattern in the app** (reference for
  the Today hero). Today shows "AT GYM · ROUTINE LIVE · 3 steps left · Next: Open Fitness · Continue routine".
- **E's hand entry (corrected from E's screenshots):** the Gym has FOUR actions — Open Fitness, Text Sam Taylor, Open
  www.nhs.uk (all on arrival) and Journal "Log today's workout" (when leaving). The requested arrival journal line "Arrived
  at the gym" was not added, and the departure step is a Journal line rather than a Capture. Not evidence against the
  editor's direction control; the Capture-vs-Journal choice may be easy to mix up (unconfirmed). Voice transcript "Remember to ask Freya about the Q4 on Monday" (speech
  recogniser, not the app; the capture shows only the transcript).

## K. Today: alternative ideas (E's side request, 2026-09-19, after round 3 chose "C · One next thing")

These are suggestions, not decisions. Each names the ADHD struggle it serves and its evidence grade (research brief
§), says whether it needs a new capability, and how it fits C.

1. **"Leave by" time card.** When a fixed commitment is ahead, the one card reads "Leave by 14:20 · 1h 50m free · a
   25-min sprint fits".
   - Serves: time blindness and waiting mode. STRONG timing deficit (§5.1, addendum 2).
   - Needs: calendar read (EventKit).
   - Fit with C: it takes the one slot when a commitment is near.
2. **Work sized to the gap.** The card offers a task that fits the time you actually have.
   - Serves: §5.1, addendum 2.
   - Needs: a task estimate field (the round 5 schema question).
3. **Morning first-unlock surface.** The first open after waking shows one pre-chosen first step, with no decisions.
   A routine can be anchored to waking.
   - Serves: sleep inertia, STRONG [gen]; the delayed body clock, MODERATE (addendum 7–8).
   - Needs: wake-event triggers (a Scope C gap).
4. **Evening "tomorrow's first thing".** After a set hour, the card asks one tap: which item from the then-list goes
   first tomorrow. That pre-decides the morning.
   - Serves: implementation intentions, MODERATE (§5.5).
   - Needs: nothing new beyond pinning (round 5).
5. **Resume card.** "You were on 'Reply to Priya', 12 min in · Pick up".
   - Serves: resuming after interruption. The mechanism is MODERATE; there is no ADHD-specific study (§2.5).
   - Needs: sprint pause state, which exists.
6. **Fresh Start greeting.** After 7+ days away, one card: "Welcome back. Start fresh?" One tap moves the backlog
   out of sight. No tallies.
   - Serves: E's Q9 (§5.4, §5.8).
   - Needs: a new flow.
7. **"Not this one" swap.** One tap on the card offers the next suggestion, until you pin one.
   - Serves: working-memory load when choosing (§1.3). Choice paralysis itself is FOLK.
   - Needs: fits E's Q1 "suggested then pinned".
8. **Time you can see.** A thin bar on the card shrinks from now to the next commitment. It reads without numerals.
   - Serves: §5.1 test.
   - Needs: a calendar or a task deadline.
9. **One quiet "done today" line under the card.**
   - Serves: immediate informational feedback (§5.2–5.3).
   - Conflicts slightly with C's "nothing else", so it is optional.
10. **The one card on the Lock Screen.** An accessory widget.
    - Serves: out of sight, out of mind (addendum 1).
    - Needs: a new widget family (a Scope C gap).

**Not recommended:** body-doubling or "work alongside" presence (FOLK/WEAK, §5.7), and energy/mood matching (no
evidence it helps choose tasks; offer it only as an optional filter).
