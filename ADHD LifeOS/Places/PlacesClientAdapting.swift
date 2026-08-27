//
//  PlacesClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// The seam `PlacesService` talks to, so the service is testable without Firebase.
/// `FirebasePlacesClientAdapter` is the one production conformance.
protocol PlacesClientAdapting: Sendable {
    func fetchPlaces() async throws -> [Place]
    func savePlace(_ place: Place) async throws
    func deletePlace(id: UUID) async throws
}
