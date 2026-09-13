//
//  PlaceRoutineCompletionCallSiteTests.swift
//  ADHD LifeOSTests
//
//  REACHABILITY and SHAPE guards for `F-CTACelebrations-6` — this repo's most-repeated defect is
//  a component that is written, unit-tested, correct and called by nothing, so the pure layer's
//  tests are not enough on their own.
//
//  Source is read with comment lines stripped and flattened to one line, the `*CallSiteTests`
//  house shape, so a guard cannot go green on a claim that only appears in a comment.
//

import XCTest

final class PlaceRoutineCompletionCallSiteTests: XCTestCase {

    // MARK: - E's answer 6: the glyph shrinks with the list

    /// `minimumScaleFactor` scales `Text` and never a `Circle`, so twenty rows of the hard
    /// 28×28 circle is 560 pt of glyph alone. The circle has to be sizeable or "shrink to fit"
    /// cannot be true.
    func testTheStepCircleCanBeSizedSoALongListCanShrinkIt() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineScreenRows.swift").contains("var size: CGFloat = 28"),
            "PlaceRoutineStepCircle is a fixed size again, so a 20-step congratulation cannot fit"
        )
    }

    /// The DEFAULT is what keeps "reuse the existing circle" true — E's answer 9 asked for the
    /// routine screen's own rows, and a default of 28 means neither existing row changed at all.
    func testTheTwoExistingStepCircleCallSitesKeepTheDefaultSize() throws {
        let rows = try flattened("Places/PlaceRoutineScreenRows.swift")
        XCTAssertEqual(
            rows.components(separatedBy: "PlaceRoutineStepCircle(state:").count - 1, 2,
            "the resolved row and the upcoming row must both still build the circle by state"
                + " alone — passing a size at either would change a screen this block never"
                + " intended to touch"
        )
    }

    func testTheCongratulationSizesItsGlyphsFromTheDensityTable() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineCongratulationView.swift")
                .contains("size: density.circleSize"),
            "the congratulation draws a fixed-size glyph, so its own density table is decoration"
        )
    }

    // MARK: - §7.2: the leaf is deterministic, and the motion is the SCREEN's decision

    /// Design answer B: **the leaf gets no internal animation at all.** That is what makes
    /// §7.2's opening-pose rule true by CONSTRUCTION rather than by inspection — there is no
    /// first frame for the geometry to be wrong in — and it is what makes a render of this view
    /// deterministic evidence rather than a screenshot of a moment.
    func testTheCongratulationLeafCarriesNoMotionOfItsOwn() throws {
        let view = try flattened("Places/PlaceRoutineCongratulationView.swift")
        XCTAssertFalse(view.contains("withAnimation"), "the leaf animates something itself")
        XCTAssertFalse(view.contains(".animation("), "the leaf animates something itself")
        XCTAssertFalse(
            view.contains(".transition("),
            "the entrance belongs to the ZStack branch in the SCREEN, not to the leaf"
        )
    }

    /// §7.2: Reduce Motion is resolved by the parent and reaches the motion as a PARAMETER. A
    /// leaf that read the environment could not be rendered in both modes, because
    /// `accessibilityReduceMotion` cannot be injected through `.environment(\.)`.
    func testTheCongratulationLeafNeverReadsReduceMotionItself() throws {
        XCTAssertFalse(
            try flattened("Places/PlaceRoutineCongratulationView.swift")
                .contains("accessibilityReduceMotion"),
            "the leaf reads the setting, so the screen is no longer the one place that decides"
                + " and the leaf can no longer be rendered in both modes"
        )
    }

    // MARK: - The plan's risk 7: there is no Close button for up to 5.4 s

    func testTheCongratulationCanAlwaysBeSkipped() throws {
        let view = try flattened("Places/PlaceRoutineCongratulationView.swift")
        XCTAssertTrue(
            view.contains("accessibilityAction(named: Text(PlaceRoutineCompletionCopy.skipAction), onSkip)"),
            "the congratulation takes the Close button off screen for up to 5.4 s, so for"
                + " VoiceOver this action is the ONLY way out"
        )
        XCTAssertFalse(
            view.contains("accessibilityHidden(true)"),
            "hiding the view from accessibility would hide the one escape with it"
        )
    }

    /// The plan's risk 4. **Both UI journeys resolve the gym routine as 1 auto + 3 skipped, so
    /// R-f is NOT earned and neither ever sees confetti.** A journey waiting on paper that is
    /// never coming hangs to the timeout and reads exactly like a render failure, so both wait
    /// on this instead.
    func testTheGreetingIsIdentifiedSoAJourneyHasSomethingDeterministicToWaitOn() throws {
        XCTAssertTrue(
            try flattened("Places/PlaceRoutineCongratulationView.swift")
                .contains("accessibilityIdentifier(\"routineCongratulationGreeting\")"),
            "nothing on the congratulation is addressable, so a journey can only wait on confetti"
        )
    }

    /// E's answer 6 chose "show every step, shrink to fit" over scrolling, and the reason is
    /// mechanical: the whole view is one tap target, and a scroll gesture would fight it.
    func testTheStepListNeverScrolls() throws {
        XCTAssertFalse(
            try flattened("Places/PlaceRoutineCongratulationView.swift").contains("ScrollView"),
            "a ScrollView here would swallow the tap that skips the celebration"
        )
    }

    // MARK: - Reading the tree

    private func flattened(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CompletionSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private enum CompletionSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`) — if the file has not been written yet, that is the point."
            }
        }
    }
}
