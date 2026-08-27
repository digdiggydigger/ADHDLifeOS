//
//  FirebaseTaskDetailClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// This is the adapter that actually drives `FirestoreFieldPayloads.taskUpdate`, so between this
/// file and `FirestoreFieldPayloadsTests` the nested-optional clear convention is covered end to
/// end: the payload arrives here untouched, and the payload tests prove what it becomes on the wire.
final class FirebaseTaskDetailClientAdapterTests: XCTestCase {
    private var store: FakeTaskDetailBackingStore!
    private var adapter: FirebaseTaskDetailClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeTaskDetailBackingStore()
        store.storedTask = Self.task(title: "Stored title")
        adapter = FirebaseTaskDetailClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    func testFetchTask_readsTheRequestedDocument() async throws {
        let id = UUID()

        let task = try await adapter.fetchTask(id: id)

        XCTAssertEqual(store.fetchedIds, [id])
        XCTAssertEqual(task.title, "Stored title")
    }

    // MARK: - Update: write then re-read

    /// The returned `TaskDetail` must be the stored truth, not the local edit echoed back — the
    /// write is a delta, so anything the payload didn't touch is only correct if it comes back from
    /// Firestore.
    func testUpdateTask_returnsTheReReadDocumentNotTheLocalEdit() async throws {
        let id = UUID()
        var payload = TaskUpdatePayload()
        payload.title = "Locally typed"

        let updated = try await adapter.updateTask(id: id, payload: payload)

        XCTAssertEqual(updated.title, "Stored title", "the re-read wins over the local edit")
        XCTAssertEqual(store.fetchedIds, [id], "the write must be followed by a read")
    }

    /// The payload reaches the store untouched — the adapter must not reinterpret the
    /// omit-if-nil/explicit-clear convention on the way through.
    func testUpdateTask_forwardsThePayloadVerbatim() async throws {
        let id = UUID()
        var payload = TaskUpdatePayload()
        payload.title = "Locally typed"
        payload.notes = .some(nil)
        payload.dueDate = .some(nil)

        _ = try await adapter.updateTask(id: id, payload: payload)

        XCTAssertEqual(store.updates.count, 1)
        XCTAssertEqual(store.updates.first?.id, id)
        XCTAssertEqual(store.updates.first?.payload, payload)
    }

    func testUpdateTask_whenTheWriteFails_doesNotReRead() async {
        store.updateError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(
            try await adapter.updateTask(id: UUID(), payload: TaskUpdatePayload())
        ) { _ in }

        XCTAssertTrue(store.fetchedIds.isEmpty, "a failed write must not report a document back")
    }

    // MARK: - Delete (moved here from the list adapter in F-V3-Tasks-rebuild)

    func testDeleteTask_forwardsTheId() async throws {
        let id = UUID()

        try await adapter.deleteTask(id: id)

        XCTAssertEqual(store.deletedIds, [id])
    }

    func testDeleteTask_propagatesFailure() async {
        store.deleteError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.deleteTask(id: UUID())) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    // MARK: - Status

    func testUpdateStatus_writesTheStatusAndReturnsTheReReadDocument() async throws {
        let id = UUID()

        let updated = try await adapter.updateStatus(id: id, status: .done)

        XCTAssertEqual(store.statusWrites.count, 1)
        XCTAssertEqual(store.statusWrites.first?.id, id)
        XCTAssertEqual(store.statusWrites.first?.status, .done)
        XCTAssertEqual(store.fetchedIds, [id])
        XCTAssertEqual(updated.title, "Stored title")
    }

    func testUpdateStatus_stampsWithTheCurrentClientClock() async throws {
        let before = Date()

        _ = try await adapter.updateStatus(id: UUID(), status: .done)

        let stamped = try XCTUnwrap(store.statusWrites.first?.now)
        XCTAssertGreaterThanOrEqual(stamped, before)
        XCTAssertLessThanOrEqual(stamped, Date())
    }

    // MARK: - Tags

    func testFetchTagsForTask_scopesToTheTaskCollection() async throws {
        let taskId = UUID()
        store.tagsForTask = [Tag(id: UUID(), name: "errand")]

        let tags = try await adapter.fetchTagsForTask(taskId: taskId)

        XCTAssertEqual(tags, store.tagsForTask)
        XCTAssertEqual(store.tagLookups.first?.parent, .task, "never .capture — that would read the wrong document")
        XCTAssertEqual(store.tagLookups.first?.parentId, taskId)
    }

    func testAddTagToTask_attachesToTheTask() async throws {
        let taskId = UUID()
        let tagId = UUID()

        try await adapter.addTagToTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(store.addedTags.first?.parent, .task)
        XCTAssertEqual(store.addedTags.first?.parentId, taskId)
        XCTAssertEqual(store.addedTags.first?.tagId, tagId)
    }

    func testRemoveTagFromTask_detachesFromTheTask() async throws {
        let taskId = UUID()
        let tagId = UUID()

        try await adapter.removeTagFromTask(taskId: taskId, tagId: tagId)

        XCTAssertEqual(store.removedTags.first?.parent, .task)
        XCTAssertEqual(store.removedTags.first?.parentId, taskId)
        XCTAssertEqual(store.removedTags.first?.tagId, tagId)
    }

    func testCreateTag_returnsTheExistingTagOnANameMatch() async throws {
        let existing = Tag(id: UUID(), name: "Errand")
        store.tags = [existing]

        let tag = try await adapter.createTag(name: "errand")

        XCTAssertEqual(tag, existing)
    }

    func testFetchAllTags_returnsTheWholeTagCollection() async throws {
        store.tags = [Tag(id: UUID(), name: "errand"), Tag(id: UUID(), name: "admin")]

        let tags = try await adapter.fetchAllTags()

        XCTAssertEqual(tags, store.tags)
    }

    private static func task(title: String) -> TaskDetail {
        TaskDetail(
            id: UUID(),
            lifeAreaId: nil,
            title: title,
            notes: nil,
            status: .open,
            priority: .p2,
            dueDate: nil,
            createdAt: Date(timeIntervalSince1970: 1_755_000_000)
        )
    }
}
