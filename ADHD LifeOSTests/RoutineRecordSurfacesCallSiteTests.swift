//
//  RoutineRecordSurfacesCallSiteTests.swift
//  ADHD LifeOSTests
//
//  REACHABILITY for the routine record's surfaces (F-RoutineRecord-2). The timeline rules and
//  every word are pinned by `JournalRoutineRowsTests`; these read the SOURCE to prove the
//  Journal actually renders the three kinds, the header actually renders the switch that
//  reveals the offers, and the Tools section actually hands its runs to the catalog.
//

import XCTest

final class RoutineRecordSurfacesCallSiteTests: XCTestCase {

    func testTheJournalRendersAllThreeRoutineRowKinds() throws {
        let sections = try Self.code("Journal/JournalTimelineSections.swift")

        for kind in ["routineOffered", "routineStarted", "routineEnded"] {
            XCTAssertTrue(
                sections.contains("case .\(kind)(let"),
                "the day stream must render `.\(kind)` — an entry kind the timeline produces and"
                    + " the switch never draws is a row nobody can see"
            )
        }
    }

    func testTheTimelineIsBuiltWithTheRunsAndTheSwitch() throws {
        let sections = try Self.code("Journal/JournalTimelineSections.swift")

        XCTAssertTrue(
            sections.contains("routineRuns: journalService.routineRuns"),
            "the service publishes the runs; the timeline must be handed them"
        )
        XCTAssertTrue(
            sections.contains("showAllActivity: showAllActivity"),
            "the header switch must reach the timeline rule, or it is a switch wired to nothing"
        )
    }

    func testTheHeaderRendersTheAllActivitySwitch() throws {
        let view = try Self.code("Journal/JournalView.swift")

        XCTAssertTrue(
            view.contains(".accessibilityIdentifier(\"journalAllActivitySwitch\")"),
            "the switch is the ONLY way an ignored offer becomes visible (E's call: hidden by"
                + " default) — unrendered, the offer records exist for nobody"
        )
        XCTAssertTrue(
            view.contains("@State var showAllActivity = false"),
            "off on every launch and not persisted — E's 'hidden by default', read literally"
        )
        let rows = try Self.code("Journal/JournalTimeline+RoutineRows.swift")
        XCTAssertTrue(
            rows.contains("guard showAllActivity else { return [] }"),
            "E's device-walk call: the switch gates EVERY routine row, so the gate is one guard"
                + " at the top — not a per-phase decision that could let a row through"
        )
    }

    func testTheToolsSectionHandsItsRunsToTheCatalog() throws {
        let section = try Self.code("Tools/ToolsRoutinesSection.swift")

        XCTAssertTrue(
            section.contains("ToolsRoutinesCatalog.content(from: service.places, runs: history.runs"),
            "the last-run line is computed by the catalog from the runs the section loads —"
                + " a section that never passes them renders yesterday's subtitle forever"
        )
        XCTAssertTrue(
            section.contains("await history.load()"),
            "and the section must actually LOAD the history"
        )
    }

    /// One reconciler type behind both loads. Two copies of the passive-ending rule would be
    /// the drift this repo keeps rediscovering.
    func testBothLoadsShareTheReconciler() throws {
        let journal = try Self.code("Journal/JournalService.swift")
        let history = try Self.code("Places/RoutineRunHistoryService.swift")

        XCTAssertTrue(journal.contains("RoutineRunReconciler"))
        XCTAssertTrue(history.contains("RoutineRunReconciler"))
        XCTAssertFalse(
            journal.contains("RoutineRunReconciliation.updates("),
            "the Journal service must go THROUGH the reconciler, not re-run the rule beside it"
        )
    }

    // MARK: - Reading the tree

    private static func code(_ relativePath: String) throws -> String {
        let source = try appSource(relativePath)
        var output = ""
        var index = source.startIndex
        while index < source.endIndex {
            if source[index...].hasPrefix("//") {
                while index < source.endIndex, source[index] != "\n" {
                    index = source.index(after: index)
                }
            } else {
                output.append(source[index])
                index = source.index(after: index)
            }
        }
        return output
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        return text
    }

    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
