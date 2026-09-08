//
//  LocationStampingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Recording WHERE something happened (F-Location-Tagging, block 3 of E's spec).
///
/// The stamp is deliberately two things at once: the raw coordinate, and the named place it fell
/// inside if any. Storing only the place id would lose everything that happened away from a known
/// place; storing only the coordinate would make every display do geometry. Both, once, at the
/// moment it happened.
///
/// Nothing here touches CoreLocation — the fix arrives through `LocationStamping`, so the rules
/// about when a stamp is taken at all are testable on a laptop.
@MainActor
final class LocationStampingTests: XCTestCase {

    private let oxfordCircus = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private func place(_ name: String, _ coordinate: PlaceCoordinate, radius: Double = 200) -> Place {
        Place(id: UUID(), name: name, coordinate: coordinate, radiusMetres: radius)
    }

    private final class FakeFixProvider: LocationFixProviding {
        var fix: PlaceCoordinate?
        var authorization: LocationAuthorizationState = .whenInUse
        private(set) var requestCount = 0

        var authorizationState: LocationAuthorizationState { authorization }

        func currentCoordinate() async -> PlaceCoordinate? {
            requestCount += 1
            return fix
        }
    }

    // MARK: - Which place a coordinate falls in

    func testResolution_insideAPlace_returnsIt() {
        let home = place("Home", oxfordCircus, radius: 300)

        let resolved = PlaceResolution.place(containing: oxfordCircus, in: [home])

        XCTAssertEqual(resolved?.id, home.id)
    }

    func testResolution_outsideEveryPlace_returnsNil() {
        let home = place("Home", oxfordCircus, radius: 100)
        let elsewhere = PlaceCoordinate(latitude: 55.9533, longitude: -3.1883)

        XCTAssertNil(PlaceResolution.place(containing: elsewhere, in: [home]))
    }

    func testResolution_withNoPlacesDefined_returnsNil() {
        XCTAssertNil(PlaceResolution.place(containing: oxfordCircus, in: []))
    }

    /// Every place the coordinate falls inside, tightest first — the office inside the town
    /// centre lists as [office, town]. `place(containing:)` is the head of this list, so the two
    /// can never disagree about the winner.
    func testResolution_places_listsEveryContainingPlaceTightestFirst() {
        let office = place("Office", oxfordCircus, radius: 100)
        let town = place("Town centre", oxfordCircus, radius: 800)
        let edinburgh = place("Edinburgh", PlaceCoordinate(latitude: 55.9533, longitude: -3.1883))

        let containing = PlaceResolution.places(containing: oxfordCircus, in: [edinburgh, town, office])

        XCTAssertEqual(containing.map(\.id), [office.id, town.id])
        XCTAssertEqual(PlaceResolution.place(containing: oxfordCircus, in: [edinburgh, town, office])?.id, office.id)
    }

    /// Equal radii fall back to centre distance — E's real home has two 100 m places 1.2 m apart,
    /// so BOTH must be reported, the nearer centre first.
    func testResolution_places_equalRadii_orderByCentreDistance() {
        let home = place("Home", oxfordCircus, radius: 100)
        let nudged = PlaceCoordinate(latitude: oxfordCircus.latitude + 0.00001, longitude: oxfordCircus.longitude)
        let testPlace = place("Test", nudged, radius: 100)
        let fix = PlaceCoordinate(latitude: oxfordCircus.latitude + 0.000008, longitude: oxfordCircus.longitude)

        let containing = PlaceResolution.places(containing: fix, in: [home, testPlace])

        XCTAssertEqual(containing.map(\.id), [testPlace.id, home.id])
    }

    func testResolution_places_outsideEveryPlace_isEmpty() {
        let home = place("Home", oxfordCircus, radius: 100)
        let elsewhere = PlaceCoordinate(latitude: 55.9533, longitude: -3.1883)

        XCTAssertTrue(PlaceResolution.places(containing: elsewhere, in: [home]).isEmpty)
    }

    /// Overlapping places are entirely normal — "the office" inside "town centre". The SMALLEST
    /// containing place wins, because the most specific answer is the useful one.
    ///
    /// Note the town centre here is centred exactly on the query point and the office is 13m off,
    /// so a centre-distance rule would pick the wrong one. That is not hypothetical — it is what
    /// the first implementation did, and this test is what caught it.
    func testResolution_whenPlacesOverlap_prefersTheSmallestContainingPlace() {
        let townCentre = place("Town centre", oxfordCircus, radius: 2_000)
        let office = place("The office", PlaceCoordinate(latitude: 51.5153, longitude: -0.1419), radius: 200)

        let resolved = PlaceResolution.place(containing: oxfordCircus, in: [townCentre, office])

        XCTAssertEqual(resolved?.id, office.id, "the tighter, nearer place is the useful answer")
    }

