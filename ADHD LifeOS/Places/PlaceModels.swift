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
    /// The per-place nudge toggles (block 4b) — OFF by default, deliberately: a nudging place
    /// spends one of iOS's 20 silent region slots and earns the right to interrupt, so each
    /// place opts in rather than every saved place becoming a noise source.
    var nudgeOnArrival: Bool
    var nudgeOnDeparture: Bool
    /// E's own words for arriving here (the 2026-08-27 follow-up). Setting one CHANGES the
    /// firing rule on purpose: the message is content, so this place nudges on every arrival —
    /// the empty-never-fires gate applies only to places without one. `nil`, never "", when
    /// unset (the emoji rule).
    var arrivalMessage: String?
    /// E's own words for LEAVING here (the 2026-08-28 request). Same contract as
    /// `arrivalMessage`, and deliberately a separate field: "remember your keys" on the way out
    /// is not the sentence you want on the way in, and a place commonly wants one without the
    /// other. Setting one makes departure fire even with nothing open here.
    var departureMessage: String?
    /// What this place DOES on a crossing (the Place Actions arc, E's 2026-08-31 spec) — a
    /// list, each action with its own direction. Absent on every place saved before the arc.
    var actions: [PlaceAction]

    /// Whether this place deserves a region slot at all — the nudge toggles' own meaning,
    /// untouched by actions (the toggles are E's per-place interrupt opt-in for TASK nudges).
    var anyNudgeEnabled: Bool { nudgeOnArrival || nudgeOnDeparture }

    /// Whether this place wants to be woken for a crossing in each direction. Configuring an
    /// action IS an opt-in gesture — "arrive → Spotify" is E saying interrupt me here — so an
    /// action earns its direction's fence exactly as the matching toggle does. Unsupported
    /// actions count on purpose: the intent came from a newer build, and dropping its fence
    /// here would silently disarm it until the device catches up.
    var wantsArrivalCrossing: Bool {
        nudgeOnArrival || actions.contains { $0.direction == .arrival }
    }
    var wantsDepartureCrossing: Bool {
        nudgeOnDeparture || actions.contains { $0.direction == .departure }
    }
    var wantsAnyCrossing: Bool { wantsArrivalCrossing || wantsDepartureCrossing }

    static func clampedRadius(_ metres: Double) -> Double {
        min(max(metres, minimumRadiusMetres), maximumRadiusMetres)
    }

    init(
        id: UUID,
        name: String,
        coordinate: PlaceCoordinate,
        radiusMetres: Double,
        emoji: String? = nil,
        createdAt: Date = .now,
        nudgeOnArrival: Bool = false,
        nudgeOnDeparture: Bool = false,
        arrivalMessage: String? = nil,
        departureMessage: String? = nil,
        actions: [PlaceAction] = []
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.radiusMetres = Self.clampedRadius(radiusMetres)
        self.emoji = emoji
        self.createdAt = createdAt
        self.nudgeOnArrival = nudgeOnArrival
        self.nudgeOnDeparture = nudgeOnDeparture
        self.arrivalMessage = arrivalMessage
        self.departureMessage = departureMessage
        self.actions = actions
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
        case nudgeOnArrival = "nudge_on_arrival"
        case nudgeOnDeparture = "nudge_on_departure"
        case arrivalMessage = "arrival_message"
        case departureMessage = "departure_message"
        case actions
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
        // Absent on every place saved before block 4 — a quiet place, never a failed document.
        nudgeOnArrival = try container.decodeIfPresent(Bool.self, forKey: .nudgeOnArrival) ?? false
        nudgeOnDeparture = try container.decodeIfPresent(Bool.self, forKey: .nudgeOnDeparture) ?? false
        arrivalMessage = try container.decodeIfPresent(String.self, forKey: .arrivalMessage)
        departureMessage = try container.decodeIfPresent(String.self, forKey: .departureMessage)
        // Absent on every place saved before the actions arc — a place with nothing to do,
        // never a failed document.
        actions = try container.decodeIfPresent([PlaceAction].self, forKey: .actions) ?? []
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
        try container.encode(nudgeOnArrival, forKey: .nudgeOnArrival)
        try container.encode(nudgeOnDeparture, forKey: .nudgeOnDeparture)
        try container.encodeIfPresent(arrivalMessage, forKey: .arrivalMessage)
        try container.encodeIfPresent(departureMessage, forKey: .departureMessage)
        try container.encode(actions, forKey: .actions)
    }
}
