//
//  PlaceAppDirectoryRemoteTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The remote top-up (F-AppDirectory-4-Remote): the directory grows without a release, and
/// EVERY failure mode — offline, rules-unpublished (permission denied), malformed doc,
/// corrupted cache — degrades to bundled + last good entries, never a broken picker.
///
/// The no-reshuffle contract is structural: the sheet renders a SNAPSHOT taken when it opens,
/// and a completed fetch only updates what the NEXT open sees.
final class PlaceAppDirectoryRemoteTests: XCTestCase {

    // MARK: - Fakes

    private final class RecordingClient: AppDirectoryClientAdapting {
        var result: Result<[[String: Any]], Error> = .success([])
        private(set) var fetchCount = 0
        func fetchRemoteEntryObjects() async throws -> [[String: Any]] {
            fetchCount += 1
            return try result.get()
        }
    }

    private final class MemoryCache: AppDirectoryCacheStoring {
        var stored: (data: Data, fetchedAt: Date)?
        func load() -> (data: Data, fetchedAt: Date)? { stored }
        func save(data: Data, fetchedAt: Date) { stored = (data, fetchedAt) }
    }

    private struct Boom: Error {}

    private let bundled = [
        PlaceAppDirectoryEntry(scheme: "spotify", name: "Spotify", rank: 90),
        PlaceAppDirectoryEntry(scheme: "maps", name: "Apple Maps", rank: 80)
    ]

    private let remoteObject: [String: Any] = [
        "scheme": "newapp", "name": "New App", "rank": 99
    ]

    @MainActor
    private func provider(
        client: RecordingClient = RecordingClient(),
        cache: MemoryCache = MemoryCache(),
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 2_000_000_000) }
    ) -> PlaceAppDirectoryProvider {
        PlaceAppDirectoryProvider(client: client, cache: cache, bundled: bundled, now: now)
    }

    private func cacheData(_ objects: [[String: Any]]) -> Data {
        // Force-try in a test helper: a fixture that cannot serialize is a broken TEST.
        // swiftlint:disable:next force_try
        try! JSONSerialization.data(withJSONObject: objects)
    }

    // MARK: - The cache policy

    func testPolicy_firstEverFetchIsDue() {
        XCTAssertTrue(PlaceAppDirectoryCachePolicy.isFetchDue(lastFetchedAt: nil, now: .now))
    }

    func testPolicy_holdsInsideTheDayAndFetchesPastIt() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        XCTAssertFalse(
            PlaceAppDirectoryCachePolicy.isFetchDue(
                lastFetchedAt: now.addingTimeInterval(-23 * 3600), now: now
            )
        )
        XCTAssertTrue(
            PlaceAppDirectoryCachePolicy.isFetchDue(
                lastFetchedAt: now.addingTimeInterval(-25 * 3600), now: now
            )
        )
    }

    // MARK: - The snapshot

    @MainActor
    func testSnapshot_withNoCache_isExactlyBundled() {
        XCTAssertEqual(provider().snapshot(), bundled)
    }

    @MainActor
    func testSnapshot_withCache_mergesRemoteOverBundled() {
        let cache = MemoryCache()
        cache.stored = (
            data: cacheData([
                remoteObject,
                ["scheme": "spotify", "name": "Spotify Renamed", "rank": 5]
            ]),
            fetchedAt: .distantPast
        )

        let merged = provider(cache: cache).snapshot()

        XCTAssertEqual(merged.count, 3)
        XCTAssertEqual(merged.first(where: { $0.scheme == "spotify" })?.name, "Spotify Renamed")
        XCTAssertEqual(merged.first(where: { $0.scheme == "newapp" })?.rank, 99)
    }

    @MainActor
    func testSnapshot_corruptedCache_degradesToBundled() {
        let cache = MemoryCache()
        cache.stored = (data: Data("not json".utf8), fetchedAt: .distantPast)
        XCTAssertEqual(provider(cache: cache).snapshot(), bundled)
    }

    /// Per-entry lossiness reaches the snapshot too: one bad cached row costs itself, not the
    /// directory.
    @MainActor
    func testSnapshot_partiallyMalformedCache_keepsTheGoodEntries() {
        let cache = MemoryCache()
        cache.stored = (
            data: cacheData([remoteObject, ["name": "No scheme"]]),
            fetchedAt: .distantPast
        )

        let merged = provider(cache: cache).snapshot()

        XCTAssertEqual(merged.count, 3)
        XCTAssertNotNil(merged.first(where: { $0.scheme == "newapp" }))
    }

    // MARK: - The refresh

    @MainActor
    func testRefresh_whenDue_fetchesAndCachesStampedWithNow() async {
        let client = RecordingClient()
        client.result = .success([remoteObject])
        let cache = MemoryCache()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let sut = provider(client: client, cache: cache, now: { now })

        await sut.refreshIfDue()

        XCTAssertEqual(client.fetchCount, 1)
        XCTAssertEqual(cache.stored?.fetchedAt, now)
        XCTAssertEqual(sut.snapshot().first(where: { $0.scheme == "newapp" })?.name, "New App")
    }

    @MainActor
    func testRefresh_insideTheTTL_neverFetches() async {
        let client = RecordingClient()
        let cache = MemoryCache()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        cache.stored = (data: cacheData([remoteObject]), fetchedAt: now.addingTimeInterval(-3600))
        let sut = provider(client: client, cache: cache, now: { now })

        await sut.refreshIfDue()

        XCTAssertEqual(client.fetchCount, 0)
    }

    /// THE COMPOSITION PIN: a failed fetch — offline and rules-unpublished look identical
    /// here — leaves cache and snapshot exactly as they were.
    @MainActor
    func testRefresh_failure_keepsCacheAndSnapshotUntouched() async {
        let client = RecordingClient()
        client.result = .failure(Boom())
        let cache = MemoryCache()
        cache.stored = (data: cacheData([remoteObject]), fetchedAt: .distantPast)
        let sut = provider(client: client, cache: cache)
        let before = sut.snapshot()

        await sut.refreshIfDue()

        XCTAssertEqual(client.fetchCount, 1)
        XCTAssertEqual(cache.stored?.fetchedAt, .distantPast, "a failure must not refresh the stamp")
        XCTAssertEqual(sut.snapshot(), before)
    }

    /// A payload that cannot round-trip through JSON is not cached — the old cache survives.
    @MainActor
    func testRefresh_unserializablePayload_isNotCached() async {
        let client = RecordingClient()
        client.result = .success([["scheme": "x", "name": "X", "created": Date()]])
        let cache = MemoryCache()
        let sut = provider(client: client, cache: cache)

        await sut.refreshIfDue()

        XCTAssertNil(cache.stored)
    }

    /// The no-reshuffle contract: an already-taken snapshot is a value — a refresh landing
    /// mid-open changes only what the NEXT open sees.
    @MainActor
    func testRefresh_updatesTheNextOpenNotATakenSnapshot() async {
        let client = RecordingClient()
        client.result = .success([remoteObject])
        let sut = provider(client: client)
        let openSheet = sut.snapshot()

        await sut.refreshIfDue()

        XCTAssertEqual(openSheet, bundled, "the presented list must not move under E's finger")
        XCTAssertEqual(sut.snapshot().count, 3, "the next open sees the remote entry")
    }
}
