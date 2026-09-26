//
//  AreasService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// The Areas tab's screen state — a presentation service over the EXISTING client seams
/// (home, journal, capture); no new adapters, per the redesign's views-only line. Areas and
/// tasks are load-bearing (their failure fails the screen); logs and captures degrade to zero
/// like every scoreboard input.
@MainActor
final class AreasService: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([AreasGrid.Item])
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    /// Every capture still waiting — the header badge.
    @Published private(set) var inboxCount = 0
    /// The waiting captures with no area — the "Unfiled" card.
    @Published private(set) var unfiledCount = 0
    @Published private(set) var weekShare: AreasGrid.WeekShare?
    /// The full unarchived set, for pushes that need it (detail, triage picker).
    @Published private(set) var lifeAreas: [LifeArea] = []
    /// `F-E3-OneCardToday`: what the last load fetched and used only for the grid, kept for the
    /// Week review door so it opens without refetching them.
    private var allTasks: [TaskItem] = []
    private var openTaskCount = 0
    private var activeAreaCount = 0

    private let homeClient: HomeClientAdapting
    private let journalClient: JournalClientAdapting?
    private let captureClient: CaptureClientAdapting
    /// Read only when the Week review door is used, for the summary's due count. `nil` (previews,
    /// most tests) counts nothing due.
    private let nudgesClient: NudgesClientAdapting?
    /// The Settings focus goal, read when the Week review door is used (`F-E4`): the review's one
    /// chart draws its goal bar only for a set goal, as Today's door does.
    private let preferencesStore: MomentumPreferencesStoring

    init(
        homeClient: HomeClientAdapting,
        journalClient: JournalClientAdapting?,
        captureClient: CaptureClientAdapting,
        nudgesClient: NudgesClientAdapting? = nil,
        preferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        self.homeClient = homeClient
        self.journalClient = journalClient
        self.captureClient = captureClient
        self.nudgesClient = nudgesClient
        self.preferencesStore = preferencesStore
    }

    func load() async {
        do {
            async let fetchedAreas = homeClient.fetchLifeAreas()
            async let openTasks = homeClient.fetchOpenTasks()
            async let allTasks = homeClient.fetchAllTasks()
            let (areas, open, all) = try await (fetchedAreas, openTasks, allTasks)
            let active = areas
                .filter { !$0.archived }
                .sorted { $0.sortOrder < $1.sortOrder }
            let logs: [Log]
            if let journalClient {
                logs = (try? await journalClient.fetchLogs()) ?? []
            } else {
                logs = []
            }
            let captures = (try? await captureClient.fetchUnprocessedCaptures()) ?? []
            lifeAreas = areas
            self.allTasks = all
            openTaskCount = open.count
            activeAreaCount = active.count
            inboxCount = captures.count
            unfiledCount = AreasGrid.unfiledCount(captures: captures)
            weekShare = AreasGrid.weekShare(areas: active, allTasks: all)
            state = .loaded(AreasGrid.build(
                areas: active, openTasks: open, allTasks: all, logs: logs, captures: captures
            ))
        } catch {
            state = .failed(
                (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            )
        }
    }

    /// Round 5b's second Week review door (*"AND a row sits at the top of the Areas tab"*). The two
    /// streams this tab never needed — focus sessions and nudges — are read HERE, when the door is
    /// used, not on every refresh of the tab; like every garnish, a failed read counts as empty.
    func weekReviewInputs(asOf now: Date = .now) async -> WeekReviewInputs {
        async let fetchedSessions = journalClient?.fetchFocusSessions()
        async let fetchedNudges = nudgesClient?.fetchNudges()
        let sessions = (try? await fetchedSessions) ?? []
        let nudges = (try? await fetchedNudges) ?? []
        return WeekReviewInputs(
            tasks: allTasks,
            lifeAreas: lifeAreas,
            sessions: sessions,
            inboxCount: inboxCount,
            openTaskCount: openTaskCount,
            areaCount: activeAreaCount,
            dueNudgeCount: nudges.filter { NudgeDueness.isNudgeDue(nudge: $0, now: now) }.count,
            focusDailyGoalMinutes: preferencesStore.read().focusDailyGoalMinutes
        )
    }
}
