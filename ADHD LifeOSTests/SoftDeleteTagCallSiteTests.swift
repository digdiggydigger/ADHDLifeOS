//
//  SoftDeleteTagCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C4-TagsRecentlyDeleted`: the tag half of `SoftDeleteCallSiteTests`, split off for the same
//  reason `FirestoreFieldPayloadsSoftDeleteTests` was — the parent crossed SwiftLint's 400-line
//  ceiling — and not because it is a different kind of test. Everything that file's header says
//  applies verbatim: the failure mode of a soft delete is SILENCE, the COUNTS are the load-bearing
//  part rather than the individual assertions, and the unit-test target deliberately does not link
//  the Firebase SDK, so reading the source is the only way to see these methods at all.
//
//  The private reading helpers are duplicated rather than shared, which is the house arrangement:
//  each of the dozen `*CallSiteTests` files carries its own copy.
//

import XCTest
@testable import ADHD_LifeOS

final class SoftDeleteTagCallSiteTests: XCTestCase {

    /// **One wrap covers eight screens, and that is a structural fact rather than luck.**
    /// `fetchTags(for:parentId:)` resolves a parent's ids against `fetchTags()`, `fetchTag(named:)`
    /// searches `fetchTags()`, and `createTagDeduplicating` goes through `fetchTag(named:)` — so
    /// the Tag Editor, task detail's chip row, the task composer, capture triage, the inbox cards,
    /// the journal timeline, the log composer and Quick Capture all read through ONE method.
    ///
    /// The counts are the load-bearing part: a second, independent read of `.tags` would need its
    /// own `live(`, and adding one without it is the silent leak this file exists to stop.
    func testEveryTagReadPathAppliesTheFilter() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Tags.swift")

