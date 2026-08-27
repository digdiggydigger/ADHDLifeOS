//
//  PlacesServiceTests.swift
//  ADHD LifeOSTests
//

import Combine
import XCTest
@testable import ADHD_LifeOS

/// The places list's state and mutations (F-Location-PlacesUI), against a recording fake.
///
/// Two house contracts are asserted here because both fail *invisibly* when broken: mutations are
/// serialised (a second write cannot begin while one is in flight — the superseded-response race),
/// and the QUIET-RELOAD rule (a reload over loaded content never flips back to `.loading`, which
/// is what stops `DataChangeSignal`'s refetch flashing every screen).
@MainActor
final class PlacesServiceTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private func place(_ name: String) -> Place {
        Place(id: UUID(), name: name, coordinate: coordinate, radiusMetres: 200)
    }

    private final class FakeClient: PlacesClientAdapting {
        var places: [Place] = []
        var fetchError: Error?
        var mutationError: Error?
        private(set) var savedPlaces: [Place] = []
        private(set) var deletedIds: [UUID] = []
        private(set) var fetchCount = 0

        func fetchPlaces() async throws -> [Place] {
            fetchCount += 1
            if let fetchError { throw fetchError }
            return places
        }

        func savePlace(_ place: Place) async throws {
            if let mutationError { throw mutationError }
            savedPlaces.append(place)
            places.removeAll { $0.id == place.id }
            places.append(place)
        }

        func deletePlace(id: UUID) async throws {
            if let mutationError { throw mutationError }
            deletedIds.append(id)
            places.removeAll { $0.id == id }
        }
    }

    private enum TestError: LocalizedError {
        case boom
        var errorDescription: String? { "Something went wrong." }
    }

    // MARK: - Loading

    func testLoad_populatesPlacesAndMarksLoaded() async {
        let client = FakeClient()
        client.places = [place("Gym"), place("Home")]
        let service = PlacesService(client: client)

        await service.load()

        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.places.count, 2)
    }

    func testLoad_sortsByNameCaseInsensitively() async {
        let client = FakeClient()
        client.places = [place("zebra"), place("Apple"), place("banana")]
        let service = PlacesService(client: client)

        await service.load()

        XCTAssertEqual(service.places.map(\.name), ["Apple", "banana", "zebra"])
    }

    func testLoad_whenTheFetchFails_surfacesAReadableMessage() async {
        let client = FakeClient()
        client.fetchError = TestError.boom
        let service = PlacesService(client: client)

        await service.load()

        XCTAssertEqual(service.state, .failed("Something went wrong."))
    }

    /// The QUIET-RELOAD rule: a refetch over already-loaded content must not flip to `.loading`,
    /// or every `DataChangeSignal` burst blanks the list mid-read.
    func testLoad_overLoadedContent_neverFlipsBackToLoading() async {
        let client = FakeClient()
        client.places = [place("Gym")]
        let service = PlacesService(client: client)
        await service.load()

        var sawLoading = false
        let cancellable = service.$state.sink { if $0 == .loading { sawLoading = true } }
        await service.load()
        cancellable.cancel()

        XCTAssertFalse(sawLoading, "a reload over loaded content must stay quiet")
        XCTAssertEqual(service.state, .loaded)
    }

    // MARK: - Create and update

    func testSave_writesThePlaceAndReloads() async {
        let client = FakeClient()
        let service = PlacesService(client: client)
        await service.load()

        let saved = await service.save(place("Gym"))

        XCTAssertTrue(saved)
        XCTAssertEqual(client.savedPlaces.count, 1)
        XCTAssertEqual(service.places.map(\.name), ["Gym"])
    }

    func testSave_whenTheWriteFails_reportsFailureAndSurfacesTheMessage() async {
        let client = FakeClient()
        client.mutationError = TestError.boom
        let service = PlacesService(client: client)
        await service.load()

        let saved = await service.save(place("Gym"))

        XCTAssertFalse(saved)
        XCTAssertEqual(service.errorMessage, "Something went wrong.")
        XCTAssertTrue(service.places.isEmpty)
    }

    /// Editing an existing place must replace it, not add a second row with the same id.
    func testSave_anEditedPlace_replacesRatherThanDuplicates() async {
        let client = FakeClient()
        let original = place("Gym")
        client.places = [original]
        let service = PlacesService(client: client)
        await service.load()

        var renamed = original
        renamed.name = "The Gym"
        _ = await service.save(renamed)

        XCTAssertEqual(service.places.count, 1)
        XCTAssertEqual(service.places.first?.name, "The Gym")
    }

    // MARK: - Delete

    func testDelete_removesThePlaceAndReloads() async {
        let client = FakeClient()
        let gym = place("Gym")
        client.places = [gym, place("Home")]
        let service = PlacesService(client: client)
        await service.load()

        let deleted = await service.delete(gym)

        XCTAssertTrue(deleted)
        XCTAssertEqual(client.deletedIds, [gym.id])
        XCTAssertEqual(service.places.map(\.name), ["Home"])
    }

    func testDelete_whenItFails_keepsThePlaceAndReportsIt() async {
        let client = FakeClient()
        let gym = place("Gym")
        client.places = [gym]
        client.mutationError = TestError.boom
        let service = PlacesService(client: client)
        await service.load()

        let deleted = await service.delete(gym)

        XCTAssertFalse(deleted)
        XCTAssertEqual(service.errorMessage, "Something went wrong.")
        XCTAssertEqual(service.places.count, 1)
    }

    // MARK: - Error clearing

    /// A stale error under a now-successful screen is its own bug — it tells E something is
    /// broken when nothing is.
    func testANewMutation_clearsThePreviousErrorMessage() async {
        let client = FakeClient()
        client.mutationError = TestError.boom
        let service = PlacesService(client: client)
        await service.load()
        _ = await service.save(place("Gym"))
        XCTAssertNotNil(service.errorMessage)

        client.mutationError = nil
        _ = await service.save(place("Home"))

        XCTAssertNil(service.errorMessage)
    }
}
