//
//  PlaceGeometry.swift
//  ADHD LifeOS
//

import Foundation

/// The pure geometry behind places — distance, containment, and the decision of which places get
/// one of iOS's scarce monitored regions.
///
/// Deliberately CoreLocation-free. `CLLocation.distance(from:)` would do the first two, but
/// pulling a location object into every calculation makes the whole layer need a device to test,
/// and the third calculation — the one that actually decides whether a geofence ever fires — has
/// no CoreLocation equivalent at all.
enum PlaceGeometry {
    /// Apple's cap: 20 monitored regions per app, app-wide, silently enforced. Register a 21st
    /// and something else stops working with no error.
    static let regionMonitoringLimit = 20

    private static let earthRadiusMetres: Double = 6_371_000

    /// Great-circle distance (haversine). Handles antimeridian wrap, which a naive
    /// coordinate subtraction does not.
    static func distanceMetres(from origin: PlaceCoordinate, to destination: PlaceCoordinate) -> Double {
        let lat1 = origin.latitude * .pi / 180
        let lat2 = destination.latitude * .pi / 180
        let deltaLat = (destination.latitude - origin.latitude) * .pi / 180
        let deltaLon = (destination.longitude - origin.longitude) * .pi / 180

        let haversine = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let angle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusMetres * angle
    }

    static func contains(place: Place, coordinate: PlaceCoordinate) -> Bool {
        distanceMetres(from: place.coordinate, to: coordinate) <= place.radiusMetres
    }

    /// Which places get a monitored region, given where we are now.
    ///
    /// Nearest-first: the places you might plausibly arrive at next are the ones worth a region.
    /// This is exactly what the significant-change fallback exists to support — a wake re-runs
    /// this selection, so moving across the country swaps in the regions that now matter instead
    /// of leaving twenty fences around a city you have left.
    ///
    /// With no fix yet (cold start, or permission granted a moment ago) there is no "nearest", so
    /// it falls back to a STABLE arbitrary subset ordered by id — monitoring an arbitrary twenty
    /// beats monitoring nothing, and stability stops consecutive calls churning registrations.
    static func placesToMonitor(
        from places: [Place],
        around location: PlaceCoordinate?,
        limit: Int = regionMonitoringLimit
    ) -> [Place] {
        guard let location else {
            return Array(places.sorted { $0.id.uuidString < $1.id.uuidString }.prefix(limit))
        }
        let sorted = places
            .map { (place: $0, distance: distanceMetres(from: location, to: $0.coordinate)) }
            // id breaks ties so the order is total, never dependent on input order.
            .sorted { ($0.distance, $0.place.id.uuidString) < ($1.distance, $1.place.id.uuidString) }
            .map(\.place)
        return Array(sorted.prefix(limit))
    }
}
