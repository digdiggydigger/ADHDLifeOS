//
//  FirebaseManager+LocationEvents.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Recorded fence crossings (block 4c). Append-only like logs: a crossing is a historical fact,
/// so there is no update or delete here — only account deletion's cascade ever removes them.
extension FirebaseManager {
    func appendLocationEvent(_ event: LocationEvent) async throws {
        try await save(event, id: event.id, in: .locationEvents)
    }

    /// Newest first, matching the journal's own ordering.
    func fetchLocationEvents() async throws -> [LocationEvent] {
        try await fetchAll(
            LocationEvent.self, from: .locationEvents, orderedBy: "occurred_at", descending: true
        )
    }
}

extension FirebaseManager: LocationEventsBackingStore {}