        XCTAssertEqual(
            Self.count(of: "func fetch", in: source), 4,
            "The number of tag read paths changed. Update this count DELIBERATELY, having decided"
                + " whether the new one reads live tags or deleted ones."
        )
        XCTAssertEqual(
            Self.count(of: "live(", in: source), 1,
            "The base `fetchTags()` is not wrapped in `live(_:)` — or a second read of `.tags`"
                + " appeared beside it and went unfiltered. Either way a deleted tag is still being"
                + " offered on some screen."
        )
        XCTAssertEqual(
            Self.count(of: "deleted(try await", in: source), 1,
            "`fetchDeletedTags()` does not go through the shared `deleted(_:)` inverse."
        )
    }

    /// The derived reads must KEEP going through the base, because that is the only thing making
    /// one wrap sufficient. Re-pointing either at `fetchAll(Tag.self, …)` for speed would restore
    /// the deleted tag to the surface it serves and break nothing that is currently asserted.
    func testTheDerivedTagReadsStillGoThroughTheFilteredBase() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Tags.swift")

        for derived in ["try await fetchTags().filter", "try await fetchTags().first"] {
            XCTAssertTrue(
                source.contains(derived),
                "`\(derived)` is gone, so a tag read stopped inheriting the live filter from"
                    + " `fetchTags()` and now answers with deleted tags."
            )
        }
        XCTAssertEqual(
            Self.count(of: "fetchAll(Tag.self", in: source), 2,
            "There are no longer exactly two raw `fetchAll(Tag.self …)` reads — the live one and"
                + " the Recently Deleted one. A third is an unfiltered read of the collection."
        )
    }

    /// A tag's stamp is snake_cased, siding with `tasks`. `Tag` had no `CodingKeys` before this
    /// block, so the default synthesis would have written `deletedAt` — and a stamp under a key
    /// nothing reads leaves the tag on every chip while the write reports success.
    func testATagsStampIsSnakeCasedLikeATasks() throws {
        let tags = try Self.appCode("Tasks/TagModels.swift")
        XCTAssertTrue(
            tags.contains("case deletedAt = \"deleted_at\""),
            "A tag's stamp is not snake_cased. `Tag` has no other multi-word field, so nothing else"
                + " in the model would reveal the convention had been dropped."
        )
    }

    func testTheTagSoftDeleteAndRestoreWritesGoThroughTheSharedUpdatePlumbing() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Tags.swift")
        for write in [
            "func softDeleteTag(id: UUID, now: Date = .now) async throws {",
            "update(id: id, fields: FirestoreFieldPayloads.tagSoftDelete(now: now), in: .tags)",
            "func restoreTag(id: UUID) async throws {",
            "update(id: id, fields: FirestoreFieldPayloads.tagRestore(), in: .tags)"
        ] {
            XCTAssertTrue(
                source.contains(write),
                "`FirebaseManager+Tags.swift` no longer contains `\(write)`. Either the soft delete"
                    + " is missing, or it stopped going through `update(id:fields:in:)` — the write"
                    + " plumbing that posts `DataChangeSignal`, and therefore the reason a restored"
                    + " tag reappears on every chip at once rather than on the next screen visit."
            )
        }
        XCTAssertFalse(
            source.contains("\"deleted_at\":"),
            "A tag's stamp is spelled inline here as well as in the payload — two spellings of one"
                + " key, free to drift."
        )
    }

    /// **The whole block in one assertion.** A tag's soft delete must name `tag_ids` nowhere:
    /// E's *"Back on every item"* is a property of never having unlinked. A `softDeleteTag` that
    /// tidied the links would pass every test that only checks the tag is hidden, and would make
    /// the restore a lie that nothing could detect until a user tried it.
    func testTheTagSoftDeleteAndRestoreNeverTouchTheLinks() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Tags.swift")
        let softDelete = try XCTUnwrap(Self.body(ofFunc: "func softDeleteTag", in: source))
        let restore = try XCTUnwrap(Self.body(ofFunc: "func restoreTag", in: source))

        for (name, body) in [("softDeleteTag", softDelete), ("restoreTag", restore)] {
            XCTAssertFalse(
                body.contains("tagIdsField") || body.contains("tag_ids")
                    || body.contains("removeTagEverywhere"),
                "`\(name)` touches the links. They are stripped ONLY by the 30-day purge — a"
                    + " delete that unlinks cannot be undone by restoring the tag document."
            )
        }
    }

    /// One function's body, from its declaration to the first line that closes at its own indent.
    /// Crude on purpose: it only has to isolate a four-line manager method.
    private static func body(ofFunc declaration: String, in source: String) -> String? {
        guard let start = source.range(of: declaration) else { return nil }
        let rest = source[start.upperBound...]
        guard let end = rest.range(of: "\n    }") else { return nil }
        return String(rest[..<end.lowerBound])
    }

    // MARK: - E's call, 2026-09-22: no confirm, a capsule instead

    /// **E's decision, taken on this block: drop the alert, add an Undo capsule.** It is the third
    /// time the same reasoning has run — `F-C3` removed the task and capture confirms the same day
    /// — and it turns on one sentence. `alerts.md › Best practices`: *"Avoid displaying alerts for
    /// common, undoable actions, even when they're destructive… when people take an uncommon
    /// destructive action that they can't undo, it's important to display an alert."* The alert
    /// existed BECAUSE a tag delete was irreversible, and this block ended that.
    ///
    /// The copy went with it: `deleteConfirmMessage` ended *"and this can't be undone"*, which is
    /// now false, and a string with no call site is the dead-shared-component pattern this repo
    /// has shipped seven times.
    func testTheTagDeleteNoLongerConfirms() throws {
        let view = try Self.appCode("TagEditor/TagEditorDetailView.swift")
        XCTAssertFalse(
            view.contains("showDeleteAlert"),
            "The tag delete confirms again. E dropped it on 2026-09-22 because the delete became"
                + " undoable — re-adding one silently reverses that decision."
        )
        XCTAssertFalse(view.contains(".alert(\"Delete Tag\""))

        let presentation = try Self.appCode("TagEditor/TagEditorPresentation.swift")
        XCTAssertFalse(
            presentation.contains("deleteConfirmMessage"),
            "The confirm's copy outlived the confirm. It ends \"this can't be undone\", which the"
                + " soft delete made false, and nothing reads it."
        )
    }

    /// **The capsule is what replaces the alert, and it carries more than reassurance.**
    /// `undo-and-redo.md › Best practices`: *"it's crucial to highlight the result of each undo and
    /// redo to keep people from thinking that the action had no effect."* A tag delete's effect is
    /// almost entirely OFFSCREEN — chips vanishing from tasks and captures the user is not looking
    /// at — so without the capsule the only visible consequence is a row leaving a list in
    /// Settings.
    func testTheTagDeleteRecordsAnUndoCapsuleThatRestores() throws {
        let view = try Self.appCode("TagEditor/TagEditorDetailView.swift")
        XCTAssertTrue(
            view.contains("RecentAction(kind: .tagDeleted, subject:"),
            "Deleting a tag records no capsule, so the one visible consequence of the delete is a"
                + " row disappearing from a list in Settings."
        )
        XCTAssertTrue(
            view.contains("await service.restore(tagId:"),
            "The capsule's Undo does not restore the tag."
        )
    }

    /// **The closure captures the SERVICE here, and that is a deliberate departure from `F-C3`.**
    /// Task detail captured `[client, taskId]` because `performDelete()` dismisses the screen that
    /// owns the service. This service is owned by `TagEditorListView`, which is the screen being
    /// returned TO — so it outlives the detail view by construction, and holding it is what lets
    /// the restore reload the list the user is now looking at.
    func testTheTagDeletesUndoCapturesTheSurvivingListService() throws {
        let view = try Self.appCode("TagEditor/TagEditorDetailView.swift")
        XCTAssertTrue(
            view.contains("{ [service, tagId] in"),
            "The undo closure does not capture the list's service and the id explicitly. An"
                + " implicit capture of `self` here is a whole View value held past its dismissal."
        )
    }

    // MARK: - Reading the tree

    private static func count(of needle: String, in source: String) -> Int {
        source.components(separatedBy: needle).count - 1
    }

    private static func appRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
    }

    /// Comments stripped, because these files document the very names the assertions look for.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot().appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw TagSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum TagSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
