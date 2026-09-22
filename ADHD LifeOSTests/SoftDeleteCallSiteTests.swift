//
//  SoftDeleteCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: every read path the live-ness filter must reach, asserted by reading
//  the tree.
//
//  **These exist because the failure mode of a soft delete is silence.** A fetch that forgets the
//  filter returns deleted items to a list, and nothing complains: the app draws them, every
//  behaviour test passes (they use fakes, not the manager), and the only symptom is a task the
//  user deleted reappearing. The spec calls for exactly this test *"so a later collection/query
//  addition cannot silently leak deleted items back in"*, on the model of `AppTabBarCallSiteTests`.
//
//  **The COUNTS are the load-bearing part, not the individual assertions.** Pinning "every fetch
//  that exists today is filtered" catches nothing tomorrow; pinning "there are exactly N fetches
//  and N of them are filtered" fails the moment someone adds the N+1th. The unit-test target
//  deliberately does not link the Firebase SDK (CLAUDE.md, Architecture notes), so reading the
//  source is not a shortcut here — it is the only way to see these methods at all.
//

import XCTest
@testable import ADHD_LifeOS

final class SoftDeleteCallSiteTests: XCTestCase {

    // MARK: - Tasks

    /// `fetchTasks()`, `fetchOpenTaskSummaries()` and `fetchTasks(lifeAreaId:)` return LISTS and
    /// must drop deleted rows; `fetchTaskDetail(id:)` returns ONE document and must refuse.
    func testEveryTaskReadPathAppliesTheFilter() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Tasks.swift")

