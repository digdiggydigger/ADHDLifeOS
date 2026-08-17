//
//  RemindersService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class RemindersService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Reminder])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading

    private let client: RemindersClientAdapting

    init(client: RemindersClientAdapting) {
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            let reminders = try await client.fetchReminders()
            state = .loaded(Self.sorted(reminders))
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Sorted by `datetime` descending where present; items with no `datetime` (missing or
    /// unparseable) sort last, ordered among themselves by `created` descending.
    static func sorted(_ reminders: [Reminder]) -> [Reminder] {
        reminders.sorted { lhs, rhs in
            switch (lhs.datetime, rhs.datetime) {
            case let (left?, right?):
                return left > right
            case (nil, nil):
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            }
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
