//
//  RecentlyDeletedAdapterTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the fifteenth `Firebase*ClientAdapter`, covered on the day it ships.
//
//  **F-AdapterDrift (2026-09-07) is why this file exists at commit time rather than later.** Four
//  adapters were found below the bar that day — `FirebaseAppDirectoryClientAdapter` at 0% — and
//  every one of them had arrived with an arc that shipped without its adapter test. All four were
//  reachable in production the whole time.
//

import XCTest
@testable import ADHD_LifeOS

final class RecentlyDeletedAdapterTests: XCTestCase {
    private var store: FakeRecentlyDeletedBackingStore!
    private var adapter: FirebaseRecentlyDeletedClientAdapter!
    private let stamp = Date(timeIntervalSince1970: 1_799_000_000)

    override func setUp() {
        super.setUp()
        store = FakeRecentlyDeletedBackingStore()
        adapter = FirebaseRecentlyDeletedClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    private func task(_ title: String, deletedAt: Date?) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: .open, priority: .p4,
            dueDate: nil, deletedAt: deletedAt
        )
    }

    private func capture(_ content: String, deletedAt: Date?) -> Capture {
        Capture(
            id: UUID(), content: content, kind: .note, processed: false, createdAt: Date(),
            deletedAt: deletedAt
        )
    }

    private func tag(_ name: String, deletedAt: Date?) -> Tag {
        Tag(id: UUID(), name: name, deletedAt: deletedAt)
    }

    // MARK: - Reading

    func testFetchDeletedReturnsBothCollectionsAsOneList() async throws {
        store.deletedTasks = [task("Ring the dentist", deletedAt: stamp)]
        store.deletedCaptures = [capture("Idle thought", deletedAt: stamp)]

        let items = try await adapter.fetchDeleted()

        XCTAssertEqual(Set(items.map(\.title)), ["Ring the dentist", "Idle thought"])
        XCTAssertEqual(Set(items.map(\.kind)), [.task, .capture])
        XCTAssertEqual(items.map(\.deletedAt), [stamp, stamp])
    }

    /// **A failure in EITHER collection fails the whole read**, rather than quietly returning the
    /// half that worked. A screen showing only the tasks because the capture fetch threw tells the
    /// user their capture is already gone, which is the one claim this screen exists to disprove.
    func testAFailureInEitherCollectionFailsTheWholeRead() async {
        store.fetchCapturesError = FirebaseManagerError.notSignedIn
        store.deletedTasks = [task("Still here", deletedAt: stamp)]

        await XCTAssertThrowsErrorAsync(try await adapter.fetchDeleted()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    func testAFailureFetchingTasksAlsoFailsTheRead() async {
        store.fetchTasksError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchDeleted()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    /// Unreachable by construction — the fetches already filter to stamped documents — and
    /// dropped rather than defaulted anyway, because `.now` would put a stampless row at the TOP
    /// of the list with a full window it does not have.
    func testADocumentWithNoStampIsDroppedRatherThanDatedToNow() async throws {
        store.deletedTasks = [task("No stamp", deletedAt: nil), task("Stamped", deletedAt: stamp)]

        let items = try await adapter.fetchDeleted()

        XCTAssertEqual(items.map(\.title), ["Stamped"])
    }

    /// One capture reads the same wherever it appears — the inbox, the capsule and this list all
    /// ask `CaptureDetailPresentation`.
    func testACapturesTitleComesFromTheSharedHeadlineRule() async throws {
        store.deletedCaptures = [capture("  Ring   the dentist  ", deletedAt: stamp)]

        let items = try await adapter.fetchDeleted()

        XCTAssertEqual(
            items.first?.title,
            CaptureDetailPresentation.headline(for: capture("  Ring   the dentist  ", deletedAt: stamp))
        )
    }

    // MARK: - Writing

    func testRestoreRoutesByKind() async throws {
        let taskItem = RecentlyDeletedItem(itemId: UUID(), kind: .task, title: "T", deletedAt: stamp)
        let captureItem = RecentlyDeletedItem(itemId: UUID(), kind: .capture, title: "C", deletedAt: stamp)

        try await adapter.restore(taskItem)
        try await adapter.restore(captureItem)

        XCTAssertEqual(store.restoredTaskIds, [taskItem.itemId])
        XCTAssertEqual(store.restoredCaptureIds, [captureItem.itemId])
        XCTAssertEqual(store.hardDeletedTaskIds, [], "a restore reached the hard delete")
        XCTAssertEqual(store.hardDeletedCaptureIds, [])
    }

    func testDeleteForeverRoutesByKind() async throws {
        let taskItem = RecentlyDeletedItem(itemId: UUID(), kind: .task, title: "T", deletedAt: stamp)
        let captureItem = RecentlyDeletedItem(itemId: UUID(), kind: .capture, title: "C", deletedAt: stamp)

        try await adapter.deleteForever(taskItem)
        try await adapter.deleteForever(captureItem)

        XCTAssertEqual(store.hardDeletedTaskIds, [taskItem.itemId])
        XCTAssertEqual(store.hardDeletedCaptureIds, [captureItem.itemId])
    }

    func testRestorePropagatesFailure() async {
        store.restoreError = FirebaseManagerError.notSignedIn
        let item = RecentlyDeletedItem(itemId: UUID(), kind: .task, title: "T", deletedAt: stamp)

        await XCTAssertThrowsErrorAsync(try await adapter.restore(item)) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    func testDeleteForeverPropagatesFailure() async {
        store.deleteError = FirebaseManagerError.notSignedIn
        let item = RecentlyDeletedItem(itemId: UUID(), kind: .capture, title: "C", deletedAt: stamp)

        await XCTAssertThrowsErrorAsync(try await adapter.deleteForever(item)) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    // MARK: - Tags, the third collection (F-C4-TagsRecentlyDeleted)

    func testFetchDeletedReturnsAllTHREECollectionsAsOneList() async throws {
        store.deletedTasks = [task("Ring the dentist", deletedAt: stamp)]
        store.deletedCaptures = [capture("Idle thought", deletedAt: stamp)]
        store.deletedTags = [tag("someday", deletedAt: stamp)]

        let items = try await adapter.fetchDeleted()

        XCTAssertEqual(Set(items.map(\.title)), ["Ring the dentist", "Idle thought", "someday"])
        XCTAssertEqual(Set(items.map(\.kind)), [.task, .capture, .tag])
    }

    /// The third fetch joins the existing all-or-nothing rule: a screen that quietly showed only
    /// tasks and captures would tell someone their tag is already gone, which is the one thing
    /// this screen exists to disprove.
    func testAFailedTagFetchFailsTheWholeRead() async {
        store.deletedTasks = [task("Ring the dentist", deletedAt: stamp)]
        store.fetchTagsError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchDeleted()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    func testRestoringATagErasesItsStampAndWritesNothingElse() async throws {
        let item = RecentlyDeletedItem(itemId: UUID(), kind: .tag, title: "someday", deletedAt: stamp)

        try await adapter.restore(item)

        XCTAssertEqual(store.restoredTagIds, [item.itemId])
        XCTAssertTrue(store.purgedTagIds.isEmpty)
    }

    /// **The one row on this screen whose "Delete Forever" is not a document delete.** A tag's
    /// purge strips its id from every task and capture that still carries it, THEN destroys the
    /// document — the batch a tag delete used to run at the tap. Routing it to a plain delete
    /// would leave every referencing item pointing at nothing.
    func testDeletingATagForeverPurgesItRatherThanDeletingTheDocument() async throws {
        let item = RecentlyDeletedItem(itemId: UUID(), kind: .tag, title: "someday", deletedAt: stamp)

        try await adapter.deleteForever(item)

        XCTAssertEqual(store.purgedTagIds, [item.itemId])
        XCTAssertTrue(
            store.hardDeletedTaskIds.isEmpty && store.hardDeletedCaptureIds.isEmpty,
            "a tag's purge reached one of the document deletes"
        )
    }

    // MARK: - The name a restore would collide with (F-C4-TagsRecentlyDeleted)

    /// **Detected on the READ, not attempted on the write.** The row has to know before the user
    /// taps Restore, because the alert is what the tap opens — and a write that failed with a
    /// typed error would put the same alert on every caller of `restore`, including the capsule.
    func testADeletedTagWhoseNameWasTakenAgainCarriesTheCollision() async throws {
        let deleted = tag("errand", deletedAt: stamp)
        let live = Tag(id: UUID(), name: "Errand")
        store.deletedTags = [deleted]
        store.liveTags = [live]

        let items = try await adapter.fetchDeleted()

        XCTAssertEqual(items.first?.collision?.liveId, live.id)
        XCTAssertEqual(
            items.first?.collision?.liveName, "Errand",
            "the collision must carry the LIVE spelling — it is one of the two the user picks from"
        )
    }

    /// The match folds case, because `fetchTag(named:)` does: two tags that differ only in case
    /// cannot both be live, so a restore that ignored case would create exactly that.
    func testTheCollisionMatchFoldsCaseJustAsTheDedupDoes() async throws {
        store.deletedTags = [tag("ERRAND", deletedAt: stamp)]
        store.liveTags = [Tag(id: UUID(), name: "errand")]

        let items = try await adapter.fetchDeleted()

        XCTAssertNotNil(
            items.first?.collision,
            "the collision was missed, so a restore would leave two live tags with one name"
        )
    }

    func testATagWhoseNameIsStillFreeCarriesNoCollision() async throws {
        store.deletedTags = [tag("someday", deletedAt: stamp)]
        store.liveTags = [Tag(id: UUID(), name: "errand")]

        let items = try await adapter.fetchDeleted()

        XCTAssertNil(items.first?.collision)
    }

    /// A task and a capture can never collide — only tags have a name that must be unique.
    func testOnlyTagRowsEverCarryACollision() async throws {
        store.deletedTasks = [task("errand", deletedAt: stamp)]
        store.deletedCaptures = [capture("errand", deletedAt: stamp)]
        store.liveTags = [Tag(id: UUID(), name: "errand")]

        let items = try await adapter.fetchDeleted()

        XCTAssertTrue(items.allSatisfy { $0.collision == nil })
    }

    // MARK: - Resolving it

    func testKeepingTheRestoredTagMergesTheLiveOneIntoItInOneCall() async throws {
        let live = Tag(id: UUID(), name: "Errand")
        let item = RecentlyDeletedItem(
            itemId: UUID(), kind: .tag, title: "errand", deletedAt: stamp,
            collision: .init(liveId: live.id, liveName: live.name)
        )

        try await adapter.restore(item, keepingRestored: true)

        XCTAssertEqual(store.mergesRestoring.map(\.survivor), [item.itemId])
        XCTAssertEqual(store.mergesRestoring.map(\.absorbed), [live.id])
        XCTAssertTrue(store.restoredTagIds.isEmpty, "a plain restore ran as well as the merge")
    }

    /// Keeping the LIVE tag is today's merge, and there is no restore at all: the deleted document
    /// is absorbed and destroyed, which is what "it did not survive" means.
    func testKeepingTheLiveTagMergesTheDeletedOneIntoItAndNeverRestores() async throws {
        let live = Tag(id: UUID(), name: "Errand")
        let item = RecentlyDeletedItem(
            itemId: UUID(), kind: .tag, title: "errand", deletedAt: stamp,
            collision: .init(liveId: live.id, liveName: live.name)
        )

        try await adapter.restore(item, keepingRestored: false)

        XCTAssertEqual(store.mergesInto.map(\.tagId), [item.itemId])
        XCTAssertEqual(store.mergesInto.map(\.replacement), [live.id])
        XCTAssertTrue(store.restoredTagIds.isEmpty)
        XCTAssertTrue(store.mergesRestoring.isEmpty)
    }
}
