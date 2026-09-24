//
//  TasksAnytimeRowCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-D3-TasksAnytimeRow` — the view half of round 6's "Anytime · N" row.
//
//  `MomentumTaskBucketsTests` proves undated tasks reach the fourth bucket. It cannot prove the
//  board FOLDS that bucket, that the fold starts closed, or that its rows stay quiet — those are
//  decisions that live in `TaskListView`'s body, where a unit test cannot reach. So they are
//  asserted here by what the code says, with comment lines stripped (the
//  `PinnedSectionHeaderCallSiteTests` posture: a guard satisfiable by prose is no guard).
//
//  Round 6, E's words: *"The Tasks board gains one collapsed 'Anytime · N' row at the bottom: the
//  tail stays folded, but a new task is visible where it was added."*
//

import XCTest
@testable import ADHD_LifeOS

final class TasksAnytimeRowCallSiteTests: XCTestCase {

    /// The one id both halves agree on. The view keys its fold on this constant, never on a
    /// re-typed string, so the bucket and the fold cannot drift apart silently.
    func testTheAnytimeGroupCarriesTheIdTheViewFoldsOn() {
        let undated = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Undated", status: .open, priority: .p3, dueDate: nil
        )
        let groups = MomentumTaskBuckets.group(tasks: [undated])

        XCTAssertEqual(groups.map(\.customId), [MomentumTaskBuckets.anytimeGroupId])
        XCTAssertEqual(MomentumTaskBuckets.anytimeGroupId, "momentum-anytime")
    }

    /// **The default is the whole round-6 decision** — "the tail stays folded". Home's life-area
    /// fold defaults OPEN; this one must default CLOSED, and a stored preference (not `@State`) so
    /// it does not spring back open on the next launch.
    func testTheFoldIsAStoredPreferenceThatStartsCollapsed() throws {
        let code = try Self.taskListCode()
        XCTAssertTrue(
            code.contains(#"@AppStorage("tasks.anytimeCollapsed") private var anytimeCollapsed = true"#),
            "The Anytime fold must be `@AppStorage(\"tasks.anytimeCollapsed\")` defaulting to TRUE"
                + " (collapsed) — round 6: \"the tail stays folded\"."
        )
    }

    /// The house fold, not a hand-rolled one: `CollapsibleSectionHeader` carries the chevron
    /// convention (it points AT the content, E 2026-08-28), the VoiceOver state hint and the 44pt
    /// target. And it is chosen by the shared id.
    func testTheAnytimeHeaderIsTheSharedCollapsibleHeader() throws {
        let code = try Self.taskListCode()
        XCTAssertTrue(code.contains("CollapsibleSectionHeader("), "Anytime must use the shared fold")
        XCTAssertTrue(
            code.contains("MomentumTaskBuckets.anytimeGroupId"),
            "The fold must be keyed on `MomentumTaskBuckets.anytimeGroupId`, not a re-typed string"
        )
        XCTAssertTrue(
            code.contains("onToggle: { anytimeCollapsed.toggle() }"),
            "The header must toggle the stored fold"
        )
    }

    /// Folding must actually hide the rows: the row card is gated on the fold.
    func testTheRowsAreGatedOnTheFold() throws {
        let code = try Self.taskListCode()
        XCTAssertTrue(
            code.contains("if !isFolded(group) {"),
            "The Anytime rows must render only while the fold is open"
        )
        XCTAssertTrue(
            code.contains("group.customId == MomentumTaskBuckets.anytimeGroupId && anytimeCollapsed"),
            "`isFolded` must fold the Anytime group, and only while the stored fold is closed"
        )
    }

    /// The header is PINNED (the list pins section headers), and Anytime is the one bucket whose
    /// own rows scroll under its own header once opened. So it must be painted the page, the same
    /// surface `pinnedSectionHeader()` gives every other header — or rows show through it.
    func testThePinnedFoldIsPaintedThePage() throws {
        let code = try Self.taskListCode()
        XCTAssertTrue(
            code.contains(".background(Color(PinnedHeaderMetrics.surfaceAssetName))"),
            "The Anytime header is pinned; it must carry the pinned surface or rows show through"
        )
    }

    /// E's b11 call: the ▶ sprint launcher is a TODAY thing and rides only Due today. Anytime
    /// rows get the quieter tap-circle only — true by construction, since the key is Due today's
    /// id; this pins that nobody widens it to the new bucket.
    func testTheSprintLauncherStaysOnDueTodayOnly() throws {
        let code = try Self.taskListCode()
        XCTAssertTrue(
            code.contains(#"let showsSprintStart = group.customId == "momentum-dueToday""#),
            "The ▶ sprint launcher must stay keyed to Due today alone"
        )
        XCTAssertEqual(
            code.components(separatedBy: "showsSprintStart =").count - 1, 1,
            "`showsSprintStart` must be decided in exactly one place"
        )
    }

    // MARK: - Reading the tree

    private static func taskListCode() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS/Tasks/TaskListView.swift")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw AnytimeSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    /// Loud rather than skipped: a guard that quietly disables itself is what these tests prevent.
    private enum AnytimeSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
