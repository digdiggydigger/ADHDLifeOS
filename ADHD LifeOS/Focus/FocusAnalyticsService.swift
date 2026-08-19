//
//  FocusAnalyticsService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// Loads focus history once for the analytics widgets, so `WeeklyFocusSummaryWidget` and
/// `ProductivityTrendChart` render from one Firestore read rather than fetching separately.
@MainActor
final class FocusAnalyticsService: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([CompletedFocusSession])
        case failed(String)
    }

    @Published private(set) var state: State = .loading

    private let reader: FocusHistoryReading

    init(reader: FocusHistoryReading) {
        self.reader = reader
    }

    var sessions: [CompletedFocusSession] {
        if case .loaded(let sessions) = state { return sessions }
        return []
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await reader.fetchHistory())
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
