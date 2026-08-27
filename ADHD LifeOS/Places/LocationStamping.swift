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
        places
            .filter { PlaceGeometry.contains(place: $0, coordinate: coordinate) }
            .min { lhs, rhs in
                let leftDistance = PlaceGeometry.distanceMetres(from: coordinate, to: lhs.coordinate)
                let rightDistance = PlaceGeometry.distanceMetres(from: coordinate, to: rhs.coordinate)
                return (lhs.radiusMetres, leftDistance, lhs.id.uuidString)
                    < (rhs.radiusMetres, rightDistance, rhs.id.uuidString)
            }
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
