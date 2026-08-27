//
//  PlaceModels.swift
//  ADHD LifeOS
//

import Foundation

/// A latitude/longitude pair, kept free of CoreLocation so the model layer and every pure
/// calculation over it stay testable without a location manager.
struct PlaceCoordinate: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

/// A named place — E's first-class location concept (F-Location-Foundation, 2026-08-27).
///
/// Two jobs, per E's spec: it is what a capture/log/task gets tagged WITH, and it is what a
/// geofence is registered FOR. The radius is therefore not decoration — it is the trigger
/// boundary, and it is clamped into the range iOS can actually monitor at every entry point
/// (init and decode), so a bad value can never reach CoreLocation.
///
/// Wire format is snake_case throughout; see `PlaceModelsTests` for why this collection does not
/// follow `captures`' mixed convention.
struct Place: Codable, Identifiable, Equatable, Sendable {
    /// Below ~100m, region monitoring is unreliable — it is Wi-Fi/cell derived rather than GPS,
    /// so a tighter fence simply misses arrivals.
    static let minimumRadiusMetres: Double = 100
    /// Beyond this, "arrived" stops meaning anything useful.
    static let maximumRadiusMetres: Double = 5_000

    let id: UUID
    var name: String
    var coordinate: PlaceCoordinate
    /// Always within `minimumRadiusMetres...maximumRadiusMetres`.
    var radiusMetres: Double
    /// Identity glyph, the `LifeArea.colour` arrangement.
    var emoji: String?
    var createdAt: Date

    static func clampedRadius(_ metres: Double) -> Double {
        min(max(metres, minimumRadiusMetres), maximumRadiusMetres)
    }

    init(
        id: UUID,
        name: String,
        coordinate: PlaceCoordinate,
        radiusMetres: Double,
        emoji: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.radiusMetres = Self.clampedRadius(radiusMetres)
        self.emoji = emoji
        self.createdAt = createdAt
    }

    // MARK: - Codable

    // Hand-written because the coordinate is FLATTENED to latitude/longitude on the wire: a
    // Firestore query can then range over them directly, and the document stays legible in the
    // console. A synthesised `Codable` would nest it under "coordinate".
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case radiusMetres = "radius_metres"
        case emoji
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        coordinate = PlaceCoordinate(
            latitude: try container.decode(Double.self, forKey: .latitude),
            longitude: try container.decode(Double.self, forKey: .longitude)
        )
        // Clamped on the way IN too: a hand-edited document or a future writer must not be able
        // to hand CoreLocation a region it cannot monitor.
        radiusMetres = Self.clampedRadius(try container.decode(Double.self, forKey: .radiusMetres))
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(radiusMetres, forKey: .radiusMetres)
        try container.encodeIfPresent(emoji, forKey: .emoji)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
