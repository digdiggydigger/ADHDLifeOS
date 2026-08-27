//
//  FirebaseManager+Places.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// The `places` collection — E's named locations (F-Location-Foundation, 2026-08-27).
///
/// Per-collection file, per `CLAUDE.md`: the core manager holds only the class, auth and the
/// Firestore plumbing every extension builds on.
///
/// Each method posts `DataChangeSignal` after its awaited write via the generic funnel it calls,
/// so places obey the same refresh contract as every other collection — a new place appears
/// wherever places are shown without a manual reload.
extension FirebaseManager {
    func fetchPlaces() async throws -> [Place] {
        // Ordered by name rather than created_at: this list is something E reads and picks from,
        // so alphabetical is the useful order. No composite index needed — single-field order.
        try await fetchAll(Place.self, from: .places, orderedBy: "name")
    }

    func savePlace(_ place: Place) async throws {
        try await save(place, id: place.id, in: .places)
    }

    func deletePlace(id: UUID) async throws {
        try await delete(id: id, from: .places)
    }

    /// Named wrapper rather than exposing the generic `update(id:fields:in:)` — the house rule
    /// from `CLAUDE.md`, so a store that can edit places cannot address another collection.
    func updatePlace(id: UUID, fields: [String: Any]) async throws {
        try await update(id: id, fields: fields, in: .places)
    }
}
