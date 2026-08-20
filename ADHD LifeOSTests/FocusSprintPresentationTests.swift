//
//  FocusSprintPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Three focus-surface rules E asked for on 2026-08-20, kept pure so they are testable away from
/// the views that render them.
final class FocusSprintPresentationTests: XCTestCase {
    private let taskId = UUID()

    // MARK: - Active Goal button state

    /// The hero's button always said "START SESSION", even while that very task's sprint was
    /// running — so Home gave no sign a sprint was live, and the obvious button re-started it.
    func testHeroAction_withNoSprint_offersToStart() {
        let state = ActiveGoalSprintState.resolve(taskId: taskId, sprint: nil)

        XCTAssertEqual(state, .idle)
        XCTAssertEqual(state.title, "Start Session")
        XCTAssertEqual(state.systemImage, "play.fill")
    }

    func testHeroAction_whileThisTasksSprintRuns_saysActive() {
        let state = ActiveGoalSprintState.resolve(
            taskId: taskId, sprint: ActiveSprintStatus(taskId: taskId, isPaused: false)
        )

        XCTAssertEqual(state, .running)
        XCTAssertEqual(state.title, "Session Active")
        XCTAssertEqual(state.systemImage, "pause.fill", "the glyph shows what the tap will DO")
    }

    func testHeroAction_whileThisTasksSprintIsPaused_saysPaused() {
        let state = ActiveGoalSprintState.resolve(
            taskId: taskId, sprint: ActiveSprintStatus(taskId: taskId, isPaused: true)
        )

        XCTAssertEqual(state, .paused)
        XCTAssertEqual(state.title, "Session Paused")
        XCTAssertEqual(state.systemImage, "play.fill")
    }

    func testHeroAction_whileANOTHERTasksSprintRuns_stillOffersToStart() {
        let state = ActiveGoalSprintState.resolve(
            taskId: taskId, sprint: ActiveSprintStatus(taskId: UUID(), isPaused: false)
        )

        XCTAssertEqual(state, .idle, "someone else's sprint is not this card's business")
    }

    func testHeroAction_forAnUnfiledTask_neverClaimsAnUnrelatedSprint() {
        // Both `nil` would compare equal — a task with no id must not adopt a sprint with no task.
        let state = ActiveGoalSprintState.resolve(
            taskId: nil, sprint: ActiveSprintStatus(taskId: nil, isPaused: false)
        )

        XCTAssertEqual(state, .idle)
    }

    // MARK: - Checkpoint dot state

    private func session(checkpoints: [Int], remaining: Int) -> FocusSession {
        var sut = FocusSession(
            taskId: taskId, taskTitle: "Walk", lifeAreaEmoji: "🫀",
            durationSeconds: 900, nudgeCheckpoints: checkpoints
        )
        _ = sut.advance(toRemaining: remaining)
        return sut
    }

    func testDotState_marksReachedNextAndPendingDistinctly() {
        // 300s elapsed of 900: the 225s mark has fired, 450 is next, 675 is still pending.
        let sut = session(checkpoints: [225, 450, 675], remaining: 600)

        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 0, session: sut), .reached)
        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 1, session: sut), .next)
        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 2, session: sut), .pending)
    }

    func testDotState_onAFreshSprint_theFirstMarkIsNext() {
        let sut = session(checkpoints: [225, 450], remaining: 900)

        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 0, session: sut), .next)
        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 1, session: sut), .pending)
    }

    func testDotState_onceEveryMarkHasFired_noneIsNext() {
        let sut = session(checkpoints: [225, 450], remaining: 100)

        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 0, session: sut), .reached)
        XCTAssertEqual(FocusCheckpointDotState.resolve(index: 1, session: sut), .reached)
    }

    // MARK: - Stop confirmation

    /// Stop is destructive and sits a thumb-width from `+5m`; it now asks first, and the question
    /// names what is actually at stake — the time already banked.
    func testStopConfirmation_namesTheFocusAboutToBeLogged() {
        let sut = session(checkpoints: [], remaining: 600)  // 5m elapsed

        let message = FocusStopConfirmation.message(for: sut)

        XCTAssertTrue(message.contains("5m"), "the elapsed time is the thing worth knowing: \(message)")
    }

    func testStopConfirmation_atTheVeryStart_doesNotBoastAboutZeroMinutes() {
        let sut = session(checkpoints: [], remaining: 900)

        XCTAssertEqual(
            FocusStopConfirmation.message(for: sut),
            "This sprint will end and nothing will be logged.",
            "0m focused is not an achievement to wave at the user"
        )
    }

    func testStopConfirmation_hasADestructiveVerbAndASafeWayOut() {
        XCTAssertEqual(FocusStopConfirmation.confirmTitle, "Stop sprint")
        XCTAssertEqual(FocusStopConfirmation.cancelTitle, "Keep going")
    }

    // MARK: - Floating bar status

    /// The always-visible bar is where a sprint is actually managed, so it must state paused-ness
    /// as plainly as the Home hero does — a "Resume" button alone reads as an option, not a state
    /// (E, 2026-08-20).
    func testBarStatus_whileRunning_showsNoBadge() {
        let sut = session(checkpoints: [], remaining: 600)

        XCTAssertNil(FocusBarStatus.pausedBadge(for: sut))
    }

    func testBarStatus_whilePaused_saysSo() {
        var sut = session(checkpoints: [], remaining: 600)
        sut.isPaused = true

        XCTAssertEqual(FocusBarStatus.pausedBadge(for: sut), "Paused")
    }

    func testBarAccessibilityLabel_carriesTheStateNotJustTheClock() {
        var sut = session(checkpoints: [], remaining: 600)
        sut.isPaused = true

        let label = FocusBarStatus.accessibilityLabel(for: sut)

        XCTAssertTrue(label.contains("Paused"), "VoiceOver must hear the state too: \(label)")
        XCTAssertTrue(label.contains("10:00"))
    }
}
