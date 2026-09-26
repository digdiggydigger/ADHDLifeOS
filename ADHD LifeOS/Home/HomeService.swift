//
//  HomeService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

enum HomeLoadState: Equatable {
    case loading
    case loaded([LifeAreaTaskCount])
    case failed(String)
}

enum HomeServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

@MainActor
final class HomeService: ObservableObject {
    @Published private(set) var state: HomeLoadState = .loading

    private let client: HomeClientAdapting

    /// The FULL fetched set including archived areas. Today's own reads use `activeAreas`;
    /// the Capture triage picker (fed from Home) needs the archived ones too, so they are kept here
    /// rather than filtered away in the adapter — the same over-eager filter previously starved that
    /// picker of archived areas entirely.
    private(set) var lifeAreas: [LifeArea] = []

    /// The open tasks behind the counts, retained for Today's one card (`TodayPlan`). `@Published`
    /// so the card re-renders when a reload changes what leads it.
    @Published private(set) var openTasks: [TaskSummary] = []

    /// Every task, closed ones included — the Momentum scoreboard's raw material. Failure-
    /// tolerant on load: the scoreboard is derived decoration over history, and its fetch failing
    /// must never take the screen down with it.
    ///
    /// A failure KEEPS the last-known set rather than emptying it, matching the inbox's
    /// `CaptureInboxService.refresh()`. An emptied list is not "don't know", it is the positive
    /// claim "there are no tasks", and every consumer downstream believes it — the Momentum ring,
    /// the streaks, the week charts, and loudest of all the Home arrival card, which Home
    /// refreshes deliberately AFTER this load. `ArrivalSurface.refreshed` re-checks the card it
    /// is holding against these tasks and cannot tell "the work here closed" from "the fetch
    /// failed", so a wiped list silently destroyed a card the user was looking at.
    @Published private(set) var allTasks: [TaskItem] = []

    init(client: HomeClientAdapting) {
        self.client = client
    }

    /// Active areas in sort order.
    var activeAreas: [LifeArea] {
        lifeAreas.filter { !$0.archived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func load() async {
        // Quiet reload (SUGG-b4): only the FIRST load may show the loading state — once content
        // is on screen, a refetch (pull, or the app-wide DataChangeSignal) replaces it in place
        // instead of flashing it away.
        if case .loaded = state {} else { state = .loading }
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let openTasksResult = client.fetchOpenTasks()
            async let allTasksResult = client.fetchAllTasks()
            lifeAreas = try await lifeAreasResult
            openTasks = try await openTasksResult
            if let fetchedAllTasks = try? await allTasksResult { allTasks = fetchedAllTasks }
            // The grid excludes archived areas — the filter is applied HERE, at the view/service
            // layer, not in the adapter.
            let counts = LifeAreaTaskCounts.countOpenTasksByLifeArea(
                lifeAreas: lifeAreas.filter { !$0.archived },
                tasks: openTasks
            )
            state = .loaded(counts)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
