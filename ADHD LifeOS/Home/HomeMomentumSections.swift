//
//  HomeMomentumSections.swift
//  ADHD LifeOS
//
//  HomeView's daily counts and the close-from-Today flow, in their own file so the view stays
//  inside its type-body budget (the `HomeAccessoryStrips` arrangement). The state and clients these
//  touch are internal on `HomeView` for exactly this split.
//
//  `F-E3-OneCardToday` moved the drawing out: the ring, the Best-next-move card, "Due now" and the
//  week chart gave way to the one card, the "then" list and the done line (`HomeView+Today`,
//  `HomeWeekReviewRow`). What stays here is what those read: the counts, the close, the arrival
//  refresh, and the ONE `MomentumTaskContext` build both Task Detail and the card take Close's
//  words from.
//

import SwiftUI

extension HomeView {
    var closedToday: [TaskItem] {
        TaskCompletionStamp.completedTasks(in: homeService.allTasks)
    }

    /// M7: captures whose exit stamp is today, feeding the ring when the Settings toggle counts
    /// them — 0 whenever it is off.
    ///
    /// **Computed, not stored, and that is the whole point.** It was `@State`, written only by
    /// `refreshClearedCaptureCount`'s two fetches; so flipping "count cleared captures" moved the
    /// ring's RULES immediately and its COUNT only when the next `DataChangeSignal` refresh landed.
    /// `DailyGoalTracker` re-baselines when the rules change, which is right — but on that first
    /// tick the count was still the stale one, and the refresh arriving afterwards looked like a
    /// rise across the goal under rules that already matched. A Settings toggle then bought a
    /// full-screen celebration. Reading the toggle here, off the ungated `inboxHandledToday`, puts
    /// the rule and the number in the same render — exactly as `nudgesDismissedToday` already did.
    var capturesClearedToday: Int {
        momentumPreferences.countClearedCaptures ? inboxHandledToday : 0
    }

    /// The ring's nudge contribution (M9): derived straight from the nudge list Home already
    /// observes — no extra fetch, and a failed load reads as 0 extra, like every scoreboard
    /// input. Recomputes live when a dismissal lands because `NudgesService` republishes.
    var nudgesDismissedToday: Int {
        guard momentumPreferences.countNudges else { return 0 }
        return MomentumScoreboard.dismissedToday(nudges: nudgesService.nudges)
    }

    // MARK: - Close-from-Today

    /// **Recorded AFTER the write lands, and this is the one site of the five that waits.** The
    /// other four are optimistic — their row flips before the network answers, so a capsule that
    /// waited would arrive after the thing it names had gone. Home is not: the card's Close holds
    /// a spinner (`isClosingTask`) until the write returns and surfaces `closeTaskErrorMessage` if
    /// it fails, so a capsule offered on the optimistic edge would sit beside an error saying the
    /// close never happened. Recording on success is what the user is already being shown.
    func closeTask(_ task: TaskSummary) async {
        guard !isClosingTask else { return }
        isClosingTask = true
        defer { isClosingTask = false }
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .done)
            recordAction.record(
                RecentAction(kind: .taskClosed, subject: task.title) { await undoClose(task) }
            )
            await homeService.load()
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// The capsule's way back. **Reopening was never new capability here** — this method predates
    /// `F-C1-UndoCapsule` and drove the retired closure card's own Undo button; all that changed
    /// is who calls it. A pinned task closed and then undone comes back PINNED: the pin is left in
    /// its store on a close (`TodayPlan`).
    @discardableResult
    func undoClose(_ task: TaskSummary) async -> Bool {
        do {
            _ = try await taskDetailClient.updateStatus(id: task.id, status: .open)
            await homeService.load()
            return true
        } catch {
            closeTaskErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func refreshInboxCount() async {
        // The week review's summary counts the waiting captures; a failure keeps the last known.
        if let waiting = try? await captureClient.fetchUnprocessedCaptures() {
            inboxCount = waiting.count
        }
        await refreshClearedCaptureCount()
        // `F-E1`: the chain's journal signal is Home-only too, and rides every path that refreshes
        // the captures — so no reload can bring one signal up to date and leave the other stale.
        await refreshJournalLines()
    }

    /// Two extra fetches, failure-tolerant like every scoreboard input. Ungated: the Settings
    /// toggle governs what COUNTS toward the daily goal, and the chain reads the stamps regardless.
    func refreshClearedCaptureCount() async {
        async let seen = captureClient.fetchSeenCaptures()
        async let processed = captureClient.fetchProcessedCaptures()
        let seenCaptures = try? await seen
        let processedCaptures = try? await processed
        let cleared = (seenCaptures ?? []) + (processedCaptures ?? [])
        inboxHandledToday = MomentumScoreboard.clearedToday(captures: cleared)
        // A fetch that failed outright keeps the last known stamps rather than erasing a day.
        if seenCaptures != nil || processedCaptures != nil {
            clearedCaptureStamps = cleared.compactMap(\.clearedAt)
        }
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

    /// An arrival-card row is a door into its task, through the same pushed detail the "then"
    /// rows use — projected down to the `TaskSummary` that destination expects.
    func openArrivalTask(_ task: TaskItem) {
        inspectingTask = TaskSummary(
            id: task.id, lifeAreaId: task.lifeAreaId, status: task.status,
            title: task.title, priority: task.priority, dueDate: task.dueDate,
            focusDurationSeconds: task.focusDurationSeconds, nudgesCount: task.nudgesCount,
            nextStep: task.nextStep
        )
    }

    /// The pushed task detail's destination, with the S3 Momentum context built from the history
    /// Home already holds.
    func inspectedTaskDetail(_ task: TaskSummary) -> some View {
        TaskDetailView(
            taskId: task.id,
            lifeAreas: homeService.lifeAreas,
            client: taskDetailClient,
            onStartFocus: onStartFocus,
            momentumContext: momentumContext(for: task.lifeAreaId)
        ) {
            Task { await homeService.load() }
        }
    }

    /// Home's ONE Momentum context build (`WeeklyChainCallSiteTests` counts the doors by file).
    /// Task Detail takes its area line from it and the one card takes Close's words from it, so
    /// "Close it — makes today count" reads the same on both (`F-E1`'s hand-off to `F-E3`).
    func momentumContext(for lifeAreaId: UUID?) -> MomentumTaskContext.Context {
        MomentumTaskContext.build(
            lifeAreaId: lifeAreaId,
            tasks: homeService.allTasks,
            lifeAreas: homeService.lifeAreas,
            showStreaks: momentumPreferences.showStreaks,
            hasCountedToday: hasCountedToday
        )
    }
}
