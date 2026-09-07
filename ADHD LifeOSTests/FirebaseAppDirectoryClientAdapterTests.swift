//
//  FirebaseAppDirectoryClientAdapterTests.swift
//  ADHD LifeOSTests
//
//  Written 2026-09-07, closing the adapter drift the coverage re-measure found.
//  `FirebaseAppDirectoryClientAdapter` measured **0.00% (0/6)** — the only adapter in the app
//  that no test had ever instantiated. It is NOT dead code: `PlaceAppDirectoryProvider.shared`
//  constructs it (`PlaceAppDirectoryRemote.swift`), so the untested hop was live in production
//  on every directory refresh. That is the shape `dead-shared-component` warns about from the
//  other direction — reachable, shipped, and unexercised.
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseAppDirectoryClientAdapterTests: XCTestCase {
    private var store: FakeAppDirectoryBackingStore!
    private var adapter: FirebaseAppDirectoryClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeAppDirectoryBackingStore()
        adapter = FirebaseAppDirectoryClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// The catalogue is raw `[[String: Any]]` on purpose — decoding is the provider's job and is
    /// deliberately lenient, so the adapter must hand the objects over untouched rather than
    /// filtering or reshaping them. Two rows, one of them missing a key a stricter layer would
    /// reject, both arriving intact.
    func testFetchRemoteEntryObjects_passesTheStoreObjectsThroughUnchanged() async throws {
        store.entryObjects = [
            ["scheme": "spotify", "displayName": "Spotify"],
            ["scheme": "gym"]
        ]

        let objects = try await adapter.fetchRemoteEntryObjects()

        XCTAssertEqual(store.fetchCallCount, 1, "one hop, no retry of its own")
        XCTAssertEqual(objects.count, 2)
        XCTAssertEqual(objects.first?["scheme"] as? String, "spotify")
        XCTAssertEqual(objects.first?["displayName"] as? String, "Spotify")
        XCTAssertEqual(objects.last?["scheme"] as? String, "gym")
        XCTAssertNil(objects.last?["displayName"], "a partial row is forwarded, not dropped")
    }

    func testFetchRemoteEntryObjects_forwardsAnEmptyCatalogueRatherThanTreatingItAsAFailure() async throws {
        store.entryObjects = []

        let objects = try await adapter.fetchRemoteEntryObjects()

        XCTAssertTrue(objects.isEmpty)
        XCTAssertEqual(store.fetchCallCount, 1)
    }

    /// `catalog/{docId}` is the ONE non-per-user path, and it is read-only to signed-in users.
    /// A signed-out read fails permission-denied, which the provider treats exactly like being
    /// offline — so the adapter must let the error out untouched rather than swallowing it into
    /// an empty list, which would look to the provider like a genuinely empty catalogue.
    func testFetchRemoteEntryObjects_propagatesFailureRatherThanReturningEmpty() async {
        store.fetchError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchRemoteEntryObjects()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }
}
