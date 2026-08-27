//
//  PlaceMapGeometryTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Turning a radius in METRES into a map span in DEGREES (F-Location-PlacesUI).
///
/// The picker has to open showing the place's circle at a sensible size, and a radius change has
/// to zoom to match. Degrees-per-metre is not constant — longitude degrees shrink toward the
/// poles — so this is real arithmetic with two genuine failure modes: a span that shows the
/// circle far too small to judge, and a division by ~zero at high latitude that produces an
/// infinite span and a blank map.
final class PlaceMapGeometryTests: XCTestCase {

    // MARK: - Latitude

    /// Latitude degrees are ~constant everywhere: 1° ≈ 111.32km.
    func testLatitudeSpan_isIndependentOfLatitude() {
        let equator = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 0)
        let london = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 51.5)

        XCTAssertEqual(equator.latitudeDelta, london.latitudeDelta, accuracy: 1e-9)
    }

    func testLatitudeSpan_scalesWithRadius() {
        let small = PlaceMapGeometry.span(fittingRadiusMetres: 500, atLatitude: 51.5)
        let large = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 51.5)

        XCTAssertEqual(large.latitudeDelta, small.latitudeDelta * 2, accuracy: 1e-9)
    }

    /// The circle must be comfortably inside the frame, not touching its edges — the padding
    /// factor is what makes the radius legible rather than filling the whole map.
    func testSpan_leavesRoomAroundTheCircle() {
        let radius: Double = 1_000
        let span = PlaceMapGeometry.span(fittingRadiusMetres: radius, atLatitude: 0)

        // The circle's full width is 2r; the span must exceed that.
        let circleWidthDegrees = (radius * 2) / PlaceMapGeometry.metresPerDegreeLatitude
        XCTAssertGreaterThan(span.latitudeDelta, circleWidthDegrees)
    }

    // MARK: - Longitude

    /// Longitude degrees shrink with cos(latitude): at 60°N a degree is about half its
    /// equatorial width, so the same radius needs about twice the longitude span.
    func testLongitudeSpan_widensWithLatitude() {
        let equator = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 0)
        let sixty = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 60)

        XCTAssertEqual(sixty.longitudeDelta, equator.longitudeDelta * 2, accuracy: equator.longitudeDelta * 0.01)
    }

    func testLongitudeSpan_atTheEquator_matchesTheLatitudeSpan() {
        let span = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 0)

        XCTAssertEqual(span.longitudeDelta, span.latitudeDelta, accuracy: 1e-9)
    }

    /// The failure this exists to prevent: cos(90°) is 0, so an unguarded division yields an
    /// infinite longitude span and MapKit renders nothing at all.
    func testLongitudeSpan_atThePole_staysFinite() {
        let span = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 90)

        XCTAssertTrue(span.longitudeDelta.isFinite, "a pole must not produce an infinite span")
        XCTAssertLessThanOrEqual(span.longitudeDelta, PlaceMapGeometry.maximumLongitudeDelta)
    }

    func testLongitudeSpan_nearThePole_isClampedNotAstronomical() {
        let span = PlaceMapGeometry.span(fittingRadiusMetres: 5_000, atLatitude: 89.99)

        XCTAssertLessThanOrEqual(span.longitudeDelta, PlaceMapGeometry.maximumLongitudeDelta)
    }

    /// Southern latitudes must behave identically — cos is even, but a sign slip would show.
    func testSpan_isSymmetricAcrossTheEquator() {
        let north = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: 45)
        let south = PlaceMapGeometry.span(fittingRadiusMetres: 1_000, atLatitude: -45)

        XCTAssertEqual(north.longitudeDelta, south.longitudeDelta, accuracy: 1e-9)
        XCTAssertEqual(north.latitudeDelta, south.latitudeDelta, accuracy: 1e-9)
    }

    // MARK: - Whole-range sanity

    /// Every radius the model permits must produce a usable span — the picker is unusable if
    /// either end of the slider blanks the map.
    func testSpan_isUsableAcrossTheWholePermittedRadiusRange() {
        for radius in [Place.minimumRadiusMetres, 500, 2_000, Place.maximumRadiusMetres] {
            for latitude in [0.0, 51.5, -33.9, 71.0] {
                let span = PlaceMapGeometry.span(fittingRadiusMetres: radius, atLatitude: latitude)
                XCTAssertTrue(span.latitudeDelta.isFinite && span.latitudeDelta > 0,
                              "radius \(radius) at \(latitude) gave a bad latitude span")
                XCTAssertTrue(span.longitudeDelta.isFinite && span.longitudeDelta > 0,
                              "radius \(radius) at \(latitude) gave a bad longitude span")
            }
        }
    }
}
