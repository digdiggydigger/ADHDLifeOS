//
//  FirebaseManagerTagsSoftDeleteTests.swift
//  ADHD LifeOSTests
//
//  `F-C4-TagsRecentlyDeleted`: the third collection's soft delete, against the Emulator Suite.
//
//  **Its own file, like `FirestoreFieldPayloadsSoftDeleteTests`**: `FirebaseManagerTagsTests` is
//  311 lines against SwiftLint's 400 ceiling, and this is the same kind of test rather than a
//  different one. Everything that file's header says applies verbatim — real Firestore because
//  `whereField(arrayContains:)`, `arrayUnion` and `WriteBatch` are server semantics a fake can
//  only imitate, and imitate wrongly.
//
//  **What makes tags different from the other two collections, and why these tests are shaped
//  around it.** A task's soft delete hides a task. A tag's soft delete must hide the TAG and
//  change nothing else — every `tag_ids` array on every task and capture keeps the id while the
//  stamp is set, because E's *"Back on every item"* is a property of never having unlinked, not of
//  re-attaching at restore. So the assertions below are in two halves that must both hold: the tag
//  stops being offered anywhere, AND the links are provably untouched.
//
//  Skips when the Emulator Suite is not running — see `FirebaseEmulatorHarness`.
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseManagerTagsSoftDeleteTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
        // Empty rather than seeded, for the reason `FirebaseManagerTagsTests` gives: the seed's
        // five tags would sit underneath every collection assertion here.
        try await FirebaseEmulatorHarness.signUpEmptyUser()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    // MARK: - Hiding

    func testSoftDeleteTag_takesItOutOfTheListEveryScreenReads() async throws {
        let kept = try await makeTag("errand")
        let doomed = try await makeTag("someday")

        try await manager.softDeleteTag(id: doomed.id)

        let live = try await manager.fetchTags()
        XCTAssertEqual(live.map(\.id), [kept.id], "a soft-deleted tag is still offered somewhere")
    }

    /// **`fetchTags()` is the single choke point and this is what proves it.** Every tag surface in
    /// the app — the Tag Editor, task detail's chip row, the task composer, capture triage, the
    /// inbox cards, the journal timeline, the log composer and Quick Capture — reaches tags through
    /// this one method or through the two below that call it. One wrap covers all eight.
    func testTheTwoDerivedReadsInheritTheFilterRatherThanRepeatingIt() async throws {
        let task = try await makeTask()
        let doomed = try await makeTag("someday")
        try await manager.addTagId(doomed.id, to: .task, parentId: task.id)

        try await manager.softDeleteTag(id: doomed.id)

        let onTask = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(onTask, [], "the task still renders a chip for a deleted tag")
        let byName = try await manager.fetchTag(named: "someday")
        XCTAssertNil(
            byName, "a deleted tag answers to its own name, so typing it back returns the hidden"
                + " one and the user gets a chip that never renders"
        )
    }

    /// The consequence of the line above, and the reason the merge case exists at all: with the
    /// original hidden, typing its name creates a genuinely NEW tag, and restoring the original
    /// then has two live tags with one name to reconcile.
    func testCreatingTheSameNameDuringTheWindowMakesANewTagRatherThanRevivingTheHiddenOne() async throws {
        let original = try await makeTag("errand")
        try await manager.softDeleteTag(id: original.id)

        let replacement = try await manager.createTagDeduplicating(name: "errand")

        XCTAssertNotEqual(
            replacement.id, original.id,
            "dedup matched the hidden tag, so the user's new tag is invisible from the moment they"
                + " make it"
        )
    }

    // MARK: - The links, which must NOT move

    /// **The acceptance criterion's own wording: assert the ARRAY is unchanged, not just that the
    /// tag looks gone.** `Capture` is the model that exposes `tag_ids` to Swift at all, so it is
    /// the one place this can be read directly rather than inferred.
    func testSoftDeleteTag_leavesEveryTagIdsArrayExactlyAsItWas() async throws {
        let capture = try await makeCapture()
        let tag = try await makeTag("errand")
        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)
        let before = try await manager.fetchCapture(id: capture.id).tagIds

        try await manager.softDeleteTag(id: tag.id)

        let after = try await manager.fetchCapture(id: capture.id).tagIds
        XCTAssertEqual(before, [tag.id], "the fixture did not attach the tag")
        XCTAssertEqual(
            after, before,
            "the soft delete rewrote a `tag_ids` array. Nothing may touch the links until the"
                + " 30-day purge — a delete that strips them cannot be undone by restoring the tag"
        )
    }

    /// The task half, proved the only way a task can prove it: restore touches the TAG document
    /// alone, so a chip that comes back is a chip whose id never left.
    func testRestoreBringsTheTagBackOnEveryItemWithoutWritingToThoseItems() async throws {
        let task = try await makeTask()
        let capture = try await makeCapture()
        let tag = try await makeTag("errand")
        try await manager.addTagId(tag.id, to: .task, parentId: task.id)
        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)
        try await manager.softDeleteTag(id: tag.id)

        try await manager.restoreTag(id: tag.id)

        let onTask = try await manager.fetchTags(for: .task, parentId: task.id)
        let onCapture = try await manager.fetchTags(for: .capture, parentId: capture.id)
        let live = try await manager.fetchTags()
        XCTAssertEqual(onTask, [tag])
        XCTAssertEqual(onCapture, [tag])
        XCTAssertEqual(live, [tag])
    }

    // MARK: - The Recently Deleted list's own read

    func testFetchDeletedTags_returnsExactlyWhatFetchTagsDrops() async throws {
        let kept = try await makeTag("errand")
        let doomed = try await makeTag("someday")
        try await manager.softDeleteTag(id: doomed.id)

        let deleted = try await manager.fetchDeletedTags()

        let live = try await manager.fetchTags()
        XCTAssertEqual(deleted.map(\.id), [doomed.id])
        XCTAssertEqual(live.map(\.id), [kept.id])
    }

    func testTheStampIsReadableAsAnInstantSoTheCountdownHasSomethingToCountFrom() async throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let tag = try await makeTag("someday")

        try await manager.softDeleteTag(id: tag.id, now: stamp)

        let deleted = try await manager.fetchDeletedTags()
        XCTAssertEqual(deleted.first?.deletedAt?.timeIntervalSince1970, stamp.timeIntervalSince1970)
    }

    // MARK: - The purge, which is today's whole batch deferred

    /// **A tag's "delete forever" is not a document delete — it is the batch that used to run
    /// immediately.** Stripping the links is the irreversible half, and it is what the 30 days buy
    /// back. This asserts the deferred call does exactly what the old immediate one did.
    func testPurgingATagStripsTheLinksAndDestroysTheDocument() async throws {
        let task = try await makeTask()
        let capture = try await makeCapture()
        let tag = try await makeTag("errand")
        try await manager.addTagId(tag.id, to: .task, parentId: task.id)
        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)
        try await manager.softDeleteTag(id: tag.id)

        try await manager.removeTagEverywhere(tag.id, replacingWith: nil)

        let strippedLinks = try await manager.fetchCapture(id: capture.id).tagIds
        let live = try await manager.fetchTags()
        let stillWaiting = try await manager.fetchDeletedTags()
        XCTAssertEqual(strippedLinks, [], "the purge left the links behind")
        XCTAssertEqual(live, [], "the purge left the tag document behind")
        XCTAssertEqual(stillWaiting, [], "the purged tag is still in Recently Deleted")
    }

    // MARK: - Fixtures

    private func makeTag(_ name: String) async throws -> Tag {
        let tag = Tag(id: UUID(), name: name)
        try await manager.saveTag(tag)
        return tag
    }

    @discardableResult
    private func makeTask(title: String = "A task") async throws -> TaskDetail {
        let task = TaskDetail(
            id: UUID(), lifeAreaId: nil, title: title, notes: nil,
            status: .open, priority: .p3, dueDate: nil, createdAt: Date()
        )
        try await manager.createTask(task)
        return task
    }

    @discardableResult
    private func makeCapture() async throws -> Capture {
        let capture = Capture(
            id: UUID(), content: "a thought", kind: .note, processed: false, createdAt: Date()
        )
        try await manager.saveCapture(capture)
        return capture
    }
}
