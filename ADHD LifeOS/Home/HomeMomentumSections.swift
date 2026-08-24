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
                ClosureCelebrationCard(
                    taskTitle: celebrated.title,
                    closedTodayCount: closedToday.count,
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

    var scoreboardSection: some View {
        MomentumRingCard(
            closedToday: closedToday.count,
            goal: MomentumScoreboard.defaultDailyGoal,
            streak: MomentumScoreboard.streak(tasks: homeService.allTasks),
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
        if !dueNow.isEmpty {
            Text("Due now")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(dueNow, id: \.id) { task in
                    dueNowRow(task)
                }
            }
            .bentoCard()
        }
    }

    func dueNowRow(_ task: TaskSummary) -> some View {
        HStack(spacing: 8) {
            if let effort = MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds) {
                Text(effort)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
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
        .frame(minHeight: 44)
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
            Text("Life Areas")
                .font(.headline)
            Spacer()
            if showArrangeControl {
                Button(isArranging ? "Done" : "Arrange") {
                    if isArranging {
                        isArranging = false
                        Task { await homeService.load() }
                    } else {
                        arrangeAreas = activeAreas
                        isArranging = true
                    }
                }
                .font(.body.weight(.semibold))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("homeArrangeButton")
            }
        }
    }
}
