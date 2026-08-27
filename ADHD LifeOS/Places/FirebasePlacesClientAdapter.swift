//
//  FirebasePlacesClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Places over Firestore. Depends on the narrow `PlacesBackingStore`, never on `FirebaseManager`
/// directly (the house rule — the manager is a `final class` with a `private init`, so an adapter
/// holding it concretely could not be tested at any price).
///
/// Every write here posts `DataChangeSignal` through the manager's generic funnel, so a new or
/// edited place reaches every subscribed screen without a manual reload.
struct FirebasePlacesClientAdapter: PlacesClientAdapting {
    private let store: PlacesBackingStore

    init(store: PlacesBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchPlaces() async throws -> [Place] {
        try await store.fetchPlaces()
    }

    func savePlace(_ place: Place) async throws {
        try await store.savePlace(place)
    }

    func deletePlace(id: UUID) async throws {
        try await store.deletePlace(id: id)
    }
}
