//
//  LocationTriggerServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The registration engine (block 4b): the plan actually reaches the monitor, stale fences come
/// down, the significant-change fallback follows the plan, and a trigger event makes it back out.
@MainActor
final class LocationTriggerServiceTests: XCTestCase {

    private final class FakeMonitor: RegionMonitoring {
        var onEvent: ((PlaceTriggerEvent) -> Void)?
        var onSignificantChange: ((PlaceCoordinate?) -> Void)?
        var monitoredPlaceIds: Set<UUID> = []
        private(set) var started: [PlaceRegion] = []
        private(set) var stopped: [UUID] = []
        private(set) var significantChangeStates: [Bool] = []

        func startMonitoring(_ region: PlaceRegion) {
            started.append(region)
            monitoredPlaceIds.insert(region.placeId)
        }

        func stopMonitoring(placeId: UUID) {
            stopped.append(placeId)
            monitoredPlaceIds.remove(placeId)
        }

        func setSignificantChangeMonitoring(enabled: Bool) {
            significantChangeStates.append(enabled)
        }
    }

    private final class FakePlacesClient: PlacesClientAdapting {
        var places: [Place] = []
        var fetchError: Error?
        private(set) var fetchCount = 0

        func fetchPlaces() async throws -> [Place] {
            fetchCount += 1
            if let fetchError { throw fetchError }
            return places
        }

        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
    }

    private func nudgingPlace(name: String = "Tesco") -> Place {
        Place(
            id: UUID(), name: name,
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒", nudgeOnArrival: true
        )
    }

    private func makeSUT(
        monitor: FakeMonitor,
        places: FakePlacesClient,
        enabled: Bool = true,
        authorization: LocationAuthorizationState = .always
    ) -> LocationTriggerService {
        LocationTriggerService(
            monitor: monitor,
            placesClient: places,
            isEnabled: { enabled },
            authorization: { authorization }
        )
    }

    func testRefresh_registersTheNudgingPlacesAndArmsTheFallback() async {
        let monitor = FakeMonitor()
        let places = FakePlacesClient()
        let tesco = nudgingPlace()
        places.places = [tesco]
        let sut = makeSUT(monitor: monitor, places: places)

        await sut.refreshRegistrations()

        XCTAssertEqual(monitor.started.map(\.placeId), [tesco.id])
        XCTAssertEqual(monitor.significantChangeStates.last, true)
    }

    func testRefresh_stopsFencesThatFellOutOfThePlan() async {
        let monitor = FakeMonitor()
        let stale = UUID()
        monitor.monitoredPlaceIds = [stale]
        let places = FakePlacesClient()
        let sut = makeSUT(monitor: monitor, places: places)

        await sut.refreshRegistrations()

        XCTAssertEqual(monitor.stopped, [stale])
        XCTAssertEqual(monitor.significantChangeStates.last, false)
    }

    /// The master switch (or a revoked grant) tears everything down NOW — without even a places
    /// fetch, because "off" must not cost a Firestore read.
    func testRefresh_disabledTearsDownWithoutFetching() async {
        let monitor = FakeMonitor()
        monitor.monitoredPlaceIds = [UUID()]
        let places = FakePlacesClient()
        let sut = makeSUT(monitor: monitor, places: places, enabled: false)

        await sut.refreshRegistrations()

        XCTAssertTrue(monitor.monitoredPlaceIds.isEmpty)
        XCTAssertEqual(places.fetchCount, 0)
        XCTAssertEqual(monitor.significantChangeStates.last, false)
    }

    /// A transient fetch failure on a background wake must NOT drop live fences — a fence wrongly
    /// torn down is an arrival nudge that silently never fires.
    func testRefresh_fetchFailureKeepsTheCurrentFences() async {
        let monitor = FakeMonitor()
        let live = UUID()
        monitor.monitoredPlaceIds = [live]
        let places = FakePlacesClient()
        places.fetchError = URLError(.notConnectedToInternet)
        let sut = makeSUT(monitor: monitor, places: places)

        await sut.refreshRegistrations()

        XCTAssertEqual(monitor.monitoredPlaceIds, [live])
        XCTAssertTrue(monitor.stopped.isEmpty)
    }

    func testMonitorEvents_reachTheServiceHandler() async {
        let monitor = FakeMonitor()
        let sut = makeSUT(monitor: monitor, places: FakePlacesClient())
        var received: [PlaceTriggerEvent] = []
        sut.onEvent = { received.append($0) }

        let event = PlaceTriggerEvent(placeId: UUID(), kind: .arrival, occurredAt: Date())
        monitor.onEvent?(event)

        XCTAssertEqual(received, [event])
    }

    /// A significant-change wake re-runs the selection around the NEW location — that re-pick is
    /// the entire point of the fallback.
    func testSignificantChange_triggersAReplan() async {
        let monitor = FakeMonitor()
        let places = FakePlacesClient()
        places.places = [nudgingPlace()]
        let sut = makeSUT(monitor: monitor, places: places)
        _ = sut

        monitor.onSignificantChange?(PlaceCoordinate(latitude: 51.5, longitude: -0.14))
        // The replan hops through a Task; let it land.
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(places.fetchCount, 1)
        XCTAssertEqual(monitor.started.count, 1)
    }
}
