//
//  FirebaseTagEditorClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The old backend computed `usageCount` server-side and answered a rename collision with a `409`.
/// Both are reproduced client-side here, with the same typed outcomes, so `TagEditorService`'s
/// alert flows are unchanged — which makes the outcome branches the thing worth pinning.
final class FirebaseTagEditorClientAdapterTests: XCTestCase {
    private var store: FakeTagEditorBackingStore!
    private var adapter: FirebaseTagEditorClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeTagEditorBackingStore()
        adapter = FirebaseTagEditorClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Fetch: the usage-count join

    func testFetchTags_joinsEachTagToItsUsageCount() async throws {
        let used = Tag(id: UUID(), name: "errand")
        let unused = Tag(id: UUID(), name: "someday")
        store.tags = [used, unused]
        store.usageCounts = [used.id: 4]

        let tags = try await adapter.fetchTags()

        XCTAssertEqual(tags, [
            EditableTag(id: used.id, name: "errand", usageCount: 4),
            EditableTag(id: unused.id, name: "someday", usageCount: 0)
        ])
    }

    /// A tag nothing references reads as 0, not as missing — the editor shows the count on every
    /// row, and an absent entry must not become a blank.
    func testFetchTags_aTagWithNoUsagesReadsAsZero() async throws {
        let tag = Tag(id: UUID(), name: "someday")
        store.tags = [tag]

        let tags = try await adapter.fetchTags()

        XCTAssertEqual(tags.first?.usageCount, 0)
    }

