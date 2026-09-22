//
//  RecentlyDeletedServiceTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the list's state, and the launch purge.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RecentlyDeletedServiceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func item(_ title: String, kind: RecentlyDeletedItem.Kind = .task, daysAgo: Double) -> RecentlyDeletedItem {
        RecentlyDeletedItem(
            itemId: UUID(), kind: kind, title: title,
            deletedAt: now.addingTimeInterval(-daysAgo * day)
        )
    }

    private func makeSUT(
        _ waiting: [RecentlyDeletedItem]
    ) -> (RecentlyDeletedService, FakeRecentlyDeletedClientAdapting) {
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .success(waiting)
        return (RecentlyDeletedService(client: client, now: { self.now }), client)
    }

    // MARK: - Loading

    func testLoadFillsTheListAndReachesLoaded() async {
        let (sut, _) = makeSUT([item("Ring the dentist", daysAgo: 2)])

        await sut.load()

        XCTAssertEqual(sut.items.map(\.title), ["Ring the dentist"])
        guard case .rows(let rows) = sut.screen else { return XCTFail("expected .rows") }
        XCTAssertEqual(rows.map(\.title), ["Ring the dentist"])
    }

    /// **Never the empty state on a failure.** "Nothing deleted" over a failed fetch is a
    /// confident lie about the one thing this screen exists to report, and the person reading it
    /// has just deleted something they may want back.
    func testAFailedLoadIsAnErrorStateAndNeverTheEmptyOne() async {
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .failure(FirebaseManagerError.notSignedIn)
        let sut = RecentlyDeletedService(client: client, now: { self.now })

        await sut.load()

        guard case .failed(let message) = sut.screen else { return XCTFail("expected .failed") }
        XCTAssertFalse(message.isEmpty)
        XCTAssertNotEqual(
            sut.screen, .empty,
            "a failed load is representable as the empty state, which tells someone who just"
                + " deleted something that it was never there"
        )
    }

    // MARK: - Restore and Delete forever

    func testRestoreCallsTheClientAndDropsTheRow() async {
        let doomed = item("Ring the dentist", daysAgo: 2)
        let (sut, client) = makeSUT([doomed, item("Keep waiting", daysAgo: 1)])
        await sut.load()

        let landed = await sut.restore(doomed)

        XCTAssertTrue(landed)
        XCTAssertEqual(client.restored.map(\.id), [doomed.id])
        XCTAssertEqual(sut.items.map(\.title), ["Keep waiting"])
        XCTAssertEqual(client.deletedForever, [], "a restore reached the permanent delete")
    }

    /// Non-optimistic, the discipline every other exit in this app follows: a removal that failed
    /// would look exactly like a successful restore while the item was still waiting.
    func testAFailedRestoreKeepsTheRowAndSurfacesTheError() async {
        let doomed = item("Ring the dentist", daysAgo: 2)
        let (sut, client) = makeSUT([doomed])
        await sut.load()
        client.restoreResult = .failure(FirebaseManagerError.notSignedIn)

        let landed = await sut.restore(doomed)

        XCTAssertFalse(landed)
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testDeleteForeverCallsTheClientAndDropsTheRow() async {
        let doomed = item("Idle thought", kind: .capture, daysAgo: 2)
        let (sut, client) = makeSUT([doomed])
        await sut.load()

        let landed = await sut.deleteForever(doomed)

        XCTAssertTrue(landed)
        XCTAssertEqual(client.deletedForever.map(\.id), [doomed.id])
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertEqual(sut.screen, .empty, "the last row left but the screen still drew it")
    }

    func testAFailedDeleteForeverKeepsTheRow() async {
        let doomed = item("Idle thought", kind: .capture, daysAgo: 2)
        let (sut, client) = makeSUT([doomed])
        await sut.load()
        client.deleteForeverResult = .failure(FirebaseManagerError.notSignedIn)

        let landed = await sut.deleteForever(doomed)

        XCTAssertFalse(landed)
        XCTAssertEqual(sut.items.count, 1)
    }

    // MARK: - The launch purge (E's Step 0 answer 1)

    /// Only what is past the window, and the boundary is `SoftDelete.isPurgeable`'s — an item at
    /// exactly thirty days is KEPT.
    func testThePurgeTakesOnlyWhatIsPastTheWindow() async {
        let old = item("Long gone", daysAgo: 31)
        let exactly = item("Last day", daysAgo: 30)
        let fresh = item("Yesterday", daysAgo: 1)
        let (sut, client) = makeSUT([old, exactly, fresh])

        await sut.purge()

        XCTAssertEqual(client.deletedForever.map(\.title), ["Long gone"])
    }

    /// A stamp from a device with a fast clock is a delete that has not aged. Purging it at once
    /// would destroy something the user deleted seconds ago on another device.
    func testThePurgeNeverTakesAFutureStamp() async {
        let fromTheFuture = item("Tomorrow's delete", daysAgo: -5)
        let (sut, client) = makeSUT([fromTheFuture])

        await sut.purge()

        XCTAssertEqual(client.deletedForever, [])
    }

    /// **Silent on failure**, because it runs while the user is opening the app to do something
    /// else. The items simply wait for the next launch — the accepted cost E's own question
    /// stated.
    func testAFailedPurgeSaysNothingAndLeavesNoError() async {
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .failure(FirebaseManagerError.notSignedIn)
        let sut = RecentlyDeletedService(client: client, now: { self.now })

        await sut.purge()

        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.screen, .loading, "the purge moved the screen's state")
    }

    /// One item refusing must not stop the rest — a single stuck document would otherwise hold the
    /// whole window open indefinitely, and the next launch would try the same one first.
    func testOneRefusalDoesNotAbandonTheRestOfThePurge() async {
        let (sut, client) = makeSUT([item("A", daysAgo: 40), item("B", daysAgo: 41)])
        client.deleteForeverResult = .failure(FirebaseManagerError.notSignedIn)

        await sut.purge()

        XCTAssertEqual(client.deletedForever.count, 2)
    }

    /// Idempotent, which is why `RootView` needs no once-flag: a sign-out and back in as another
    /// account SHOULD purge that account.
    func testThePurgeIsIdempotent() async {
        let (sut, client) = makeSUT([item("Long gone", daysAgo: 31)])

        await sut.purge()
        await sut.purge()

        XCTAssertEqual(client.deletedForever.count, 2)
        XCTAssertEqual(client.fetchCallCount, 2)
    }

    // MARK: - The survivor choice (F-C4-TagsRecentlyDeleted)

    /// **A colliding Restore WRITES NOTHING and opens the alert instead.** E's Step 0 chose the
    /// ask over a silent merge; the test that matters is the negative one, because a service that
    /// restored *and* raised the alert would look right on screen and have already merged.
    @MainActor
    func testRestoringACollidingTagOpensTheChoiceRatherThanWriting() async {
        let item = Self.collidingTag()
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .success([item])
        let service = RecentlyDeletedService(client: client)
        await service.load()

        let landed = await service.restore(item)

        XCTAssertFalse(landed, "a colliding restore reported success without having written")
        XCTAssertEqual(service.pendingSurvivorChoice, item)
        XCTAssertTrue(
            client.restored.isEmpty,
            "the restore ran anyway, so the alert asks about a merge that already happened"
        )
        XCTAssertTrue(client.resolvedRestores.isEmpty)
    }

    @MainActor
    func testRestoringATagWithNoCollisionStillWritesStraightAway() async {
        let item = RecentlyDeletedItem(itemId: UUID(), kind: .tag, title: "someday", deletedAt: Date())
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .success([item])
        let service = RecentlyDeletedService(client: client)
        await service.load()

        let landed = await service.restore(item)

        XCTAssertTrue(landed)
        XCTAssertNil(service.pendingSurvivorChoice, "an alert was raised for a name that is free")
        XCTAssertEqual(client.restored, [item])
    }

    @MainActor
    func testChoosingASurvivorWritesOnceAndClosesTheAlert() async {
        let item = Self.collidingTag()
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .success([item])
        let service = RecentlyDeletedService(client: client)
        await service.load()
        _ = await service.restore(item)

        let landed = await service.resolveSurvivor(item, keepingRestored: false)

        XCTAssertTrue(landed)
        XCTAssertNil(service.pendingSurvivorChoice)
        XCTAssertEqual(client.resolvedRestores, [.init(item: item, keptRestored: false)])
        XCTAssertEqual(service.items, [], "the row stayed after a landed merge")
    }

    /// Cancel writes nothing and leaves the row exactly where it was — the tag is still deleted,
    /// still waiting, still restorable once the name is free again.
    @MainActor
    func testCancellingTheChoiceWritesNothingAndKeepsTheRow() async {
        let item = Self.collidingTag()
        let client = FakeRecentlyDeletedClientAdapting()
        client.fetchResult = .success([item])
        let service = RecentlyDeletedService(client: client)
        await service.load()
        _ = await service.restore(item)

        service.cancelSurvivorChoice()

        XCTAssertNil(service.pendingSurvivorChoice)
        XCTAssertTrue(client.resolvedRestores.isEmpty)
        XCTAssertEqual(service.items, [item])
    }

    private static func collidingTag() -> RecentlyDeletedItem {
        RecentlyDeletedItem(
            itemId: UUID(), kind: .tag, title: "errand", deletedAt: Date(),
            collision: .init(liveId: UUID(), liveName: "Errand")
        )
    }
}
