//
//  LocationTriggerPlan.swift
//  ADHD LifeOS
//

import Foundation

/// One region the app wants iOS to watch: a place's fence plus which crossings should wake us.
struct PlaceRegion: Equatable, Sendable {
    let placeId: UUID
    let center: PlaceCoordinate
    let radiusMetres: Double
    let notifyOnEntry: Bool
    let notifyOnExit: Bool
}

/// A fence crossing, as delivered by the OS — the input every block-4 surfacing consumes.
struct PlaceTriggerEvent: Equatable, Sendable {
    /// `Codable` because `LocationEvent` persists it verbatim — the raw values are a wire
    /// contract and must not be renamed for display.
    enum Kind: String, Codable, Equatable, Sendable {
        case arrival
        case departure
    }

    let placeId: UUID
    let kind: Kind
    let occurredAt: Date
}

/// Which places deserve one of iOS's 20 silent region slots, and with which directions.
///
/// Pure, so every gate is pinned by a test without CoreLocation:
/// - the Settings master switch and the Always grant both plan NOTHING — When In Use regions
///   deliver only in the foreground, which defeats an arrival trigger entirely, and registering
///   them anyway would be the silent failure the permission split exists to prevent;
/// - only places that WANT a crossing compete for a slot — a nudge toggle or a configured
///   action, either is the opt-in (the Place Actions arc widened this from toggles alone) —
///   so a quiet place can never crowd out a fence that would actually fire;
/// - past 20 the nearest win, via `PlaceGeometry.placesToMonitor` — the selection the
///   significant-change fallback re-runs on every wake.
enum LocationTriggerPlan {
    static func regions(
        places: [Place],
        around location: PlaceCoordinate?,
        authorization: LocationAuthorizationState,
        isEnabled: Bool
    ) -> [PlaceRegion] {
        guard isEnabled, authorization.allowsTriggering else { return [] }
        let wanting = places.filter(\.wantsAnyCrossing)
        return PlaceGeometry.placesToMonitor(from: wanting, around: location).map { place in
            PlaceRegion(
                placeId: place.id,
                center: place.coordinate,
                radiusMetres: place.radiusMetres,
                notifyOnEntry: place.wantsArrivalCrossing,
                notifyOnExit: place.wantsDepartureCrossing
            )
        }
    }

    /// Every planned region is (re)started — registering the same identifier REPLACES the
    /// existing region, which is how a radius or direction edit takes effect without a diff —
    /// and only regions that fell out of the plan are stopped.
    static func reconcile(
        currentIds: Set<UUID>,
        planned: [PlaceRegion]
    ) -> (start: [PlaceRegion], stopIds: Set<UUID>) {
        (start: planned, stopIds: currentIds.subtracting(planned.map(\.placeId)))
    }
}
