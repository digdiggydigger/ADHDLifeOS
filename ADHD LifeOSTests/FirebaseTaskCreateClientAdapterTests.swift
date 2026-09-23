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

    // `F-D1-ComposerBothDoors` deleted this file's four tag tests (`testAttachTags_*`,
    // `testCreateTag_*`, `testFetchTags_*`) together with the adapter methods they covered: the
    // seam was pruned once the composer stopped asking for tags. `ComposerBothDoorsCallSiteTests.
    // testTheCreateSeamNoLongerCarriesTags` is their reversal — it pins that the methods stay gone.

    private static func input() -> NormalizedCreateTaskInput {
        NormalizedCreateTaskInput(title: "Draft the brief", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p2)
    }
}
