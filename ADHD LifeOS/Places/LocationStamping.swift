//
//  LocationStamping.swift
//  ADHD LifeOS
//

import Foundation

/// Where something happened: the raw coordinate, plus the named place it fell inside if any.
///
/// Both, deliberately. Only the place id would lose everything that happened away from a saved
/// place — which is most of life — and only the coordinate would make every display re-do the
/// geometry. Resolved once, at the moment it happened, because a place's radius can be edited
/// later and re-resolving would silently rewrite history.
struct LocationStamp: Equatable, Sendable {
    let coordinate: PlaceCoordinate
    let placeId: UUID?
}

/// Which named place a coordinate falls inside.
enum PlaceResolution {
    /// Overlapping places are normal — "the office" sits inside "town centre" — so the SMALLEST
    /// containing place wins: the most specific answer is the useful one.
    ///
    /// Radius, not centre-distance. An early version ranked by centre-distance and a test caught
    /// it immediately: a large place centred exactly where you are stone beats a small one a few
    /// metres off, so standing in the middle of town would report "town centre" rather than "the
    /// office". Centre-distance survives only as the tie-breaker between equally tight places,
    /// with id last so the ordering is total and never depends on the order places arrive in.
    static func place(containing coordinate: PlaceCoordinate, in places: [Place]) -> Place? {
        Self.places(containing: coordinate, in: places).first
    }

    /// EVERY place the coordinate falls inside, in the order above — so `place(containing:)` is
    /// simply the head of this list and the two can never disagree.
    ///
    /// Added for the arrival card (2026-09-08): E's real home holds three saved places with the
    /// 100 m floor radius whose centres are 1.2 m and 34.5 m apart. With equal radii the winner
    /// above is decided by which centre the fix happens to land nearer, i.e. a coin flip per fix
    /// — and only one of the three ever has tasks. A caller that needs "am I at a place with
    /// something to do" must see all of them, not the coin.
    static func places(containing coordinate: PlaceCoordinate, in places: [Place]) -> [Place] {
        places
            .filter { PlaceGeometry.contains(place: $0, coordinate: coordinate) }
            .map { (place: $0, distance: PlaceGeometry.distanceMetres(from: coordinate, to: $0.coordinate)) }
            .sorted { lhs, rhs in
                (lhs.place.radiusMetres, lhs.distance, lhs.place.id.uuidString)
                    < (rhs.place.radiusMetres, rhs.distance, rhs.place.id.uuidString)
            }
            .map(\.place)
    }
}

/// A one-shot current-location fix. Behind a protocol so the rules about *when* a stamp is taken
/// are testable without CoreLocation.
protocol LocationFixProviding {
    var authorizationState: LocationAuthorizationState { get }
    /// `nil` when no usable fix arrived — indoors, airplane mode, a cold GPS.
    func currentCoordinate() async -> PlaceCoordinate?
}

/// Takes the stamp, or decides not to.
///
/// Three gates, in cheapest-first order, and each of them means "don't even ask": the Settings
/// toggle, the authorization grant, and whether a fix actually arrived. The last one matters more
/// than it looks — a failed fix must produce NO stamp rather than one at (0, 0). Null Island is a
/// real point off the coast of Africa, and a record tagged there is worse than one tagged nowhere.
@MainActor
struct LocationStamping {
    private let provider: LocationFixProviding
    private let isEnabled: () -> Bool

    init(
        provider: LocationFixProviding,
        isEnabled: @escaping () -> Bool = { AppFeedback.locationTaggingEnabled() }
    ) {
        self.provider = provider
        self.isEnabled = isEnabled
    }

    /// The stamp for right now, or `nil` when one should not or could not be taken.
    ///
    /// Note the authorization bar is `allowsTagging`, i.e. When In Use — tagging must not quietly
    /// demand the Always grant that only arrival triggering needs.
    func stamp(against places: [Place]) async -> LocationStamp? {
        guard isEnabled() else { return nil }
        guard provider.authorizationState.allowsTagging else { return nil }
        guard let coordinate = await provider.currentCoordinate() else { return nil }
        return LocationStamp(
            coordinate: coordinate,
            placeId: PlaceResolution.place(containing: coordinate, in: places)?.id
        )
    }
}
