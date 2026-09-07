//
//  FirebasePlacesClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Written 2026-09-07, closing the adapter drift the coverage re-measure found.
//  `FirebasePlacesClientAdapter` measured **41.67% (5/12)**: `fetchPlaces` was reached
//  incidentally through other suites, while `savePlace` and `deletePlace` — both WRITE paths —
//  had never been exercised at all. Places has eight production call sites, more than any other
//  adapter in the app, so these were the least-tested most-used writes in the tree.
//

import XCTest
@testable import ADHD_LifeOS

final class FirebasePlacesClientAdapterTests: XCTestCase {
    private var store: FakePlacesBackingStore!
    private var adapter: FirebasePlacesClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakePlacesBackingStore()
        adapter = FirebasePlacesClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    func testFetchPlaces_passesTheStoreListThrough() async throws {
        let gym = Self.place(name: "Gym")
        store.places = [gym]

        let places = try await adapter.fetchPlaces()

        XCTAssertEqual(places, [gym])
        XCTAssertEqual(store.fetchCallCount, 1)
    }

    func testFetchPlaces_propagatesFailure() async {
        store.fetchError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchPlaces()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    /// A place is written WHOLE, never field-by-field: the per-place nudge toggles and the radius
    /// are validated together, so a partial write could persist a radius outside
    /// `minimumRadiusMetres...maximumRadiusMetres`. The assertion that `updateCalls` stays empty
    /// is the one that protects that — `PlacesBackingStore` exposes `updatePlace`, and the
    /// adapter deliberately does not use it.
    func testSavePlace_writesTheWholePlaceAndNeverTakesThePartialUpdatePath() async throws {
        let gym = Self.place(name: "Gym", emoji: "🏋️")

        try await adapter.savePlace(gym)

        XCTAssertEqual(store.savedPlaces, [gym], "the value arrives unchanged")
        XCTAssertEqual(store.savedPlaces.first?.emoji, "🏋️")
        XCTAssertEqual(store.savedPlaces.first?.radiusMetres, 200)
        XCTAssertTrue(store.updateCalls.isEmpty, "places are written whole, never patched")
    }

    func testSavePlace_propagatesFailure() async {
        store.saveError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.savePlace(Self.place(name: "Gym"))) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    func testDeletePlace_passesTheIdThrough() async throws {
        let id = UUID()

        try await adapter.deletePlace(id: id)

        XCTAssertEqual(store.deletedIds, [id])
    }

    /// A delete that fails must surface. A place owns a geofence, and iOS only allows 20 silent
    /// region slots — silently reporting success on a failed delete would strand the fence while
    /// the row vanished from the UI, spending a slot nothing can reach to release.
    func testDeletePlace_propagatesFailure() async {
        store.deleteError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.deletePlace(id: UUID())) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    private static func place(name: String, emoji: String? = nil) -> Place {
        Place(
            id: UUID(),
            name: name,
            coordinate: PlaceCoordinate(latitude: 51.5, longitude: -0.12),
            radiusMetres: 200,
            emoji: emoji
        )
    }
}
