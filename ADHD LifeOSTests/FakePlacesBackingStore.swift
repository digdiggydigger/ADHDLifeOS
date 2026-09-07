//
//  FakePlacesBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebasePlacesClientAdapter`.
///
/// `PlacesBackingStore` carries a fourth method — `updatePlace(id:fields:)` — that the adapter
/// deliberately does NOT expose: places are written whole through `savePlace`. It is stubbed here
/// so the fake conforms, and `updateCalls` stays empty as the standing assertion that the adapter
/// never quietly grows a partial-write path.
final class FakePlacesBackingStore: PlacesBackingStore {
    var places: [Place] = []

    var fetchError: Error?
    var saveError: Error?
    var deleteError: Error?

    private(set) var fetchCallCount = 0
    private(set) var savedPlaces: [Place] = []
    private(set) var deletedIds: [UUID] = []
    private(set) var updateCalls: [UUID] = []

    func fetchPlaces() async throws -> [Place] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return places
    }

    func savePlace(_ place: Place) async throws {
        savedPlaces.append(place)
        if let saveError { throw saveError }
    }

    func deletePlace(id: UUID) async throws {
        deletedIds.append(id)
        if let deleteError { throw deleteError }
    }

    func updatePlace(id: UUID, fields: [String: Any]) async throws {
        updateCalls.append(id)
    }
}
