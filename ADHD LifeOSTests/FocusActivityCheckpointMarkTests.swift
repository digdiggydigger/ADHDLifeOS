//
//  FocusActivityCheckpointMarkTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The checkpoint markers the Lock Screen banner and the Dynamic Island draw on the sprint's
/// progress track, plus the "N of M checkpoints" caption beside them.
///
/// The resolution deliberately lives on the SHARED content state rather than in the widget's view
/// code: the extension has no test bundle of its own, so this is the only place the rule can be
/// asserted — and it is the rule, not the drawing, that can be wrong.
@available(iOS 16.1, *)
final class FocusActivityCheckpointMarkTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func state(
        durationSeconds: Int = 900,
        checkpointSeconds: [Int] = [300, 600],
        checkpointsReached: Int = 0,
        isCompleted: Bool = false
    ) -> FocusActivityAttributes.ContentState {
        FocusActivityAttributes.ContentState(
            taskTitle: "Draft the review",
            lifeAreaEmoji: "💼",
            durationSeconds: durationSeconds,
            deadline: now.addingTimeInterval(600),
            pausedAt: nil,
            checkpointCount: checkpointSeconds.count,
            checkpointsReached: checkpointsReached,
            checkpointSeconds: checkpointSeconds,
            isCompleted: isCompleted
        )
    }

    // MARK: - Positions

    func testMarks_sitAtTheElapsedFractionOfThePlannedDuration() {
        let marks = state(durationSeconds: 900, checkpointSeconds: [300, 600]).checkpointMarks()

        XCTAssertEqual(marks.count, 2)
        XCTAssertEqual(marks[0].fraction, 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(marks[1].fraction, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testMarks_keepTheirIndexSoTheViewCanIdentifyThem() {
        let marks = state(checkpointSeconds: [100, 200, 300]).checkpointMarks()

        XCTAssertEqual(marks.map(\.index), [0, 1, 2])
        XCTAssertEqual(marks.map(\.id), [0, 1, 2])
    }

    /// An extension grows `durationSeconds` without re-spacing marks already planned, so positions
    /// stay strictly inside the track — but a state assembled from a stale payload must not be able
    /// to push a marker off the end of the bar.
    func testMarks_clampAFractionThatWouldOverrunTheTrack() {
        let marks = state(durationSeconds: 300, checkpointSeconds: [600]).checkpointMarks()

        XCTAssertEqual(marks[0].fraction, 1)
    }

    func testMarks_withZeroDuration_areEmptyRatherThanNaN() {
        XCTAssertTrue(state(durationSeconds: 0, checkpointSeconds: [10]).checkpointMarks().isEmpty)
    }

    func testMarks_withNoCheckpoints_areEmpty() {
        XCTAssertTrue(state(checkpointSeconds: []).checkpointMarks().isEmpty)
    }

    // MARK: - States

    /// Fired marks are always the LEADING PREFIX of the plan — `FocusCheckpoints.replanned` keeps
    /// that invariant across a mid-sprint cadence change — so the count alone separates reached from
    /// pending, and the mark at exactly that index is the one coming up.
    func testMarkStates_splitAtTheReachedCountWithTheNextOneHighlighted() {
        let marks = state(checkpointSeconds: [200, 400, 600], checkpointsReached: 1).checkpointMarks()

        XCTAssertEqual(marks.map(\.state), [.reached, .next, .pending])
    }

    func testMarkStates_withNothingReached_makeTheFirstMarkNext() {
        let marks = state(checkpointSeconds: [200, 400], checkpointsReached: 0).checkpointMarks()

        XCTAssertEqual(marks.map(\.state), [.next, .pending])
    }

    func testMarkStates_withEveryMarkReached_haveNoNext() {
        let marks = state(checkpointSeconds: [200, 400], checkpointsReached: 2).checkpointMarks()

        XCTAssertEqual(marks.map(\.state), [.reached, .reached])
    }

    /// The sprint that ran out behind a locked screen: the app was suspended and could not push the
    /// final count, but every checkpoint sits strictly before the finish, so a finished sprint has
    /// passed all of them. Rendering one as "up next" on a completed card would be a lie.
    func testMarkStates_onACompletedFrame_areAllReachedEvenIfTheCountIsStale() {
        let marks = state(checkpointSeconds: [200, 400], checkpointsReached: 0)
            .checkpointMarks(isComplete: true)

        XCTAssertEqual(marks.map(\.state), [.reached, .reached])
    }

    // MARK: - Caption

    func testSummary_readsNOfM() {
        let summary = state(checkpointSeconds: [200, 400, 600], checkpointsReached: 1)
            .checkpointSummary()

        XCTAssertEqual(summary, "1 of 3 checkpoints")
    }

    func testSummary_singularWhenTheSprintPlansOneCheckpoint() {
        XCTAssertEqual(
            state(checkpointSeconds: [400], checkpointsReached: 0).checkpointSummary(),
            "0 of 1 checkpoint"
        )
    }

    func testSummary_onACompletedFrame_countsEveryCheckpoint() {
        let summary = state(checkpointSeconds: [200, 400], checkpointsReached: 0)
            .checkpointSummary(isComplete: true)

        XCTAssertEqual(summary, "2 of 2 checkpoints")
    }

    func testSummary_withNoCheckpoints_isNilSoNoSurfaceDrawsAnEmptyCaption() {
        XCTAssertNil(state(checkpointSeconds: []).checkpointSummary())
    }

    func testSummary_clampsACountThatOverrunsThePlan() {
        // Belt and braces: the caption must never read "3 of 2".
        XCTAssertEqual(
            state(checkpointSeconds: [200, 400], checkpointsReached: 5).checkpointSummary(),
            "2 of 2 checkpoints"
        )
    }

    // MARK: - Codable (the payload crosses two processes)

    func testCodableRoundTrip_preservesTheCheckpointPositions() throws {
        let original = state(checkpointSeconds: [200, 400, 600], checkpointsReached: 2)

        let decoded = try JSONDecoder().decode(
            FocusActivityAttributes.ContentState.self, from: try JSONEncoder().encode(original)
        )

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.checkpointSeconds, [200, 400, 600])
    }

    /// An Activity started before an app update is decoded by the NEW extension from the OLD
    /// archived state. A synthesized decoder would throw on the missing key and the running sprint's
    /// card would go blank mid-sprint; it degrades to "no markers" instead.
    func testDecoding_aPayloadWithoutCheckpointPositions_degradesToNoMarkers() throws {
        let legacy = """
        {
          "taskTitle": "Draft the review",
          "lifeAreaEmoji": "💼",
          "durationSeconds": 900,
          "deadline": \(now.timeIntervalSinceReferenceDate),
          "checkpointCount": 2,
          "checkpointsReached": 1,
          "isCompleted": false
        }
        """

        let decoded = try JSONDecoder().decode(
            FocusActivityAttributes.ContentState.self, from: Data(legacy.utf8)
        )

        XCTAssertEqual(decoded.checkpointSeconds, [])
        XCTAssertTrue(decoded.checkpointMarks().isEmpty)
        XCTAssertEqual(decoded.checkpointSummary(), "1 of 2 checkpoints", "the counts still render")
    }
}
