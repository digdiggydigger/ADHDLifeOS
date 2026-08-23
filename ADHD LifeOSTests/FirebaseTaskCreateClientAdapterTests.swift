//
//  FirebaseTaskCreateClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseTaskCreateClientAdapterTests: XCTestCase {
    private var store: FakeTaskCreateBackingStore!
    private var adapter: FirebaseTaskCreateClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeTaskCreateBackingStore()
        adapter = FirebaseTaskCreateClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// A new task is always open, and the returned `TaskItem` is the list projection of the
    /// `TaskDetail` actually written — the Tasks list renders it before any refetch, so the two
    /// must agree.
    func testCreateTask_writesAnOpenTaskAndReturnsTheMatchingProjection() async throws {
        let lifeAreaId = UUID()
        let dueDate = Date(timeIntervalSince1970: 1_755_000_000)
        let input = NormalizedCreateTaskInput(
            title: "Draft the brief",
            notes: "Two paragraphs, no more",
            lifeAreaId: lifeAreaId,
            dueDate: dueDate,
            priority: .p1
        )

        let item = try await adapter.createTask(input)

        let written = try XCTUnwrap(store.createdTasks.first)
        XCTAssertEqual(written.status, .open)
        XCTAssertEqual(written.title, "Draft the brief")
        XCTAssertEqual(written.notes, "Two paragraphs, no more")
        XCTAssertEqual(written.lifeAreaId, lifeAreaId)
        XCTAssertEqual(written.priority, .p1)
        XCTAssertEqual(written.dueDate, dueDate)

        XCTAssertEqual(item.id, written.id)
        XCTAssertEqual(item.title, written.title)
        XCTAssertEqual(item.lifeAreaId, written.lifeAreaId)
        XCTAssertEqual(item.status, .open)
        XCTAssertEqual(item.priority, written.priority)
        XCTAssertEqual(item.dueDate, written.dueDate)
        XCTAssertNil(item.completedAt, "a brand-new task has never been completed")
    }

    func testCreateTask_stampsCreatedAtWithTheCurrentClock() async throws {
        let before = Date()

        _ = try await adapter.createTask(Self.input())

        let written = try XCTUnwrap(store.createdTasks.first)
        XCTAssertGreaterThanOrEqual(written.createdAt, before)
        XCTAssertLessThanOrEqual(written.createdAt, Date())
    }

    // MARK: - Tags

    /// Creation is two steps with no cross-document transaction: write the task, then attach the
    /// tags. Each tag is one membership write against the TASK document.
    func testAttachTags_attachesEveryTagToTheTask() async throws {
        let taskId = UUID()
        let first = UUID()
        let second = UUID()

        try await adapter.attachTags(taskId: taskId, tagIds: [first, second])

        XCTAssertEqual(store.tagAttachments.map(\.tagId), [first, second])
        XCTAssertEqual(store.tagAttachments.map(\.parentId), [taskId, taskId])
        for attachment in store.tagAttachments {
            XCTAssertEqual(attachment.parent, .task, "never .capture — that would tag the wrong document")
        }
    }

    func testAttachTags_withNoTags_writesNothing() async throws {
        try await adapter.attachTags(taskId: UUID(), tagIds: [])

        XCTAssertTrue(store.tagAttachments.isEmpty)
    }

    /// Dedup by name rather than creating a duplicate, matching the old backend.
    func testCreateTag_returnsTheExistingTagOnANameMatch() async throws {
        let existing = Tag(id: UUID(), name: "Errand")
        store.tags = [existing]

        let tag = try await adapter.createTag(name: "errand")

        XCTAssertEqual(tag, existing)
    }

    func testFetchTags_returnsTheTagCollection() async throws {
        let tag = Tag(id: UUID(), name: "errand")
        store.tags = [tag]

        let tags = try await adapter.fetchTags()

        XCTAssertEqual(tags, [tag])
    }

    private static func input() -> NormalizedCreateTaskInput {
        NormalizedCreateTaskInput(title: "Draft the brief", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p2)
    }
}
