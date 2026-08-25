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
                onClose: { Task { await closeTask(task) } },
                onStartSession: { onStartFocus?(FocusSprintPlan(summary: task, lifeArea: area)) }
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
        let dueNudges = nudgesService.dueNudges()
        if !dueNow.isEmpty || !dueNudges.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Due now")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(dueNow, id: \.id) { task in
                        dueNowRow(task)
                        if task.id != dueNow.last?.id || !dueNudges.isEmpty {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    if !dueNudges.isEmpty {
                        nudgesWaitingRow(dueNudges)
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

    /// v3's "Nudges waiting" row: the count in warn, the labels as metadata, and the chevron
    /// crossing to the Nudges tab — dismissal happens there now, not inline on Today.
    func nudgesWaitingRow(_ due: [Nudge]) -> some View {
        HStack(spacing: 8) {
            MomentumChip(
                text: "\(due.count) due",
                background: Color("CardSurfaceSecondary"),
                foreground: Color("StateWarn")
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Nudges waiting")
                    .font(.callout)
                Text(due.map(\.label).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
        .onTapGesture { onOpenNudges?() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Nudges waiting, \(due.count) due")
        .accessibilityIdentifier("homeNudgesWaitingRow")
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

    /// Inline section-header row directly above the grid: a "Life Areas" title and a trailing text
    /// button reading "Arrange" / "Done". Deliberately NOT a toolbar item — the toolbar carries
    /// screen-level navigation (`inboxButton`, `settingsButton`), and a content-mutating mode control
    /// belongs beside the content it mutates. A real text label, never a third competing glyph (§4).
    @ViewBuilder
    func lifeAreasHeader(activeAreas: [LifeArea], showArrangeControl: Bool) -> some View {
        HStack {
            Text("Your life areas")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Spacer()
            if showArrangeControl {
                Button {
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
        }
    }

    /// v3's life-areas block: the caps header with the Arrange control, the explainer, and the
    /// rows themselves.
    @ViewBuilder
    func lifeAreasSection(activeAreas: [LifeArea]) -> some View {
        lifeAreasHeader(activeAreas: activeAreas, showArrangeControl: activeAreas.count >= 2)
        Text("How many of each area's tasks you have closed this week. Tap one to work inside it.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        AreaMomentumList(items: MomentumScoreboard.areaMomentum(
            areas: activeAreas, openTasks: homeService.openTasks, allTasks: homeService.allTasks
        ))
    }

    func refreshInboxCount() async {
        inboxCount = (try? await captureClient.fetchUnprocessedCaptures().count) ?? inboxCount
        await refreshClearedCaptureCount()
    }

    /// Two extra fetches, gated on the toggle and failure-tolerant like every scoreboard input —
    /// the ring reads 0 extra rather than the screen failing.
    func refreshClearedCaptureCount() async {
        guard momentumPreferences.countClearedCaptures else {
            capturesClearedToday = 0
            return
        }
        async let seen = captureClient.fetchSeenCaptures()
        async let processed = captureClient.fetchProcessedCaptures()
        let cleared = ((try? await seen) ?? []) + ((try? await processed) ?? [])
        capturesClearedToday = MomentumScoreboard.clearedToday(captures: cleared)
    }

    /// The Due-now push's destination, with the S3 Momentum context built from the history Home
    /// already holds.
    func inspectedTaskDetail(_ task: TaskSummary) -> some View {
        TaskDetailView(
            taskId: task.id,
            lifeAreas: homeService.lifeAreas,
            client: taskDetailClient,
            schedulingClient: schedulingClient,
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
    var weekReviewRow: some View {
        Button {
            isPresentingWeekReview = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.accentColor)
                Text("Week review")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier("homeWeekReviewRow")
    }

    var weekReviewDestination: some View {
        WeekReviewView(
            review: MomentumWeekReview.build(
                tasks: homeService.allTasks,
                lifeAreas: homeService.lifeAreas,
                sessions: publishedHistory,
                inboxCount: inboxCount
            ),
            summaryCounts: WeekReviewSummaryCounts(
                open: homeService.openTasks.count,
                areas: homeService.activeAreas.count,
                inbox: inboxCount,
                dueNudges: nudgesService.dueNudges().count
            )
        )
    }
}
