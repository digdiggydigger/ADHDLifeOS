//
//  PlaceGeometryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure half of location services (F-Location-Foundation, E's 2026-08-27 spec: tag where
/// things happened AND trigger on arrival, geofences with a significant-change fallback).
///
/// Everything here is deliberately free of CoreLocation's *machinery* — no manager, no delegate,
/// no authorization prompt — so the decisions that actually matter are testable on a laptop.
/// The load-bearing one is `placesToMonitor`: iOS monitors at most 20 regions per app, and E can
/// define more places than that, so something has to choose. Choosing badly means a geofence
/// silently never fires, which is the worst failure this feature can have — nothing happens and
/// there is no error to see.
final class PlaceGeometryTests: XCTestCase {

    // Two well-known points, ~334m apart along Oxford Street, London.
    private let oxfordCircus = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)
    private let bondStreet = PlaceCoordinate(latitude: 51.5142, longitude: -0.1494)

    private func place(
        _ name: String,
        _ coordinate: PlaceCoordinate,
        radius: Double = 150
    ) -> Place {
        Place(id: UUID(), name: name, coordinate: coordinate, radiusMetres: radius)
    }

    // MARK: - Distance

    func testDistance_betweenTwoKnownPoints_isCorrectToWithinOnePercent() {
        let metres = PlaceGeometry.distanceMetres(from: oxfordCircus, to: bondStreet)

        // Haversine over this pair is ~537m; allow 1% for the earth-radius constant.
        XCTAssertEqual(metres, 537, accuracy: 537 * 0.01)
    }

    func testDistance_fromAPointToItself_isZero() {
        XCTAssertEqual(PlaceGeometry.distanceMetres(from: oxfordCircus, to: oxfordCircus), 0, accuracy: 0.001)
    }

    /// Longitude wraps; a naive subtraction makes these two points look half a world apart.
    func testDistance_acrossTheAntimeridian_takesTheShortWayRound() {
        let east = PlaceCoordinate(latitude: 0, longitude: 179.9)
        let west = PlaceCoordinate(latitude: 0, longitude: -179.9)

        let metres = PlaceGeometry.distanceMetres(from: east, to: west)

        // 0.2° of longitude at the equator is ~22.2km — NOT ~40,000km the long way round.
        XCTAssertEqual(metres, 22_240, accuracy: 22_240 * 0.01)
    }

    // MARK: - Containment

    func testContains_aCoordinateInsideTheRadius_isInside() {
        let home = place("Home", oxfordCircus, radius: 600)

        XCTAssertTrue(PlaceGeometry.contains(place: home, coordinate: bondStreet))
    }

    func testContains_aCoordinateBeyondTheRadius_isOutside() {
        let home = place("Home", oxfordCircus, radius: 100)

        XCTAssertFalse(PlaceGeometry.contains(place: home, coordinate: bondStreet))
    }

    // MARK: - Radius clamping

    /// iOS region monitoring is unreliable below ~100m (it is Wi-Fi/cell derived, not GPS), and a
    /// huge radius makes "arrived" meaningless. Both ends are clamped at the model boundary so a
    /// bad value can never reach CoreLocation.
    func testRadius_clampsIntoTheMonitorableRange() {
        XCTAssertEqual(Place.clampedRadius(10), Place.minimumRadiusMetres)
        XCTAssertEqual(Place.clampedRadius(50_000), Place.maximumRadiusMetres)
        XCTAssertEqual(Place.clampedRadius(250), 250)
    }

    func testInit_clampsTheRadiusItIsGiven() {
        XCTAssertEqual(place("Tiny", oxfordCircus, radius: 5).radiusMetres, Place.minimumRadiusMetres)
    }

    // MARK: - Choosing which 20 to monitor

    func testPlacesToMonitor_underTheCap_returnsEverything() {
        let places = (0..<5).map { index in
            place("P\(index)", PlaceCoordinate(latitude: 51.5 + Double(index) / 100, longitude: -0.14))
        }

        let monitored = PlaceGeometry.placesToMonitor(from: places, around: oxfordCircus)

        XCTAssertEqual(Set(monitored.map(\.id)), Set(places.map(\.id)))
    }

    /// The cap is Apple's, not ours — 20 regions per app, app-wide.
    func testPlacesToMonitor_overTheCap_keepsExactlyTheCap() {
        let places = (0..<40).map { index in
            place("P\(index)", PlaceCoordinate(latitude: 51.5 + Double(index) / 100, longitude: -0.14))
        }

        let monitored = PlaceGeometry.placesToMonitor(from: places, around: oxfordCircus)

        XCTAssertEqual(monitored.count, PlaceGeometry.regionMonitoringLimit)
        XCTAssertEqual(PlaceGeometry.regionMonitoringLimit, 20)
    }

    /// Nearest-first: the places you might plausibly arrive at next are the ones worth a region.
    /// A significant-change wake re-runs this, which is exactly what the fallback is FOR.
    func testPlacesToMonitor_overTheCap_keepsTheNearestOnes() {
        let near = place("Near", PlaceCoordinate(latitude: 51.5153, longitude: -0.1419))
        let far = place("Far", PlaceCoordinate(latitude: 55.9533, longitude: -3.1883)) // Edinburgh
        let filler = (0..<25).map { index in
            place("Filler\(index)", PlaceCoordinate(latitude: 52 + Double(index) / 10, longitude: -1))
        }

        let monitored = PlaceGeometry.placesToMonitor(from: filler + [far, near], around: oxfordCircus)

        XCTAssertTrue(monitored.contains { $0.id == near.id }, "the nearest place must always be monitored")
        XCTAssertFalse(monitored.contains { $0.id == far.id }, "Edinburgh is not the next place you arrive at")
    }

    /// Ties and ordering must not depend on dictionary order — a reshuffle between wakes would
    /// churn region registrations for no reason.
    func testPlacesToMonitor_isOrderedNearestFirst() {
        let near = place("Near", PlaceCoordinate(latitude: 51.5153, longitude: -0.1419))
        let mid = place("Mid", bondStreet)
        let far = place("Far", PlaceCoordinate(latitude: 51.6, longitude: -0.2))

        let monitored = PlaceGeometry.placesToMonitor(from: [far, mid, near], around: oxfordCircus)

        XCTAssertEqual(monitored.map(\.name), ["Near", "Mid", "Far"])
    }

    /// Without a fix yet (cold start, permission just granted) there is no "nearest" — monitor a
    /// stable arbitrary subset rather than nothing, so the feature isn't dead until a fix lands.
    func testPlacesToMonitor_withNoKnownLocation_stillReturnsUpToTheCap() {
        let places = (0..<40).map { index in
            place("P\(index)", PlaceCoordinate(latitude: 51.5 + Double(index) / 100, longitude: -0.14))
        }

        let monitored = PlaceGeometry.placesToMonitor(from: places, around: nil)

        XCTAssertEqual(monitored.count, PlaceGeometry.regionMonitoringLimit)
    }

    func testPlacesToMonitor_withNoKnownLocation_isStableAcrossCalls() {
        let places = (0..<40).map { index in
            place("P\(index)", PlaceCoordinate(latitude: 51.5 + Double(index) / 100, longitude: -0.14))
        }

        let first = PlaceGeometry.placesToMonitor(from: places, around: nil)
        let second = PlaceGeometry.placesToMonitor(from: places.shuffled(), around: nil)

        XCTAssertEqual(first.map(\.id), second.map(\.id))
    }
}
