//
//  HomeView+Today.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday` — E's round 3, *"C · One next thing. Today shows ONE card, then a short
//  'then' list, and nothing else."* This file draws the card and the list from `TodayPlan` and
//  carries the card's actions; the plan itself (what wins the slot) is pure and tested in
//  `TodayPlan`. The done line under the list lives in `HomeWeekReviewRow.swift`, beside the review
//  it opens.
//

import SwiftUI

extension HomeView {
    /// What holds the card and what the list holds, from every input Today has. Computed, not
    /// stored: each input is already observed, so the card can never lag the state it reads.
    var todayPlan: TodayPlan {
        TodayPlan.build(
            openTasks: homeService.openTasks,
            pinnedTaskId: pinnedTaskId,
            skippedTaskIds: skippedTaskIds,
            pausedSprint: TodayPausedSprint.from(status: activeSprint, sprint: widgetSprint),
            hasPlaceCard: liveRoutineRun != nil || arrivalSurface != nil,
            // Round 5a's top rank. `F-F5`'s calendar read is its only possible source.
            leaveBy: nil
        )
    }

    // MARK: - The one card

    @ViewBuilder
    var oneCardSection: some View {
        let plan = todayPlan
        switch plan.slot {
        // E, 2026-09-24: the live-routine card and the arrival card together ARE the one card,
        // unchanged — the veto of 2026-09-04 ("i want it shown") stands.
        case .place: VStack(alignment: .leading, spacing: 16) { arrivalAndRoutineCards }
        case .paused(let sprint):
            TodayPausedCard(sprint: sprint, onResume: onToggleSprintPause)
        case .pinned(let task), .suggested(let task), .leaveBy(_, .some(let task)):
            taskCard(task, slot: plan.slot)
        case .leaveBy(_, .none), .nothing:
            EmptyView()
        }
    }

    private func taskCard(_ task: TaskSummary, slot: TodaySlot) -> some View {
        let isPinned = task.id == pinnedTaskId
        let isLeaveBy: Bool = if case .leaveBy = slot { true } else { false }
        return TodayTaskCard(
            eyebrow: TodayCardCopy.eyebrow(for: slot) ?? "",
            eyebrowIsWarning: isLeaveBy,
            task: task,
            lifeArea: homeService.activeAreas.first { $0.id == task.lifeAreaId },
            isPinned: isPinned,
            offersNotThisOne: slot == .suggested(task),
            showsStart: activeSprint == nil,
            startTitle: TodayCardCopy.startTitle(
                for: task, defaultSprintMinutes: momentumPreferences.defaultSprintMinutes
            ),
            closeTitle: momentumContext(for: task.lifeAreaId).closeButtonTitle,
            loggedTodayLabel: MomentumScoreboard.focusLoggedTodayLabel(sessions: publishedHistory, taskId: task.id),
            isClosing: isClosingTask,
            onTogglePin: { togglePin(task, isPinned: isPinned) },
            onStart: { startSprint(task) },
            onClose: { Task { await closeTask(task) } },
            onNotThisOne: { skip(task) },
            onCommitNextStep: { draft in Task { await saveNextStep(draft, for: task) } }
        )
    }

    /// The same funnel into `RootView`'s app-wide sprint the hero used, so "Start N min" launches
    /// exactly the length it names (`TodayCardCopy.startTitle` resolves it the same way).
    func startSprint(_ task: TaskSummary) {
        onStartFocus?(FocusSprintPlan(
            summary: task,
            lifeArea: homeService.activeAreas.first { $0.id == task.lifeAreaId },
            defaultDurationSeconds: momentumPreferences.defaultSprintMinutes * 60
        ))
    }

    // MARK: - The "then" list

    /// Round 5a: *"Due nudges sit at the top of the 'then' list with a bell"*; then the tasks
    /// `TodayPlan` lists — what is due, a skipped task (*"Back in the list"*), and a pinned task
    /// something else displaced from the card.
    @ViewBuilder
    var thenSection: some View {
        let plan = todayPlan
        let due = nudgesService.dueNudges()
        let nudgesFailed: Bool = if case .failed = nudgesService.state { true } else { false }
        if nudgesFailed || !due.isEmpty || !plan.thenTasks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Then")
                    .sectionLabel()
                    .foregroundStyle(.secondary)
                // A failed load would otherwise read exactly like "nothing due" — say so instead.
                if case .failed(let message) = nudgesService.state {
                    nudgesFailureCard(message)
                }
                ForEach(HomeNudgesSection.cards(due)) { nudge in
                    NudgeDueCard(
                        nudge: nudge,
                        showStreaks: momentumPreferences.showStreaks,
                        showsBell: true,
                        onDismiss: { await nudgesService.dismiss(nudge) }
                    )
                }
                if let overflow = HomeNudgesSection.overflowLine(dueCount: due.count) {
                    Text(overflow)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !plan.thenTasks.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(plan.thenTasks, id: \.id) { task in
                            thenRow(task)
                            if task.id != plan.thenTasks.last?.id {
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
            // `.contain`: an identifier alone on a container is inherited by every descendant, and
            // the nudge cards' own dismiss identifiers would vanish (`captureInboxSortAreaChips`).
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("homeThenSection")
        }
    }

    /// Board `59`'s row: the title, then "🏠 Home · 15 min", then a chevron — each a door into the
    /// task, through the same pushed detail the arrival card's rows use.
    private func thenRow(_ task: TaskSummary) -> some View {
        Button {
            inspectingTask = task
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(Color("LabelPrimary"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let meta = TodayCardCopy.thenMeta(
                        area: homeService.activeAreas.first { $0.id == task.lifeAreaId },
                        focusDurationSeconds: task.focusDurationSeconds
                    ) {
                        Text(meta)
                            .font(.footnote)
                            .foregroundStyle(Color("LabelSecondary"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("homeThenRow-\(task.id)")
    }

    // MARK: - The card's choices: the pin and "Not this one"

    /// Re-read from the per-account stores: on appear, on returning to the app (a new day drops
    /// yesterday's skips), and straight after every write, so the card answers the tap it got.
    /// With no signed-in user there is nothing to key on, so there is nothing pinned or skipped.
    func refreshTodayChoices() {
        guard let uid = authService.signedInUser?.id.uuidString else {
            pinnedTaskId = nil
            skippedTaskIds = []
            return
        }
        pinnedTaskId = TodayPinStore.pinnedTaskId(uid: uid)
        skippedTaskIds = TodaySkipStore.skippedTaskIds(uid: uid)
    }

    private func togglePin(_ task: TaskSummary, isPinned: Bool) {
        guard let uid = authService.signedInUser?.id.uuidString else { return }
        if isPinned {
            TodayPinStore.unpin(uid: uid)
        } else {
            TodayPinStore.pin(task.id, uid: uid)
        }
        refreshTodayChoices()
    }

    private func skip(_ task: TaskSummary) {
        guard let uid = authService.signedInUser?.id.uuidString else { return }
        TodaySkipStore.skip(task.id, uid: uid)
        refreshTodayChoices()
    }

    // MARK: - The next step, edited on the card

    /// Writes only when the line changed (`TodayNextStep.payload`), then reloads Today so the card
    /// and the list show what is stored. A failure surfaces through the same alert as a failed
    /// close — the card is where the user was.
    func saveNextStep(_ draft: String, for task: TaskSummary) async {
        guard let payload = TodayNextStep.payload(draft: draft, current: task.nextStep) else { return }
        do {
            _ = try await taskDetailClient.updateTask(id: task.id, payload: payload)
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