        XCTAssertEqual(
            Self.count(of: "func fetch", in: source), 5,
            "The number of task read paths changed. Every one of them must apply"
                + " `SoftDelete.isLive` or refuse a deleted document — update this count"
                + " DELIBERATELY, having filtered the new one."
        )
        XCTAssertEqual(
            Self.count(of: "live(", in: source), 3,
            "One of the three list-returning task fetches is not wrapped in `live(_:)`, so a"
                + " soft-deleted task is still listed somewhere."
        )
        // **`requireLive(`, not the error's name.** The throw itself lives in the shared helper
        // (`testTheFilterIsOneSharedHelperOverASharedProtocol` pins that), which is the whole
        // point of having a helper — so asserting the error's name HERE was asserting that the
        // centralisation had not happened. It failed on the first full run, correctly, and this is
        // the assertion it should always have been: the single-document read goes THROUGH the
        // guard. The count keeps a second single-document fetch from skipping it.
        XCTAssertEqual(
            Self.count(of: "requireLive(", in: source), 1,
            "`fetchTaskDetail(id:)` does not go through `requireLive`, so a stale route — a widget"
                + " link, a nudge, a capsule held across a tab switch — opens a deleted task as"
                + " though it were live and editable."
        )
    }

    // MARK: - Captures

    /// Four list reads (`fetchCaptures`, `fetchUnprocessedCaptures`, `fetchProcessedCaptures`,
    /// `fetchSeenCaptures`) and one single-document read (`fetchCapture(id:)`).
    ///
    /// **`fetchUnprocessedCaptures()` is the one worth naming**: it is not only the inbox's own
    /// list but the TAB BAR BADGE (`RootView+Furniture.swift:51`), so an unfiltered version counts
    /// deleted captures at the user forever, on every screen in the app.
    func testEveryCaptureReadPathAppliesTheFilter() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+Captures.swift")

        XCTAssertEqual(
            Self.count(of: "func fetch", in: source), 6,
            "The number of capture read paths changed. Update this count DELIBERATELY, having"
                + " filtered the new one."
        )
        XCTAssertEqual(
            Self.count(of: "live(", in: source), 4,
            "One of the four list-returning capture fetches is not wrapped in `live(_:)`."
                + " If it is `fetchUnprocessedCaptures`, the tab bar badge counts deleted captures."
        )
        XCTAssertEqual(
            Self.count(of: "requireLive(", in: source), 1,
            "`fetchCapture(id:)` does not go through `requireLive`, so a deleted capture opens as"
                + " though it were live."
        )
    }

    // MARK: - The filter itself

    /// One helper, one place. Three files could each write `.filter { $0.deletedAt == nil }` and
    /// all three would be right until the rule changed once.
    func testTheFilterIsOneSharedHelperOverASharedProtocol() throws {
        let source = try Self.appCode("Firebase/FirebaseManager+SoftDelete.swift")
        XCTAssertTrue(
            source.contains("SoftDelete.isLive(deletedAt:"),
            "The shared helper does not go through `SoftDelete.isLive`, so the rule now lives in"
                + " two places and one of them will drift."
        )
        XCTAssertTrue(
            source.contains("SoftDeletable"),
            "The helper is not generic over `SoftDeletable`, so each model needs its own copy."
        )
        XCTAssertTrue(
            source.contains("throw SoftDeleteError.itemIsDeleted"),
            "`requireLive(_:)` does not throw, so every single-document read returns a deleted"
                + " document as though it were live."
        )
    }

    /// Every model a filtered fetch decodes has to carry the stamp, or the filter cannot see it.
    func testEveryFetchedModelCarriesTheStamp() throws {
        for (file, type) in [
            ("Tasks/TaskModels.swift", "TaskItem"),
            ("Tasks/TaskDetailModels.swift", "TaskDetail"),
            ("Home/HomeModels.swift", "TaskSummary"),
            ("Capture/CaptureModels.swift", "Capture")
        ] {
            let source = try Self.appCode(file)
            XCTAssertTrue(
                source.contains("var deletedAt: Date?"),
                "\(type) has no `deletedAt`, so a fetch that decodes it cannot tell a deleted"
                    + " document from a live one."
            )
            XCTAssertTrue(
                source.contains("SoftDeletable"),
                "\(type) does not conform to `SoftDeletable`, so the shared filter cannot take it."
            )
        }
    }

    /// Tasks are snake_cased and captures are camelCase, and the two must not borrow each other's
    /// spelling — a wrong key here writes a field nothing reads, so the delete silently does
    /// nothing and the item stays in every list. `SoftDeleteCodecTests` asserts the same thing
    /// through the real codec; this catches it in the declaration.
    func testTheTwoCollectionsKeepTheirOwnSpelling() throws {
        let tasks = try Self.appCode("Tasks/TaskModels.swift")
        XCTAssertTrue(
            tasks.contains("case deletedAt = \"deleted_at\""),
            "A task's stamp is not snake_cased, which every other task field is."
        )
        let captures = try Self.appCode("Capture/CaptureModels.swift")
        XCTAssertFalse(
            captures.contains("case deletedAt = \"deleted_at\""),
            "A capture's stamp is snake_cased, but captures are camelCase apart from their own"
                + " named exceptions (`created_at`, `tag_ids`)."
        )
    }

    // MARK: - The writes (F-C3-RecentlyDeleted, cycle 4)

    /// **The delete and the restore are UPDATES, and that is what makes the app notice them.**
    /// `FirebaseManager.update(id:fields:in:)` posts `DataChangeSignal` from the write plumbing
    /// every adapter shares, so a restore reaches `TaskListView` and `CaptureInboxView` — both of
    /// which observe `DataChangeSignal.changes` — without any site posting by hand. Route either
    /// one around `update` and the item comes back on the next tab visit instead of at once, with
    /// nothing failing to say so.
    func testTheSoftDeleteAndRestoreWritesGoThroughTheSharedUpdatePlumbing() throws {
        // Pinned as whole expressions rather than as a count of `update(`, because captures
        // already had three of those and a count could not have told a soft delete that went
        // through the plumbing from one that did not.
        for (file, writes) in [
            ("Firebase/FirebaseManager+Tasks.swift", [
                "func softDeleteTask(id: UUID, now: Date = .now) async throws {",
                "update(id: id, fields: FirestoreFieldPayloads.taskSoftDelete(now: now), in: .tasks)",
                "func restoreTask(id: UUID) async throws {",
                "update(id: id, fields: FirestoreFieldPayloads.taskRestore(), in: .tasks)"
            ]),
            ("Firebase/FirebaseManager+Captures.swift", [
                "func softDeleteCapture(id: UUID, now: Date = .now) async throws {",
                "update(id: id, fields: FirestoreFieldPayloads.captureSoftDelete(now: now), in: .captures)",
                "func restoreCapture(id: UUID) async throws {",
                "update(id: id, fields: FirestoreFieldPayloads.captureRestore(), in: .captures)"
            ])
        ] {
            let source = try Self.appCode(file)
            for write in writes {
                XCTAssertTrue(
                    source.contains(write),
                    "`\(file)` no longer contains `\(write)`. Either the soft delete is missing,"
                        + " or it stopped going through `update(id:fields:in:)` — the write"
                        + " plumbing that posts `DataChangeSignal`, and therefore the reason a"
                        + " restored item comes back at once rather than on the next tab visit."
                )
            }
        }
    }

    /// The writes name the payload rather than building a dictionary inline — CLAUDE.md's
    /// "hand-written Firestore field dictionaries live in `FirestoreFieldPayloads`, never inline",
    /// which is also what keeps the two spellings assertable (`FirestoreFieldPayloadsSoftDeleteTests`).
    func testTheWritesUseThePayloadTypeRatherThanAnInlineDictionary() throws {
        let tasks = try Self.appCode("Firebase/FirebaseManager+Tasks.swift")
        XCTAssertTrue(tasks.contains("FirestoreFieldPayloads.taskSoftDelete(now:"))
        XCTAssertTrue(tasks.contains("FirestoreFieldPayloads.taskRestore()"))
        XCTAssertFalse(
            tasks.contains("\"deleted_at\":"),
            "A task's stamp is spelled inline here as well as in the payload — two spellings of"
                + " one key, free to drift, and a wrong one writes a field nothing reads."
        )

        let captures = try Self.appCode("Firebase/FirebaseManager+Captures.swift")
        XCTAssertTrue(captures.contains("FirestoreFieldPayloads.captureSoftDelete(now:"))
        XCTAssertTrue(captures.contains("FirestoreFieldPayloads.captureRestore()"))
        XCTAssertFalse(captures.contains("\"deletedAt\":"))
    }

    /// **`deleted(`, and never `live(`.** The Recently Deleted screen's two fetches want exactly
    /// the rows every other fetch drops, so they are the one pair that must NOT be wrapped — and
    /// wrapping one by reflex would leave that screen permanently empty, with every other test
    /// still green. The inverse is its own helper for the same reason the filter is:
    /// `.filter { $0.deletedAt != nil }` hand-written here would be a second reading of a rule
    /// that already has a subtlety (a FUTURE stamp is still a delete).
    func testTheRecentlyDeletedFetchesTakeTheInverseAndAreNotFilteredLive() throws {
        for file in [
            "Firebase/FirebaseManager+Tasks.swift", "Firebase/FirebaseManager+Captures.swift"
        ] {
            let source = try Self.appCode(file)
            XCTAssertEqual(
                Self.count(of: "deleted(try await", in: source), 1,
                "\(file)'s Recently Deleted fetch does not go through the shared `deleted(_:)`"
                    + " inverse, so this screen reads the stamp by a second rule."
            )
        }
        let helper = try Self.appCode("Firebase/FirebaseManager+SoftDelete.swift")
        XCTAssertTrue(
            helper.contains("func deleted<T: SoftDeletable>"),
            "There is no shared inverse, so each Recently Deleted fetch filters by hand."
        )
        XCTAssertTrue(
            helper.contains("!SoftDelete.isLive(deletedAt:"),
            "The inverse does not negate `SoftDelete.isLive`, so it is a second reading of the"
                + " rule rather than the same one turned round."
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
            throw SoftDeleteSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private enum SoftDeleteSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
