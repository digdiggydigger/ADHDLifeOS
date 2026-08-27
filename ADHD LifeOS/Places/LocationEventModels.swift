//
//  LocationEventModels.swift
//  ADHD LifeOS
//

import Foundation

/// One recorded fence crossing (block 4c) — the silent half of arrival triggering: pure memory
/// for the journal's day review, never an interruption.
///
/// Append-only, like `logs`: a crossing is a historical fact, so nothing updates or deletes
/// these short of account deletion's cascade. Snake_cased on the wire — a new collection takes
/// the `tasks` convention, same call as `places`.
struct LocationEvent: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let placeId: UUID
    let kind: PlaceTriggerEvent.Kind
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case id, kind
        case placeId = "place_id"
        case occurredAt = "occurred_at"
    }
}

/// The write seam the trigger handler records through — narrow, per the house adapter rule.
protocol LocationEventRecording: Sendable {
    func record(_ event: LocationEvent) async throws
}

/// The Firestore surface behind `FirebaseLocationEventRecorder` and the journal's event fetch.
protocol LocationEventsBackingStore {
    func appendLocationEvent(_ event: LocationEvent) async throws
    func fetchLocationEvents() async throws -> [LocationEvent]
}

/// Production `LocationEventRecording` backed by Firestore through `LocationEventsBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests).
struct FirebaseLocationEventRecorder: LocationEventRecording {
    private let store: LocationEventsBackingStore

    init(store: LocationEventsBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func record(_ event: LocationEvent) async throws {
        try await store.appendLocationEvent(event)
    }
}
