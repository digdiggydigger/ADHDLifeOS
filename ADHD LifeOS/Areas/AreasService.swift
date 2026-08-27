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

    private let homeClient: HomeClientAdapting
    private let journalClient: JournalClientAdapting?
    private let captureClient: CaptureClientAdapting

    init(
        homeClient: HomeClientAdapting,
        journalClient: JournalClientAdapting?,
        captureClient: CaptureClientAdapting
    ) {
        self.homeClient = homeClient
        self.journalClient = journalClient
        self.captureClient = captureClient
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
}
