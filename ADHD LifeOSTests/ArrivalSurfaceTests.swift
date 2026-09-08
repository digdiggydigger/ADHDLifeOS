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

    // E's home as it actually is (live Firestore, 2026-09-08): three saved places with the 100 m
    // floor radius, centred 1.2 m ("Action Test 01/09/2026") and 34.5 m ("routines test") from
    // Home. Only Home ever holds at-place tasks. The resolver's nearest-centre tie-break made
    // the "current place" a coin flip per fix, and the card followed the coin.
    private let home = Place(
        id: UUID(uuidString: "BAF2423D-11EA-4622-BDBD-353C93FEEBDE")!, name: "Home",
        coordinate: PlaceCoordinate(latitude: 51.54320585133174, longitude: 0.7071901777279088),
        radiusMetres: 100, emoji: "🏠"
    )
    private let actionTest = Place(
        id: UUID(uuidString: "F04AC91D-4C6C-4A62-98EE-6741A142D8A8")!, name: "Action Test 01/09/2026",
        coordinate: PlaceCoordinate(latitude: 51.543199311070595, longitude: 0.7072040538326371),
        radiusMetres: 100
    )
    private let routinesTest = Place(
        id: UUID(uuidString: "44D247EE-7E0E-4073-84B6-36338AD57C38")!, name: "routines test",
        coordinate: PlaceCoordinate(latitude: 51.5429832, longitude: 0.7068436),
        radiusMetres: 100
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

    // MARK: - Overlapping places (the 2026-09-08 drag-reload bug)

    /// A fix that lands 1 m nearer "Action Test" than Home is still AT Home. The card considers
    /// every place the fix fell inside and shows the first with something open, so the test
    /// place beside Home can no longer hide Home's work.
    func testMake_overlappingPlaces_showsTheOneWithSomethingOpen() {
        let here = task("Put the bins out", atPlaceId: home.id)

        // Tightest-first order as the resolver would hand it over with the fix nearer Action Test.
        let surface = ArrivalSurface.make(currentPlaces: [actionTest, home, routinesTest], tasks: [here])

        XCTAssertEqual(surface?.place.id, home.id)
        XCTAssertEqual(surface?.tasks.map(\.title), ["Put the bins out"])
        XCTAssertEqual(surface?.headline, "You're at Home 🏠")
    }

    /// Two containing places both with open work: the tighter one (first in the order) wins,
    /// the same "most specific answer is the useful one" rule the resolver already had.
    func testMake_overlappingPlacesBothWithWork_theTighterOneWins() {
        let atTesco = task("Buy batteries", atPlaceId: tesco.id)
        let atHome = task("Put the bins out", atPlaceId: home.id)

        let surface = ArrivalSurface.make(currentPlaces: [tesco, home], tasks: [atHome, atTesco])

        XCTAssertEqual(surface?.place.id, tesco.id)
        XCTAssertEqual(surface?.tasks.map(\.title), ["Buy batteries"])
    }

    /// Inside places, none of which has anything open — no card, exactly as with one place.
    func testMake_overlappingPlacesWithNothingOpen_showsNothing() {
        let elsewhere = task("Belongs elsewhere", atPlaceId: tesco.id)

        XCTAssertNil(ArrivalSurface.make(currentPlaces: [actionTest, home], tasks: [elsewhere]))
    }

    func testMake_insideNoPlace_showsNothing() {
        XCTAssertNil(ArrivalSurface.make(currentPlaces: [], tasks: [task("Anything", atPlaceId: home.id)]))
    }
}
