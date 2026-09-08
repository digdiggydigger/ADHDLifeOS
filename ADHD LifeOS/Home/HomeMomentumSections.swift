//
//  HomeMomentumSections.swift
//  ADHD LifeOS
//
//  HomeView's Momentum scoreboard sections and the close-from-Home flow, in their own file so the
//  view stays inside its type-body budget (the `HomeAccessoryStrips` arrangement). The state and
//  clients these touch are internal on `HomeView` for exactly this split.
//

import SwiftUI

extension HomeView {
    var momentumLeadSection: some View {
        Group {
            if let celebrated = celebratedTask {
                let area = homeService.activeAreas.first { $0.id == celebrated.lifeAreaId }
                let momentum = area.flatMap {
                    MomentumScoreboard.areaMomentum(
                        areas: [$0], openTasks: homeService.openTasks, allTasks: homeService.allTasks
                    ).first
                }
                ClosureCelebrationCard(
                    taskTitle: celebrated.title,
                    line: MomentumScoreboard.celebrationLine(
                        closedTodayCount: closedToday.count,
                        areaName: area?.name,
                        areaRate: momentum?.rate
                    ),
                    nextLabel: MomentumScoreboard.nextButtonLabel(
                        effortSeconds: MomentumScoreboard.bestNextMove(
                            in: homeService.openTasks
                        )?.focusDurationSeconds
                    ),
                    onUndo: { Task { await undoClose(celebrated) } },
                    onNext: { celebratedTask = nil }
                )
            } else {
                bestNextMoveSection
            }
        }
    }

    var closedToday: [TaskItem] {
        TaskCompletionStamp.completedTasks(in: homeService.allTasks)
    }

    /// The ring's nudge contribution (M9): derived straight from the nudge list Home already
    /// observes — no extra fetch, and a failed load reads as 0 extra, like every scoreboard
    /// input. Recomputes live when a dismissal lands because `NudgesService` republishes.
    var nudgesDismissedToday: Int {
        guard momentumPreferences.countNudges else { return 0 }
        return MomentumScoreboard.dismissedToday(nudges: nudgesService.nudges)
    }

