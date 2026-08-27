//
//  ArrivalSurfaceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Home arrival card (block 4c, variation B): opening the app AT a named place surfaces that
/// place's open at-place tasks. The rule that keeps it honest: NO card unless there is something
/// to actually do here — "You're at Home" with nothing actionable is noise on the one screen
/// that must stay scannable.
@MainActor
final class ArrivalSurfaceTests: XCTestCase {

    private let tesco = Place(
        id: UUID(), name: "Tesco",
        coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
        radiusMetres: 150, emoji: "🛒"
    )

    private func task(
        _ title: String, status: TaskStatus = .open, priority: TaskPriority = .p3, atPlaceId: UUID?
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: status,
            priority: priority, dueDate: nil, atPlaceId: atPlaceId
        )
    }

    func testMake_awayFromEveryPlace_showsNothing() {
        XCTAssertNil(ArrivalSurface.make(currentPlace: nil, tasks: [task("Return", atPlaceId: tesco.id)]))
    }

    /// At a place with nothing open FOR it — no card. Closed tasks and other places' tasks are
    /// not something to do here.
    func testMake_withNothingToDoHere_showsNothing() {
        let elsewhere = UUID()

        let surface = ArrivalSurface.make(currentPlace: tesco, tasks: [
            task("Done here already", status: .done, atPlaceId: tesco.id),
            task("Belongs elsewhere", atPlaceId: elsewhere),
            task("Belongs nowhere", atPlaceId: nil)
        ])

        XCTAssertNil(surface)
    }

    func testMake_surfacesTheOpenAtPlaceTasksByPriority() {
        let urgent = task("Buy batteries", priority: .p1, atPlaceId: tesco.id)
        let later = task("Return the parcel", priority: .p3, atPlaceId: tesco.id)

        let surface = ArrivalSurface.make(currentPlace: tesco, tasks: [later, urgent])

        XCTAssertEqual(surface?.tasks.map(\.title), ["Buy batteries", "Return the parcel"])
        XCTAssertEqual(surface?.place.id, tesco.id)
    }

    func testHeadline_namesThePlaceWithItsEmoji() {
        let surface = ArrivalSurface.make(
            currentPlace: tesco, tasks: [task("Return the parcel", atPlaceId: tesco.id)]
        )

        XCTAssertEqual(surface?.headline, "You're at Tesco 🛒")
        XCTAssertEqual(surface?.countLine, "1 thing lives here")
    }

    func testCountLine_pluralises() {
        let surface = ArrivalSurface.make(currentPlace: tesco, tasks: [
            task("Return the parcel", atPlaceId: tesco.id),
            task("Buy batteries", atPlaceId: tesco.id)
        ])

        XCTAssertEqual(surface?.countLine, "2 things live here")
    }

    // MARK: - The resolution gate

    private final class RecordingPlacesClient: PlacesClientAdapting {
        private(set) var fetchCount = 0

        func fetchPlaces() async throws -> [Place] {
            fetchCount += 1
            return []
        }

        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
    }

    /// The master switch governs all three arrival surfacings — off means no work at all, not
    /// even a places fetch.
    func testCurrentPlace_disabledDoesNoWork() async {
        let places = RecordingPlacesClient()

        let resolved = await CurrentPlaceResolution.current(places: places, isEnabled: { false })

        XCTAssertNil(resolved)
        XCTAssertEqual(places.fetchCount, 0)
    }
}
