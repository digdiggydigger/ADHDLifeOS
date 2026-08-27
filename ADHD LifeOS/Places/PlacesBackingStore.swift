//
//  PlacesBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface the places adapter uses.
///
/// One narrow protocol per adapter, per `CLAUDE.md`'s 2026-08-23 call: `FirebaseManager` is a
/// `final class` with a `private init`, so an adapter holding it concretely could not be tested
/// at any price. `FirebaseManager` satisfies this in one line and tests get a recording fake.
protocol PlacesBackingStore {
    func fetchPlaces() async throws -> [Place]
    func savePlace(_ place: Place) async throws
    func deletePlace(id: UUID) async throws
    func updatePlace(id: UUID, fields: [String: Any]) async throws
}

extension FirebaseManager: PlacesBackingStore {}
