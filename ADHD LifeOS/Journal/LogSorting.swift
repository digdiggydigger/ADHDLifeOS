//
//  LogSorting.swift
//  ADHD LifeOS
//

import Foundation

/// Pure feed-derivation logic for the Journal tab: newest-first ordering (mirrors web's
/// `sortLogsByEntryDateDesc`) and the mobile-only life-area filter (`ARCHITECTURE.md` §3 specs
/// mobile as "filterable by life area"; web's `LogService.listLogs` supports the same filter
/// param but no web screen currently wires it up).
enum LogSorting {
    static func sortByEntryDateDescending(_ logs: [Log]) -> [Log] {
        logs.sorted { $0.entryDate > $1.entryDate }
    }

    /// `lifeAreaId == nil` means "All" — returns every log unfiltered. A specific id returns only
    /// logs whose `lifeAreaId` matches it exactly.
    static func filterByLifeArea(_ logs: [Log], lifeAreaId: UUID?) -> [Log] {
        guard let lifeAreaId else { return logs }
        return logs.filter { $0.lifeAreaId == lifeAreaId }
    }
}
