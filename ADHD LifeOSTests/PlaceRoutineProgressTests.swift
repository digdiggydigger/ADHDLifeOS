//
//  PlaceRoutineProgressTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The routine screen's progress semantics, exactly as the plan pins them (F-Routines-3):
/// "N of M done" counts auto-done + tapped-done; a SKIPPED step counts toward the bar's
/// resolved fraction but not the "done" wording; completion = no pending steps; Undo returns
/// done/skipped to pending; auto-done is immutable — it ran, and the record tells the truth.
final class PlaceRoutineProgressTests: XCTestCase {

    private func step(_ state: RoutineStepState, name: String = "Spotify") -> RoutineRun.Step {
        RoutineRun.Step(
            action: PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: name.lowercased(), displayName: name)
            ),
            state: state
        )
    }

    private func run(_ states: [RoutineStepState]) -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival,
            startedAt: Date(timeIntervalSince1970: 1_756_296_000),
            displayName: "Gym 🏋️", customMessage: nil,
            steps: states.map { step($0) }
        )
    }

    // MARK: - Counting

    func testDoneCount_countsAutoAndTappedDone_neverSkipped() {
        XCTAssertEqual(
            PlaceRoutineProgress.doneCount(run([.autoDone, .done, .skipped, .pending])), 2,
            "a skipped step is resolved, not DONE — the wording must not inflate"
        )
    }

    func testProgressLabel_isNOfMDone() {
        XCTAssertEqual(
            PlaceRoutineProgress.progressLabel(run([.autoDone, .done, .pending, .pending])),
            "2 of 4 done"
        )
    }

    func testResolvedFraction_includesSkipped() {
        XCTAssertEqual(
            PlaceRoutineProgress.resolvedFraction(run([.autoDone, .done, .skipped, .pending])),
            0.75,
            "the bar answers 'how much of this list is dealt with' — skipped is dealt with"
        )
    }

    func testCompletion_meansNoPendingSteps() {
        XCTAssertTrue(PlaceRoutineProgress.isFullyResolved(run([.autoDone, .done, .skipped])))
        XCTAssertFalse(PlaceRoutineProgress.isFullyResolved(run([.autoDone, .pending])))
    }

    func testNextPendingIndex_isTheFirstPendingInSavedOrder() {
        XCTAssertEqual(
            PlaceRoutineProgress.nextPendingIndex(run([.autoDone, .done, .pending, .pending])), 2
        )
        XCTAssertNil(PlaceRoutineProgress.nextPendingIndex(run([.autoDone, .done])))
    }

    // MARK: - The state machine

    func testMarking_pendingCanBecomeDoneOrSkipped() {
        let base = run([.pending, .pending])

        XCTAssertEqual(
            PlaceRoutineProgress.marking(base, stepAt: 0, as: .done).steps.map(\.state),
            [.done, .pending]
        )
        XCTAssertEqual(
            PlaceRoutineProgress.marking(base, stepAt: 1, as: .skipped).steps.map(\.state),
            [.pending, .skipped]
        )
    }

    func testMarking_undoReturnsDoneAndSkippedToPending() {
        XCTAssertEqual(
            PlaceRoutineProgress.marking(run([.done]), stepAt: 0, as: .pending).steps.map(\.state),
            [.pending]
        )
        XCTAssertEqual(
            PlaceRoutineProgress.marking(run([.skipped]), stepAt: 0, as: .pending).steps.map(\.state),
            [.pending]
        )
    }

    func testMarking_autoDoneIsImmutable() {
        let base = run([.autoDone])

        XCTAssertEqual(
            PlaceRoutineProgress.marking(base, stepAt: 0, as: .pending), base,
            "auto steps have no Undo — they RAN, and the record tells the truth"
        )
        XCTAssertEqual(PlaceRoutineProgress.marking(base, stepAt: 0, as: .done), base)
    }

    func testMarking_rejectsNonsenseWithoutTrapping() {
        let base = run([.done, .pending])

        // done → skipped is not a transition any control offers; out-of-bounds must not trap.
        XCTAssertEqual(PlaceRoutineProgress.marking(base, stepAt: 0, as: .skipped), base)
        XCTAssertEqual(PlaceRoutineProgress.marking(base, stepAt: 9, as: .done), base)
        XCTAssertEqual(PlaceRoutineProgress.marking(base, stepAt: 1, as: .autoDone), base)
    }
}
