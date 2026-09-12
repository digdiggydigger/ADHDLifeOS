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

    // MARK: - The streak on 7: one listener, in the service

    /// **Both `NudgeDueCard` hosts share Today's one service** — the section on Home and the
    /// pushed `NudgesView` — so the listener is the service's. In the card it would fire twice or
    /// once depending on which copy the user happened to tap.
    func testHomeHandsItsNudgesServiceTheCentre() throws {
        try assertPasses(
            "celebrate: celebrationCenter", toCall: "HomeView(", in: "RootView.swift",
            because: "Home owns the nudges service AND the ring that crosses the daily goal"
        )
        try assertPasses(
            "celebrate: celebrate", toCall: "NudgesService(", in: "Home/HomeView.swift",
            because: "Home holds the centre and the service that dismisses nudges never sees it"
        )
    }

    func testTheStreakMilestoneIsAskedForFromExactlyOnePlace() throws {
        let asks = try appTargetOccurrences(of: "request(.milestone(.streakSeven)")
        XCTAssertEqual(
            asks.count, 1,
            "\(asks.count) places ask for the streak milestone, not 1."
                + " Asked in: \(asks.map(\.file).sorted().joined(separator: ", "))."
        )
    }

    // MARK: - The daily goal: the milestone with no site

    /// **Both inputs, and the second is the one a reader would drop.** The count alone is not
    /// enough: Home's ring is a sum over three reloading sources, and the settle flag is what
    /// stops a failed fetch's dip — and the recovery from it — reading as a crossing. If only the
    /// count were observed, the tracker's guard would never see the transition back to settled.
    func testTheDailyGoalIsObservedFromHomeOnBothTheCountAndTheSettleFlag() throws {
        let home = try flattened("Home/HomeView.swift")
        XCTAssertTrue(
            home.contains(".onChange(of: ringCount)"),
            "Home never watches the ring's count, so the daily goal can never fire."
        )
        XCTAssertTrue(
            home.contains(".onChange(of: ringSettled)"),
            "Home never watches the settle flag, so the first observation after a failed fetch"
                + " recovers silently and the crossing it hid is lost."
        )
    }

    /// **R-h.** With E's switch off — or inside the cooldown — a milestone gets the fallback pop,
    /// and this is the one milestone site with no pop of its own. Passing the ring's measured
    /// origin is what makes that pop come from the ring rather than the middle of the screen.
    func testADowngradedDailyGoalPopsFromTheRingItself() throws {
        let observer = try flattened("Home/HomeView+DailyGoal.swift")
        XCTAssertTrue(
            observer.contains("celebrate.request(.milestone(.dailyGoal), at: ringOrigin)"),
            "The daily goal is requested with no origin, so R-h's fallback pop leaves from the"
                + " centre of the screen instead of from the ring."
        )
        XCTAssertTrue(
            try flattened("Home/MomentumScoreboardViews.swift").contains(".celebrationPopOrigin("),
            "The ring never records where it is, so `ringOrigin` is always nil."
        )
        XCTAssertTrue(
            try flattened("Home/HomeMomentumSections.swift").contains("onRingOrigin:"),
            "Home never asks the ring card for its origin, so nothing reaches `ringOrigin`."
        )
    }

    /// **E's call, 2026-09-12: the daily goal only.** The celebration itself is
    /// `accessibilityHidden`, and this milestone's site has neither a haptic of its own nor a
    /// guaranteed on-screen change — it can fire on any tab.
    func testTheDailyGoalAnnouncesItselfToVoiceOver() throws {
        let observer = try flattened("Home/HomeView+DailyGoal.swift")
        XCTAssertTrue(
            observer.contains("UIAccessibility.post(notification: .announcement"),
            "A VoiceOver user is never told the daily goal was reached — the celebration is hidden"
                + " from them and this site has no haptic and no guaranteed on-screen change."
        )
        XCTAssertTrue(observer.contains("DailyGoalAnnouncement.text("))
    }

    /// **F7's "once per day" is only true if the day is marked BEFORE the request**, because
    /// nothing downstream marks it — a request that fired and then failed to mark would replay on
    /// the next crossing, and an undo-and-recross is exactly that.
    func testTheDayIsMarkedBeforeTheDailyGoalIsRequested() throws {
        let observer = try flattened("Home/HomeView+DailyGoal.swift")
        let marked = try XCTUnwrap(
            observer.range(of: "CelebrationDayMarking.markCelebrated("),
            "Nothing marks the day, so F7's once-per-day is not enforced at all."
        )
        let requested = try XCTUnwrap(observer.range(of: "celebrate.request(.milestone(.dailyGoal)"))
        XCTAssertLessThan(
            marked.lowerBound, requested.lowerBound,
            "The day is marked after the request rather than before it."
        )
    }

    func testTheDailyGoalMilestoneIsAskedForFromExactlyOnePlace() throws {
        let asks = try appTargetOccurrences(of: "request(.milestone(.dailyGoal)")
        XCTAssertEqual(
            asks.count, 1,
            "\(asks.count) places ask for the daily goal, not 1."
                + " Asked in: \(asks.map(\.file).sorted().joined(separator: ", "))."
        )
    }

    // MARK: - Reading the tree

    private func assertPasses(
        _ argument: String, toCall call: String, in file: String, because reason: String,
        line: UInt = #line
    ) throws {
        try assertAnchorIsUnique(call, in: file, line: line)
        let arguments = try argumentList(ofCall: call, in: file)
        XCTAssertTrue(
            arguments.contains(argument),
            "\(file) builds \(call)…) without `\(argument)`, so it gets the INERT default and"
                + " celebrates nothing — \(reason).",
            line: line
        )
    }

    /// **A call's arguments, to its MATCHING close paren** — depth-tracked, not "up to the next
    /// `)`".
    ///
    /// The naive version cost a run and is worth recording: `HomeView(…)` carries
    /// `onToggleSprintPause: { focusService.togglePause() }`, so the first `)` after the call falls
    /// inside a closure a dozen arguments early, and the guard reported an argument missing that
    /// was plainly there. A guard that reads the wrong text is worse than no guard, because it
    /// fails in the believable direction.
    private func argumentList(ofCall call: String, in file: String) throws -> String {
        let source = try flattened(file)
        guard let start = source.range(of: call) else {
            throw MilestoneSiteError.anchorMissing(file, call)
        }
        var depth = 1
        var index = start.upperBound
        while index < source.endIndex {
            if source[index] == "(" { depth += 1 }
            if source[index] == ")" {
                depth -= 1
                if depth == 0 { return String(source[start.upperBound..<index]) }
            }
            index = source.index(after: index)
        }
        throw MilestoneSiteError.anchorMissing(file, "the closing paren of \(call)")
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
