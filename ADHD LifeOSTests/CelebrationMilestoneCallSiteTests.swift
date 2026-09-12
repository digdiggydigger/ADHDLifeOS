//
//  CelebrationMilestoneCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-5`'s reachability guards for E's three full-screen milestones — inbox zero,
//  the streak on 7 and the daily goal (F3, F7, F8).
//
//  **Why a whole file of greps, again.** The two milestone services take the centre as a defaulted
//  `init` parameter whose default is INERT, which is what lets every other host, preview and test
//  build them unchanged — and is exactly why a host that forgets to pass it compiles, runs, passes
//  every service test in the suite and celebrates nothing, for ever. `F-CTACelebrations-3` shipped
//  three correct, fully-tested, completely unreachable types; tests prove correctness, never
//  REACHABILITY.
//
//  Source is read with comment lines stripped and flattened to one line, so adding an argument and
//  re-flowing a call does not break a guard — the `*CallSiteTests` house shape.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationMilestoneCallSiteTests: XCTestCase {

    // MARK: - Inbox zero: every door that can clear the inbox holds the real centre

    /// Five screens host a `CaptureInboxService`. Three of them can reach a doing verb, and each
    /// needs the centre threaded to it by hand — an `@Environment` read is not available in the
    /// `init` where a `@StateObject` service is built.
    func testTheCapturesTabHandsItsServiceTheCentre() throws {
        try assertPasses(
            "celebrate: celebrationCenter", toCall: "CaptureInboxView(", in: "RootView.swift",
            because: "the Captures tab is where all three doing verbs live"
        )
        try assertPasses(
            "celebrate: celebrate", toCall: "CaptureInboxService(", in: "Capture/CaptureInboxView.swift",
            because: "the tab holds the centre and its service never sees it"
        )
    }

    /// Home's inbox peek and the Journal timeline both push a capture detail, and a detail screen
    /// can Sort, Journal it or Create Task exactly as the tab can.
    func testBothPushedCaptureDoorsCarryTheCentreToTheirService() throws {
        try assertPasses(
            "celebrate: celebrate", toCall: "JournalCaptureDoor(", in: "Home/HomeCaptureDoor.swift",
            because: "a capture cleared from Today's peek empties the same inbox"
        )
        try assertPasses(
            "celebrate: celebrate", toCall: "JournalCaptureDoor(", in: "Journal/JournalView.swift",
            because: "a capture cleared from the Journal timeline empties the same inbox"
        )
        try assertPasses(
            "celebrate: celebrate", toCall: "CaptureInboxService(",
            in: "Journal/JournalTimelineSections.swift",
            because: "the door holds the centre and the service it owns never sees it"
        )
    }

    /// **R-a as a count.** Every exit — sort, journal, promote, discard, undo-seen — funnels
    /// through the same `removeCapture`, so the listener sits one level ABOVE it, on the three
    /// verbs E named. A fourth call here would be a binned inbox celebrating like a cleared one.
    func testExactlyTheThreeDoingVerbsAskForInboxZero() throws {
        let calls = try appTargetOccurrences(of: "celebrateIfInboxCleared(capture)")
        XCTAssertEqual(
            calls.count, 3,
            "\(calls.count) verbs ask for inbox zero, not 3 (Sorted, Journal it, Create Task)."
                + " Asked in: \(calls.map(\.file).sorted().joined(separator: ", "))."
                + " R-a: a discard is tidying, not doing."
        )
    }

    func testDiscardingACaptureNeverAsksForInboxZero() throws {
        let discard = try slice(
            in: "Capture/CaptureInboxService+Triage.swift",
            // NOT a doc comment: `stripped` removes comment lines before the slice is cut, so a
            // comment anchor reads as missing and the guard throws instead of asserting.
            from: "func discard(capture: Capture) async -> Bool", to: "func undoSeen(capture: Capture)"
        )
        XCTAssertFalse(
            discard.contains("celebrateIfInboxCleared"),
            "Discard asks for the milestone. R-a: binning the last capture is tidying, not doing."
        )
    }

    // MARK: - Reading the tree

    private func assertPasses(
        _ argument: String, toCall call: String, in file: String, because reason: String,
        line: UInt = #line
    ) throws {
        try assertAnchorIsUnique(call, in: file, line: line)
        let arguments = try slice(in: file, from: call, to: ")")
        XCTAssertTrue(
            arguments.contains(argument),
            "\(file) builds \(call)…) without `\(argument)`, so it gets the INERT default and"
                + " celebrates nothing — \(reason).",
            line: line
        )
    }

    /// A guard anchored on a string that appears twice is a guard on whichever comes first.
    private func assertAnchorIsUnique(_ anchor: String, in file: String, line: UInt = #line) throws {
        let occurrences = try flattened(file).components(separatedBy: anchor).count - 1
        XCTAssertEqual(
            occurrences, 1,
            "`\(anchor)` appears \(occurrences) times in \(file); this guard would be reading"
                + " whichever one comes first.",
            line: line
        )
    }

    private func slice(in relativePath: String, from opening: String, to closing: String) throws -> String {
        let source = try flattened(relativePath)
        guard let start = source.range(of: opening) else {
            throw MilestoneSiteError.anchorMissing(relativePath, opening)
        }
        guard let end = source.range(of: closing, range: start.upperBound..<source.endIndex) else {
            throw MilestoneSiteError.anchorMissing(relativePath, closing)
        }
        return String(source[start.upperBound..<end.lowerBound])
    }

    private func flattened(_ relativePath: String) throws -> String {
        try appCode(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private func appCode(_ relativePath: String) throws -> String {
        let url = Self.appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw MilestoneSiteError.unreadable(url.path)
        }
        return stripped(text)
    }

    private func appTargetOccurrences(of needle: String) throws -> [(file: String, count: Int)] {
        guard let walker = FileManager.default.enumerator(
            at: Self.appRoot, includingPropertiesForKeys: nil
        ) else {
            throw MilestoneSiteError.unreadable(Self.appRoot.path)
        }
        var found: [(file: String, count: Int)] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let count = stripped(text).components(separatedBy: needle).count - 1
            if count > 0 { found.append((url.lastPathComponent, count)) }
        }
        return found.flatMap { entry in Array(repeating: entry, count: entry.count) }
    }

    private func stripped(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ADHD LifeOS")

    private enum MilestoneSiteError: Error, CustomStringConvertible {
        case unreadable(String)
        case anchorMissing(String, String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path)."
            case .anchorMissing(let file, let anchor):
                return "`\(anchor)` is not in \(file) any more — the guard is reading nothing."
            }
        }
    }
}