    /// Order of the input must not change the answer — places arrive alphabetically sorted, and a
    /// resort must never silently relabel where things happened.
    func testResolution_isIndependentOfInputOrder() {
        let townCentre = place("Town centre", oxfordCircus, radius: 2_000)
        let office = place("The office", PlaceCoordinate(latitude: 51.5153, longitude: -0.1419), radius: 200)

        let forwards = PlaceResolution.place(containing: oxfordCircus, in: [townCentre, office])
        let backwards = PlaceResolution.place(containing: oxfordCircus, in: [office, townCentre])

        XCTAssertEqual(forwards?.id, backwards?.id)
    }

    /// Between two equally tight places, the nearer centre is the sensible tie-break.
    func testResolution_betweenEquallyTightPlaces_prefersTheNearerCentre() {
        let near = place("Near", PlaceCoordinate(latitude: 51.5152, longitude: -0.1418), radius: 500)
        let far = place("Far", PlaceCoordinate(latitude: 51.5175, longitude: -0.1418), radius: 500)

        let resolved = PlaceResolution.place(containing: oxfordCircus, in: [far, near])

        XCTAssertEqual(resolved?.id, near.id)
    }

    // MARK: - Taking a stamp

    func testStamp_whenAuthorizedAndAFixArrives_carriesCoordinateAndPlace() async {
        let provider = FakeFixProvider()
        provider.fix = oxfordCircus
        let home = place("Home", oxfordCircus, radius: 300)
        let stamper = LocationStamping(provider: provider, isEnabled: { true })

        let stamp = await stamper.stamp(against: [home])

        XCTAssertEqual(stamp?.coordinate, oxfordCircus)
        XCTAssertEqual(stamp?.placeId, home.id)
    }

    /// Away from every known place the coordinate is still worth keeping — "where was I when I
    /// thought of this" is the whole point, and most of life happens outside a saved place.
    func testStamp_outsideEveryPlace_keepsTheCoordinateWithNoPlace() async {
        let provider = FakeFixProvider()
        provider.fix = PlaceCoordinate(latitude: 55.9533, longitude: -3.1883)
        let stamper = LocationStamping(provider: provider, isEnabled: { true })

        let stamp = await stamper.stamp(against: [place("Home", oxfordCircus)])

        XCTAssertNotNil(stamp?.coordinate)
        XCTAssertNil(stamp?.placeId)
    }

    // MARK: - When NOT to stamp

    /// The Settings switch is consulted at stamp time, the `AppFeedback` arrangement: turning
    /// tagging off silences the very next capture with no relaunch.
    func testStamp_whenTaggingIsDisabled_takesNoFixAtAll() async {
        let provider = FakeFixProvider()
        provider.fix = oxfordCircus
        let stamper = LocationStamping(provider: provider, isEnabled: { false })

        let stamp = await stamper.stamp(against: [])

        XCTAssertNil(stamp)
        XCTAssertEqual(provider.requestCount, 0, "a disabled toggle must not even ask for a fix")
    }

    func testStamp_withoutAuthorization_takesNoFix() async {
        let provider = FakeFixProvider()
        provider.authorization = .denied
        provider.fix = oxfordCircus
        let stamper = LocationStamping(provider: provider, isEnabled: { true })

        let stamp = await stamper.stamp(against: [])

        XCTAssertNil(stamp)
        XCTAssertEqual(provider.requestCount, 0)
    }

    /// A fix can simply fail to arrive (indoors, airplane mode, a cold GPS). That must produce
    /// NO stamp rather than a stamp at (0,0) — null island is a real place off the coast of
    /// Africa, and a record tagged there is worse than one tagged nowhere.
    func testStamp_whenNoFixArrives_producesNoStampRatherThanZeroZero() async {
        let provider = FakeFixProvider()
        provider.fix = nil
        let stamper = LocationStamping(provider: provider, isEnabled: { true })

        let stamp = await stamper.stamp(against: [])

        XCTAssertNil(stamp)
    }

    /// Tagging works on When In Use — it must NOT quietly require the Always grant that only
    /// arrival triggering needs.
    func testStamp_worksOnWhenInUse() async {
        let provider = FakeFixProvider()
        provider.authorization = .whenInUse
        provider.fix = oxfordCircus
        let stamper = LocationStamping(provider: provider, isEnabled: { true })

        let stamp = await stamper.stamp(against: [])

        XCTAssertNotNil(stamp)
    }
}