    /// The concept's `chartsOn` Today chart: closures per trailing day with the focus-minute
    /// counterweight underneath. Hidden while the week is empty — a flat rail is noise, not
    /// evidence — and gated on the Settings toggle.
    @ViewBuilder
    var closedWeekChartSection: some View {
        let counts = MomentumWeekCharts.closedPerDay(tasks: homeService.allTasks)
        if momentumPreferences.showCharts, counts.contains(where: { $0 > 0 }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Closed this week · \(counts.reduce(0, +))")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    WeekBarStrip(
                        fractions: MomentumWeekCharts.barFractions(counts),
                        barColor: Color("StateGoVivid")
                    )
                    Text(MomentumWeekCharts.closedCaption(sessions: publishedHistory))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .bentoCard()
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("homeClosedWeekChart")
        }
    }

    var scoreboardSection: some View {
        MomentumRingCard(
            closedToday: closedToday.count + capturesClearedToday + nudgesDismissedToday,
            goal: momentumPreferences.dailyGoal,
            // Streaks off keeps every number but stops counting consecutive days — rendering the
            // "still open" counterweight is exactly what a zero streak already does.
            streak: momentumPreferences.showStreaks
                ? MomentumScoreboard.streak(tasks: homeService.allTasks)
                : 0,
            bestStreak: momentumPreferences.showStreaks
                ? MomentumScoreboard.bestStreak(tasks: homeService.allTasks)
                : 0,
            openCount: homeService.openTasks.count,
            weekFlags: MomentumScoreboard.trailingWeekClosureFlags(tasks: homeService.allTasks),
            nextEffortLabel: MomentumScoreboard.effortLabel(
                seconds: MomentumScoreboard.bestNextMove(in: homeService.openTasks)?.focusDurationSeconds
            )
        )
        // Un-carded, so nothing holds it apart from the cards above and below: 8 here plus
        // Today's 16 stack gap is §2's 24pt macro separation on both sides (E, round-2 walk).
        .padding(.vertical, 8)
    }

    /// The Active Goal hero's successor: same top-task slot and the same start-session funnel
    /// into `RootView`'s `FocusSessionService`, plus the concept's close-it-from-here. Start is
    /// hidden while any sprint is running — this card must not offer a second one over the top.
    @ViewBuilder
    var bestNextMoveSection: some View {
        if let task = MomentumScoreboard.bestNextMove(in: homeService.openTasks) {
            let area = homeService.activeAreas.first { $0.id == task.lifeAreaId }
            BestNextMoveCard(
                task: task,
                lifeArea: area,
                isDueNow: task.dueDate.map { due in
                    Calendar.current.startOfDay(for: due) <= Calendar.current.startOfDay(for: .now)
                } ?? false,
                isClosing: isClosingTask,
                showsStartSession: activeSprint == nil,
                // Rides the same history the analytics charts read (`publishedHistory`), which
                // refetches on every finished sprint — including one settled from a dead launch,
                // because the offline path bumps `completedSprintCount` too (b10).
                loggedTodayLabel: MomentumScoreboard.focusLoggedTodayLabel(
                    sessions: publishedHistory,
                    taskId: task.id
                ),
                onClose: { Task { await closeTask(task) } },
                onStartSession: {
                    onStartFocus?(FocusSprintPlan(
                        summary: task, lifeArea: area,
                        defaultDurationSeconds: momentumPreferences.defaultSprintMinutes * 60
                    ))
                }
            )
        }
    }

    /// Open tasks already due (today or overdue), the concept's "Due now" — each row pushes the
    /// task detail. Excludes whichever task the Best-next-move card is already headlining.
    @ViewBuilder
    var dueNowSection: some View {
        let headline = celebratedTask == nil
            ? MomentumScoreboard.bestNextMove(in: homeService.openTasks)?.id
            : nil
        let today = Calendar.current.startOfDay(for: .now)
        let dueNow = homeService.openTasks.filter { task in
            guard task.id != headline, let due = task.dueDate else { return false }
            return Calendar.current.startOfDay(for: due) <= today
        }
        // Nudges left this card when they left the tab bar: a due nudge is now its own dismissable
        // card in `nudgesSection` below, not a chevron row promising a screen that no longer exists.
        if !dueNow.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Due now")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(dueNow, id: \.id) { task in
                        dueNowRow(task)
                        if task.id != dueNow.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    func dueNowRow(_ task: TaskSummary) -> some View {
        HStack(spacing: 8) {
            if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                MomentumChip(
                    text: effort,
                    background: Color("CardSurfaceSecondary"),
                    foreground: Color("LabelSecondary")
                )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(2)
                if let area = homeService.activeAreas.first(where: { $0.id == task.lifeAreaId }) {
                    Text("\(area.colour) \(area.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        .onTapGesture { inspectingTask = task }
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("homeDueNowRow-\(task.id)")
    }

    // MARK: - Close-from-Home

    func closeTask(_ task: TaskSummary) async {
        guard !isClosingTask else { return }
        isClosingTask = true
        defer { isClosingTask = false }
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .done)
            celebratedTask = task
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func undoClose(_ task: TaskSummary) async {
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .open)
            celebratedTask = nil
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// The reorder-mode toggle, as the collapsible header's trailing control. Arrange mode is
    /// still reached from here and nowhere else.
    @ViewBuilder
    func arrangeControl(activeAreas: [LifeArea], isVisible: Bool) -> some View {
        if isVisible {
            arrangeButton(activeAreas: activeAreas)
        }
    }

    /// The plain (non-folding) header, still used by ARRANGE mode, where the section is forced
    /// open and a fold control would be a contradiction.
    ///
    /// Deliberately NOT a toolbar item — the toolbar carries screen-level navigation, and a
    /// content-mutating mode control belongs beside the content it mutates. A real text label,
    /// never a third competing glyph (§4).
    func lifeAreasHeader(activeAreas: [LifeArea], showArrangeControl: Bool) -> some View {
        HStack {
            Text("Your life areas")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Spacer()
            if showArrangeControl {
                arrangeButton(activeAreas: activeAreas)
            }
        }
    }

    func arrangeButton(activeAreas: [LifeArea]) -> some View {
        Button {
            // 27. Arrange mode is a mode change, not a write — light either way.
            Haptics.play(.light)
            if isArranging {
                isArranging = false
                Task { await homeService.load() }
            } else {
                arrangeAreas = activeAreas
                isArranging = true
            }
        } label: {
            Label(
                isArranging ? "Done" : "Arrange",
                systemImage: isArranging ? "checkmark" : "arrow.up.arrow.down"
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isArranging ? AreaPalette.work.onColor : Color.accentColor)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                isArranging ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.cardSurface),
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(Color.cardBorder, lineWidth: isArranging ? 0 : 1))
            .contentShape(Capsule())
        }
        .accessibilityIdentifier("homeArrangeButton")
    }

    /// v3's life-areas block: the caps header with the Arrange control, the explainer, and the
    /// rows themselves — and, since E's 2026-08-28 note, a fold.
    ///
    /// This is the tallest thing on Today, and folding it is how the rest of the screen comes back
    /// within reach; the nudges section below it already sits under the fold on a 6.3" phone. The
    /// header keeps saying what it hid, so collapsing is not the same as losing it.
    ///
    /// The state is a stored preference rather than `@State`: you fold this because you do not
    /// want to see it, and having it spring back open on the next launch would defeat the point.
    /// Arrange mode force-expands — reordering rows you cannot see is not a mode worth allowing.
    @ViewBuilder
    func lifeAreasSection(activeAreas: [LifeArea]) -> some View {
        let items = MomentumScoreboard.areaMomentum(
            areas: activeAreas, openTasks: homeService.openTasks, allTasks: homeService.allTasks
        )
        let isExpanded = !lifeAreasCollapsed || isArranging
        CollapsibleSectionHeader(
            title: "Your life areas",
            summary: HomeLifeAreasSection.collapsedLine(items: items),
            isExpanded: isExpanded,
            onToggle: { lifeAreasCollapsed.toggle() },
            trailing: {
                arrangeControl(
                    activeAreas: activeAreas,
                    isVisible: HomeLifeAreasSection.showsArrangeControl(
                        areaCount: activeAreas.count, isExpanded: isExpanded
                    )
                )
            }
        )
        .accessibilityIdentifier("homeLifeAreasHeader")
        if isExpanded {
            Text("How many of each area's tasks you have closed this week. Tap one to work inside it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            AreaMomentumList(items: items)
        }
    }

    func refreshInboxCount() async {
        // One fetch feeds both the header badge and Today's inbox card; failure keeps the last
        // known state rather than blanking a card the user was just looking at.
        if let waiting = try? await captureClient.fetchUnprocessedCaptures() {
            inboxCount = waiting.count
            inboxPeek = HomeInboxPeek.peek(waiting)
        }
        await refreshClearedCaptureCount()
    }

    /// Two extra fetches, failure-tolerant like every scoreboard input. No longer gated on the
    /// toggle — Today's inbox card names the day's throughput regardless (E's 2026-08-25
    /// follow-up); the toggle still governs what COUNTS toward the ring, exactly as before.
    func refreshClearedCaptureCount() async {
        async let seen = captureClient.fetchSeenCaptures()
        async let processed = captureClient.fetchProcessedCaptures()
        let cleared = ((try? await seen) ?? []) + ((try? await processed) ?? [])
        let handledToday = MomentumScoreboard.clearedToday(captures: cleared)
        inboxHandledToday = handledToday
        capturesClearedToday = momentumPreferences.countClearedCaptures ? handledToday : 0
    }

    /// Variation B's resolution (block 4c): one When-In-Use fix, applied to the card ALREADY
    /// showing rather than rebuilt from nothing (E's 2026-09-08 bug — a pull threw the card
    /// away). `ArrivalSurface.refreshed` holds the rule; see its doc comment.
    func refreshArrivalSurface() async {
        // FIRST, before the location await. The routine card is the other half of the same
        // "where am I right now" slot and shares every trigger — but it is a synchronous
        // UserDefaults read, and sequencing it behind a CoreLocation fix made a finished
        // routine's card linger on Today for as long as that fix took (caught by the routine
        // journey, which is exactly the class of bug a render loop exists to find).
        refreshLiveRoutine()
        let fix = await CurrentPlaceResolution.current()
        arrivalSurface = ArrivalSurface.refreshed(previous: arrivalSurface, fix: fix, tasks: homeService.allTasks)
    }

    /// An arrival-card row is a door into its task, through the same pushed detail the Due-now
    /// rows use — projected down to the `TaskSummary` that destination expects.
    func openArrivalTask(_ task: TaskItem) {
        inspectingTask = TaskSummary(
            id: task.id, lifeAreaId: task.lifeAreaId, status: task.status,
            title: task.title, priority: task.priority, dueDate: task.dueDate,
            focusDurationSeconds: task.focusDurationSeconds, nudgesCount: task.nudgesCount
        )
    }

    /// The Due-now push's destination, with the S3 Momentum context built from the history Home
    /// already holds.
    func inspectedTaskDetail(_ task: TaskSummary) -> some View {
        TaskDetailView(
            taskId: task.id,
            lifeAreas: homeService.lifeAreas,
            client: taskDetailClient,
            onStartFocus: onStartFocus,
            momentumContext: MomentumTaskContext.build(
                lifeAreaId: task.lifeAreaId,
                tasks: homeService.allTasks,
                lifeAreas: homeService.lifeAreas,
                showStreaks: momentumPreferences.showStreaks
            )
        ) {
            Task { await homeService.load() }
        }
    }

    /// The S5 entry point: one quiet row under the daily card — the review derives on demand,
    /// so it is always available rather than gated to Sunday (the concept's Sunday cadence
    /// governed AI generation, which stayed with the daily card).
}
