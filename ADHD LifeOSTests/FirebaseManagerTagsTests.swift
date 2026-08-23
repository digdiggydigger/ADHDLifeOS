//
//  FirebaseManagerTagsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirebaseManager+Tags` — membership, dedup, usage counts, and the cascade behind the Tag
/// Editor's rename/merge/delete.
///
/// Worth real Firestore rather than a fake because almost everything here depends on server-side
/// semantics a fake would have to imitate and could imitate wrongly: `arrayUnion`/`arrayRemove`
/// deduplicating for us, `whereField(arrayContains:)` selecting the referencing documents, and a
/// `WriteBatch` applying across two collections atomically. A hand-rolled double proves only that
/// the double behaves as its author imagined Firestore does.
///
/// Skips when the Emulator Suite is not running — see `FirebaseEmulatorHarness`.
final class FirebaseManagerTagsTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
        // Empty rather than seeded: the seed ships five tags and a pre-tagged task, which would
        // sit underneath every count and collection assertion below.
        try await FirebaseEmulatorHarness.signUpEmptyUser()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    // MARK: - Membership

    func testAddTagId_attachesTheTagToATask() async throws {
        let task = try await makeTask()
        let tag = try await makeTag("errand")

        try await manager.addTagId(tag.id, to: .task, parentId: task.id)

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(attached, [tag])
    }

    func testAddTagId_attachesTheTagToACapture() async throws {
        let capture = try await makeCapture()
        let tag = try await makeTag("idea")

        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)

        let attached = try await manager.fetchTags(for: .capture, parentId: capture.id)
        XCTAssertEqual(attached, [tag])
    }

    /// `arrayUnion` is set semantics — the UI can fire a double-tap at this and it stays one
    /// membership, which is why the write is a union rather than an append.
    func testAddTagId_appliedTwice_doesNotDuplicateTheMembership() async throws {
        let task = try await makeTask()
        let tag = try await makeTag("errand")

        try await manager.addTagId(tag.id, to: .task, parentId: task.id)
        try await manager.addTagId(tag.id, to: .task, parentId: task.id)

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(attached.count, 1)
    }

    func testRemoveTagId_detachesOnlyThatTag() async throws {
        let task = try await makeTask()
        let removed = try await makeTag("errand")
        let kept = try await makeTag("focus")
        try await manager.addTagId(removed.id, to: .task, parentId: task.id)
        try await manager.addTagId(kept.id, to: .task, parentId: task.id)

        try await manager.removeTagId(removed.id, from: .task, parentId: task.id)

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(attached, [kept])
    }

    func testFetchTags_forAParentWithNoTags_isEmpty() async throws {
        let task = try await makeTask()

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)

        XCTAssertEqual(attached, [])
    }

    /// Membership is an id array on the parent, so a tag deleted elsewhere leaves a dangling id
    /// behind. It resolves to nothing rather than to a placeholder row in the UI.
    func testFetchTags_dropsIdsWhoseTagNoLongerExists() async throws {
        let task = try await makeTask()
        let doomed = try await makeTag("temporary")
        let kept = try await makeTag("permanent")
        try await manager.addTagId(doomed.id, to: .task, parentId: task.id)
        try await manager.addTagId(kept.id, to: .task, parentId: task.id)

        try await manager.deleteTag(id: doomed.id)

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(attached, [kept])
    }

    /// The reason membership stores ids and not names: a rename is one document write, and every
    /// parent shows the new name without being touched.
    func testFetchTags_reflectsARenameWithoutRewritingTheParent() async throws {
        let task = try await makeTask()
        let tag = try await makeTag("erand")
        try await manager.addTagId(tag.id, to: .task, parentId: task.id)

        try await manager.renameTag(id: tag.id, to: "errand")

        let attached = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(attached.map(\.name), ["errand"])
    }

    // MARK: - Dedup on create

    func testCreateTagDeduplicating_withANewName_createsIt() async throws {
        let tag = try await manager.createTagDeduplicating(name: "errand")

        let all = try await manager.fetchTags()
        XCTAssertEqual(all, [tag])
    }

    func testCreateTagDeduplicating_withAnExistingName_returnsTheExistingTag() async throws {
        let original = try await manager.createTagDeduplicating(name: "errand")

        let again = try await manager.createTagDeduplicating(name: "errand")

        XCTAssertEqual(again.id, original.id)
        let all = try await manager.fetchTags()
        XCTAssertEqual(all.count, 1)
    }

    /// Case-insensitive, so "Errand" typed on one screen and "errand" on another stay one tag.
    /// The stored name keeps its original casing — the match is what is lenient, not the write.
    func testCreateTagDeduplicating_matchesCaseInsensitivelyAndKeepsTheOriginalCasing() async throws {
        let original = try await manager.createTagDeduplicating(name: "Errand")

        let again = try await manager.createTagDeduplicating(name: "errand")

        XCTAssertEqual(again.id, original.id)
        XCTAssertEqual(again.name, "Errand")
        let all = try await manager.fetchTags()
        XCTAssertEqual(all.count, 1)
    }

    func testFetchTagNamed_matchesCaseInsensitively() async throws {
        let tag = try await makeTag("Errand")

        let found = try await manager.fetchTag(named: "eRRaNd")

        XCTAssertEqual(found, tag)
    }

    func testFetchTagNamed_withNoMatch_isNil() async throws {
        _ = try await makeTag("errand")

        let found = try await manager.fetchTag(named: "something-else")

        XCTAssertNil(found)
    }

    // MARK: - Usage counts

    /// The Tag Editor's per-row count. It spans both parent collections — a tag used only on
    /// captures still reads as used, which is what stops someone deleting it as unused.
    func testTagUsageCounts_countsAcrossTasksAndCaptures() async throws {
        let tag = try await makeTag("errand")
        let taskA = try await makeTask(title: "A")
        let taskB = try await makeTask(title: "B")
        let capture = try await makeCapture()
        try await manager.addTagId(tag.id, to: .task, parentId: taskA.id)
        try await manager.addTagId(tag.id, to: .task, parentId: taskB.id)
        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)

        let counts = try await manager.tagUsageCounts()

        XCTAssertEqual(counts[tag.id], 3)
    }

    /// An unused tag is absent from the dictionary rather than present as 0 — the adapter is the
    /// layer that turns a missing entry into the 0 the UI renders, and it is tested separately.
    func testTagUsageCounts_omitsATagNothingReferences() async throws {
        let unused = try await makeTag("someday")

        let counts = try await manager.tagUsageCounts()

        XCTAssertNil(counts[unused.id])
    }

    // MARK: - Cascade: delete and merge

    func testRemoveTagEverywhere_withNoReplacement_stripsItFromEveryParentAndDeletesIt() async throws {
        let tag = try await makeTag("errand")
        let task = try await makeTask()
        let capture = try await makeCapture()
        try await manager.addTagId(tag.id, to: .task, parentId: task.id)
        try await manager.addTagId(tag.id, to: .capture, parentId: capture.id)

        try await manager.removeTagEverywhere(tag.id, replacingWith: nil)

        let onTask = try await manager.fetchTags(for: .task, parentId: task.id)
        let onCapture = try await manager.fetchTags(for: .capture, parentId: capture.id)
        let all = try await manager.fetchTags()
        XCTAssertEqual(onTask, [])
        XCTAssertEqual(onCapture, [])
        XCTAssertEqual(all, [], "the tag document itself outlived the cascade")
    }

    /// A merge rewrites references rather than dropping them, so nothing loses its categorisation
    /// when two tags are folded together.
    func testRemoveTagEverywhere_withAReplacement_rewritesEveryReference() async throws {
        let merged = try await makeTag("erand")
        let survivor = try await makeTag("errand")
        let task = try await makeTask()
        let capture = try await makeCapture()
        try await manager.addTagId(merged.id, to: .task, parentId: task.id)
        try await manager.addTagId(merged.id, to: .capture, parentId: capture.id)

        try await manager.removeTagEverywhere(merged.id, replacingWith: survivor.id)

        let onTask = try await manager.fetchTags(for: .task, parentId: task.id)
        let onCapture = try await manager.fetchTags(for: .capture, parentId: capture.id)
        XCTAssertEqual(onTask, [survivor])
        XCTAssertEqual(onCapture, [survivor])
    }

    /// The case the implementation computes client-side specifically to get right: a parent that
    /// already carries BOTH tags must end up with one, not a duplicated entry.
    func testRemoveTagEverywhere_whenTheParentAlreadyHasTheReplacement_doesNotDuplicateIt() async throws {
        let merged = try await makeTag("erand")
        let survivor = try await makeTag("errand")
        let task = try await makeTask()
        try await manager.addTagId(merged.id, to: .task, parentId: task.id)
        try await manager.addTagId(survivor.id, to: .task, parentId: task.id)

        try await manager.removeTagEverywhere(merged.id, replacingWith: survivor.id)

        let onTask = try await manager.fetchTags(for: .task, parentId: task.id)
        XCTAssertEqual(onTask, [survivor])
    }

    /// Parents that never referenced the tag are not touched at all — the cascade is scoped by
    /// `whereField(arrayContains:)`, not applied to the whole collection.
    func testRemoveTagEverywhere_leavesUnrelatedParentsUntouched() async throws {
        let doomed = try await makeTag("erand")
        let other = try await makeTag("focus")
        let tagged = try await makeTask(title: "tagged")
        let untouched = try await makeTask(title: "untouched")
        try await manager.addTagId(doomed.id, to: .task, parentId: tagged.id)
        try await manager.addTagId(other.id, to: .task, parentId: untouched.id)

        try await manager.removeTagEverywhere(doomed.id, replacingWith: nil)

        let onUntouched = try await manager.fetchTags(for: .task, parentId: untouched.id)
        XCTAssertEqual(onUntouched, [other])
    }

    func testRenameTag_changesOnlyTheName() async throws {
        let tag = try await makeTag("erand")

        try await manager.renameTag(id: tag.id, to: "errand")

        let all = try await manager.fetchTags()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, tag.id)
        XCTAssertEqual(all.first?.name, "errand")
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeTag(_ name: String) async throws -> Tag {
        let tag = Tag(id: UUID(), name: name)
        try await manager.saveTag(tag)
        return tag
    }

    @discardableResult
    private func makeTask(title: String = "A task") async throws -> TaskDetail {
        let task = TaskDetail(
            id: UUID(),
            lifeAreaId: nil,
            title: title,
            notes: nil,
            status: .open,
            priority: .p3,
            dueDate: nil,
            createdAt: Date()
        )
        try await manager.createTask(task)
        return task
    }

    @discardableResult
    private func makeCapture() async throws -> Capture {
        let capture = Capture(
            id: UUID(),
            content: "a thought",
            kind: .note,
            processed: false,
            createdAt: Date()
        )
        try await manager.saveCapture(capture)
        return capture
    }
}
