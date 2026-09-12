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
                    onNext: { setCelebratedTask(nil) }
                )
                .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
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
            ),
            onRingOrigin: { ringOrigin = $0 }
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

    // MARK: - The closure card's arrival

    /// E's #8: the card springs in instead of appearing unanimated. The house pattern is
    /// `Capture/CaptureFanOverlay.swift:89-97` — under Reduce Motion the spring is replaced by
    /// a plain ease, not removed, because §7.2's rule for something that APPEARS is to swap
    /// motion for a fade rather than to strip the feedback. Paired with the card's
    /// opacity-only transition, the first reduced frame is already at final geometry and only
    /// the fade travels (the opening-pose rule).
    var closureCardAnimation: Animation {
        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// The ONLY writer of `celebratedTask`. Three paths move it — the card's Next, a close
    /// from Home, and Undo — and a transition only runs if every one of them is animated, so
    /// they share a setter rather than each remembering to wrap itself.
    func setCelebratedTask(_ task: TaskSummary?) {
        withAnimation(closureCardAnimation) { celebratedTask = task }
    }

    // MARK: - Close-from-Home

    func closeTask(_ task: TaskSummary) async {
        guard !isClosingTask else { return }
        isClosingTask = true
        defer { isClosingTask = false }
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .done)
            setCelebratedTask(task)
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func undoClose(_ task: TaskSummary) async {
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .open)
            setCelebratedTask(nil)
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
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
        let seenCaptures = try? await seen
        let processedCaptures = try? await processed
        let cleared = (seenCaptures ?? []) + (processedCaptures ?? [])
        let handledToday = MomentumScoreboard.clearedToday(captures: cleared)
        inboxHandledToday = handledToday
        capturesClearedToday = momentumPreferences.countClearedCaptures ? handledToday : 0
        // The card keeps showing whatever it can, exactly as before — but the daily goal has to
        // know the difference between "nothing cleared today" and "the fetch failed", because a
        // dip and its recovery look like a rise across the goal.
        hasLoadedClearedCaptures = seenCaptures != nil && processedCaptures != nil
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
