//
//  ArrivalSurfaceRefreshTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What a refresh does to the arrival card it already has (E's 2026-09-08 bug: "the 'You're at
/// home' card does not stay there when the user drag-reloads. Which is kind of pointless").
///
/// The rule: a refresh REPLACES the card only when a fresh fix positively says otherwise. The
/// resolution reports what it knows — nothing to be at (`.off`), a fix that never arrived
/// (`.noFix`), or the places a fix fell inside (`.inside`) — and only the last two can move the card:
/// no fix keeps the previous card re-checked against the fresh tasks; a fix inside no place, or
/// inside a different one, replaces it honestly.
@MainActor
final class ArrivalSurfaceRefreshTests: XCTestCase {

    private let home = Place(
        id: UUID(), name: "Home",
        coordinate: PlaceCoordinate(latitude: 51.54320585133174, longitude: 0.7071901777279088),
        radiusMetres: 100, emoji: "🏠"
    )
    private let tesco = Place(
        id: UUID(), name: "Tesco",
        coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
        radiusMetres: 150, emoji: "🛒"
    )

    private func task(
        _ title: String, status: TaskStatus = .open, atPlaceId: UUID?
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: status,
            priority: .p3, dueDate: nil, atPlaceId: atPlaceId
        )
    }

    private func cardAtHome(_ tasks: [TaskItem]) -> ArrivalSurface {
        guard let surface = ArrivalSurface.make(currentPlaces: [home], tasks: tasks) else {
            XCTFail("fixture should produce a card")
            return ArrivalSurface(place: home, tasks: tasks)
        }
        return surface
    }

    // MARK: - The refresh rule

    /// The pull whose fix never arrives (timeout, a request already in flight, airplane mode)
    /// keeps the card the user was just looking at.
    func testRefreshed_noFix_keepsThePreviousCard() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let previous = cardAtHome([bins])

        let next = ArrivalSurface.refreshed(previous: previous, fix: .noFix, tasks: [bins])

        XCTAssertEqual(next, previous)
    }

    /// ...but the tasks are still re-read: the card's one task closed since, so no card is
    /// correct even though the fix did not arrive.
    func testRefreshed_noFix_dropsTheCardWhenItsWorkClosed() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let previous = cardAtHome([bins])
        let closed = task("Put the bins out", status: .done, atPlaceId: home.id)

        XCTAssertNil(ArrivalSurface.refreshed(previous: previous, fix: .noFix, tasks: [closed]))
    }

    /// The reverse: a task added at Home since the last fix appears on the kept card.
    func testRefreshed_noFix_pickedUpNewWorkAtThePreviousPlace() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let previous = cardAtHome([bins])
        let water = task("Water the plants", atPlaceId: home.id)

        let next = ArrivalSurface.refreshed(previous: previous, fix: .noFix, tasks: [bins, water])

        XCTAssertEqual(next?.tasks.map(\.title), ["Put the bins out", "Water the plants"])
    }

    func testRefreshed_noFix_withNoPreviousCard_showsNothing() {
        let bins = task("Put the bins out", atPlaceId: home.id)

        XCTAssertNil(ArrivalSurface.refreshed(previous: nil, fix: .noFix, tasks: [bins]))
    }

    /// The toggle turned off, or permission withdrawn: there is nothing to be "at", and a kept
    /// card would outlive the feature.
    func testRefreshed_off_clearsThePreviousCard() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let previous = cardAtHome([bins])

        XCTAssertNil(ArrivalSurface.refreshed(previous: previous, fix: .off, tasks: [bins]))
    }

    /// A fix that arrived and fell inside NO saved place is the one honest "you have left".
    func testRefreshed_fixInsideNoPlace_clearsThePreviousCard() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let previous = cardAtHome([bins])

        XCTAssertNil(ArrivalSurface.refreshed(previous: previous, fix: .inside([]), tasks: [bins]))
    }

    func testRefreshed_fixAtAnotherPlace_replacesThePreviousCard() {
        let bins = task("Put the bins out", atPlaceId: home.id)
        let batteries = task("Buy batteries", atPlaceId: tesco.id)
        let previous = cardAtHome([bins])

        let next = ArrivalSurface.refreshed(previous: previous, fix: .inside([tesco]), tasks: [bins, batteries])

        XCTAssertEqual(next?.place.id, tesco.id)
        XCTAssertEqual(next?.tasks.map(\.title), ["Buy batteries"])
    }

    func testRefreshed_fixAtAPlace_buildsTheCardWithNoPrevious() {
        let bins = task("Put the bins out", atPlaceId: home.id)

        let next = ArrivalSurface.refreshed(previous: nil, fix: .inside([home]), tasks: [bins])

        XCTAssertEqual(next?.place.id, home.id)
    }

    // MARK: - The resolution gate

    private final class RecordingPlacesClient: PlacesClientAdapting {
        var places: [Place] = []
        var error: Error?
        private(set) var fetchCount = 0

        func fetchPlaces() async throws -> [Place] {
            fetchCount += 1
            if let error { throw error }
            return places
        }

        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
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

    private struct FetchFailed: Error {}

    /// The master switch governs all three arrival surfacings — off means no work at all, not
    /// even a places fetch.
    func testCurrentPlace_disabled_isOffAndDoesNoWork() async {
        let places = RecordingPlacesClient()
        let provider = FakeFixProvider()

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { false }, provider: provider)

        XCTAssertEqual(fix, .off)
        XCTAssertEqual(places.fetchCount, 0)
        XCTAssertEqual(provider.requestCount, 0)
    }

    func testCurrentPlace_withoutPermission_isOffAndDoesNoWork() async {
        let places = RecordingPlacesClient()
        let provider = FakeFixProvider()
        provider.authorization = .denied

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .off)
        XCTAssertEqual(places.fetchCount, 0)
        XCTAssertEqual(provider.requestCount, 0)
    }

    /// No saved places: nothing to be at, so the hardware is never asked.
    func testCurrentPlace_withNoSavedPlaces_isOffWithoutAFix() async {
        let places = RecordingPlacesClient()
        let provider = FakeFixProvider()

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .off)
        XCTAssertEqual(provider.requestCount, 0)
    }

    /// The places fetch failing is "don't know", never "nowhere" — the difference between keeping
    /// the card and clearing it.
    func testCurrentPlace_placesFetchFailing_isNoFix() async {
        let places = RecordingPlacesClient()
        places.error = FetchFailed()
        let provider = FakeFixProvider()
        provider.fix = home.coordinate

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .noFix)
    }

    func testCurrentPlace_fixNotArriving_isNoFix() async {
        let places = RecordingPlacesClient()
        places.places = [home]
        let provider = FakeFixProvider()
        provider.fix = nil

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .noFix)
        XCTAssertEqual(provider.requestCount, 1)
    }

    /// A fix that arrived reports EVERY place it fell inside, tightest first — the card decides
    /// among them, not the resolver.
    func testCurrentPlace_fixArriving_reportsEveryContainingPlaceTightestFirst() async {
        let town = Place(id: UUID(), name: "Town", coordinate: home.coordinate, radiusMetres: 800)
        let places = RecordingPlacesClient()
        places.places = [tesco, town, home]
        let provider = FakeFixProvider()
        provider.fix = home.coordinate

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .inside([home, town]))
    }

    func testCurrentPlace_fixInsideNoPlace_isAtNothing() async {
        let places = RecordingPlacesClient()
        places.places = [home]
        let provider = FakeFixProvider()
        provider.fix = tesco.coordinate

        let fix = await CurrentPlaceResolution.current(places: places, isEnabled: { true }, provider: provider)

        XCTAssertEqual(fix, .inside([]))
    }
}