    func testFetchTags_wrapsFailure() async {
        store.fetchTagsError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchTags()) { error in
            XCTAssertEqual(error as? TagEditorServiceError, .failed(Self.notSignedInMessage))
        }
    }

    // MARK: - Rename

    func testRenameTag_toAFreeName_renames() async throws {
        let id = UUID()
        store.tags = [Tag(id: id, name: "errand")]

        let outcome = try await adapter.renameTag(id: id, to: "chores")

        XCTAssertEqual(outcome, .renamed)
        XCTAssertEqual(store.renames.count, 1)
        XCTAssertEqual(store.renames.first?.id, id)
        XCTAssertEqual(store.renames.first?.name, "chores")
    }

    /// Renaming onto a *different* tag's name is the `409` — it surfaces as `.needsMerge` carrying
    /// the conflicting tag's usage count, which is what the merge alert renders.
    func testRenameTag_ontoAnotherTagsName_needsMergeWithItsUsageCount() async throws {
        let id = UUID()
        let other = Tag(id: UUID(), name: "Chores")
        store.tags = [Tag(id: id, name: "errand"), other]
        store.usageCounts = [other.id: 7]

        let outcome = try await adapter.renameTag(id: id, to: "chores")

        XCTAssertEqual(outcome, .needsMerge(TagRenameConflict(id: other.id, name: "Chores", usageCount: 7)))
        XCTAssertTrue(store.renames.isEmpty, "a conflict must not write")
    }

    /// Renaming a tag to its own name (or a case variant of it) is not a collision with itself —
    /// otherwise fixing capitalisation would be impossible.
    func testRenameTag_toItsOwnNameInADifferentCase_renames() async throws {
        let id = UUID()
        store.tags = [Tag(id: id, name: "errand")]

        let outcome = try await adapter.renameTag(id: id, to: "Errand")

        XCTAssertEqual(outcome, .renamed)
    }

    func testRenameTag_wrapsWriteFailure() async {
        let id = UUID()
        store.tags = [Tag(id: id, name: "errand")]
        store.renameError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.renameTag(id: id, to: "chores")) { error in
            XCTAssertEqual(error as? TagEditorServiceError, .failed(Self.notSignedInMessage))
        }
    }

    // MARK: - Merge

    func testMergeTag_rewritesEveryReferenceToTheTarget() async throws {
        let source = UUID()
        let target = Tag(id: UUID(), name: "Chores")
        store.tags = [Tag(id: source, name: "errand"), target]

        try await adapter.mergeTag(id: source, into: "chores")

        XCTAssertEqual(store.cascades.count, 1)
        XCTAssertEqual(store.cascades.first?.tagId, source)
        XCTAssertEqual(store.cascades.first?.replacement, target.id)
    }

    /// Merging into a name that doesn't exist is a real failure, not a silent no-op — the caller
    /// asked to fold this tag into another one, and there is nothing to fold into.
    func testMergeTag_intoANameThatDoesNotExist_fails() async {
        let source = UUID()
        store.tags = [Tag(id: source, name: "errand")]

        await XCTAssertThrowsErrorAsync(try await adapter.mergeTag(id: source, into: "chores")) { error in
            XCTAssertEqual(
                error as? TagEditorServiceError,
                .failed("There's no other tag named \"chores\" to merge into.")
            )
        }
    }

    /// Merging a tag into itself would cascade every reference onto the tag being deleted.
    func testMergeTag_intoItself_fails() async {
        let id = UUID()
        store.tags = [Tag(id: id, name: "errand")]

        await XCTAssertThrowsErrorAsync(try await adapter.mergeTag(id: id, into: "errand")) { error in
            XCTAssertNotNil(error as? TagEditorServiceError)
        }
        XCTAssertTrue(store.cascades.isEmpty)
    }

    // MARK: - Delete

    /// **REVERSED by `F-C4-TagsRecentlyDeleted`, and the reversal is the block.** This test used
    /// to assert that a delete cascaded with no replacement — stripping the tag from every
    /// referencing task and capture and destroying the document, in one atomic batch, at the tap.
    /// That is now the 30-DAY PURGE. A delete stamps the tag and touches nothing else, so the
    /// assertion that matters most is the negative one: no cascade ran.
    func testSoftDeleteTag_stampsTheTagAndCascadesNothing() async throws {
        let id = UUID()

        try await adapter.softDeleteTag(id: id)

        XCTAssertEqual(store.softDeleted, [id])
        XCTAssertTrue(
            store.cascades.isEmpty,
            "the delete still stripped `tag_ids` from every referencing item. Those links are what"
                + " make \"back on every item\" true at restore, and stripping them cannot be undone"
                + " by putting the tag document back."
        )
    }

    func testSoftDeleteTag_wrapsFailure() async {
        store.softDeleteError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.softDeleteTag(id: UUID())) { error in
            XCTAssertEqual(error as? TagEditorServiceError, .failed(Self.notSignedInMessage))
        }
    }

    /// The way back, reachable from the capsule's Undo and from the Recently Deleted screen.
    func testRestoreTag_erasesTheStampAndCascadesNothing() async throws {
        let id = UUID()

        try await adapter.restoreTag(id: id)

        XCTAssertEqual(store.restored, [id])
        XCTAssertTrue(store.cascades.isEmpty, "a restore rewrote items; it must write one field")
    }

    func testRestoreTag_wrapsFailure() async {
        store.restoreError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.restoreTag(id: UUID())) { error in
            XCTAssertEqual(error as? TagEditorServiceError, .failed(Self.notSignedInMessage))
        }
    }

    // MARK: - Create

    func testCreateTag_withAFreeName_createsItWithNoUsages() async throws {
        let outcome = try await adapter.createTag(name: "errand")

        guard case .created(let tag) = outcome else {
            return XCTFail("expected .created, got \(outcome)")
        }
        XCTAssertEqual(tag.name, "errand")
        XCTAssertEqual(tag.usageCount, 0)
        XCTAssertEqual(store.savedTags.first?.id, tag.id)
    }

    /// Create never fails on a duplicate — it hands back the existing tag, distinguished from a
    /// fresh one so the UI avoids a phantom row and can say the tag already existed.
    func testCreateTag_withAnExistingName_returnsTheExistingTagAndWritesNothing() async throws {
        let existing = Tag(id: UUID(), name: "Errand")
        store.tags = [existing]
        store.usageCounts = [existing.id: 3]

        let outcome = try await adapter.createTag(name: "errand")

        XCTAssertEqual(
            outcome,
            .alreadyExisted(EditableTag(id: existing.id, name: "Errand", usageCount: 3))
        )
        XCTAssertTrue(store.savedTags.isEmpty)
    }

    func testCreateTag_wrapsWriteFailure() async {
        store.saveError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.createTag(name: "errand")) { error in
            XCTAssertEqual(error as? TagEditorServiceError, .failed(Self.notSignedInMessage))
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""
}
