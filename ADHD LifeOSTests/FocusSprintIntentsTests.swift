//
//  FocusSprintIntentsTests.swift
//  ADHD LifeOSTests
//

import ActivityKit
import XCTest
@testable import ADHD_LifeOS

/// The app-side half of the Lock Screen's Pause and Stop buttons.
///
/// `LiveActivityIntent` performs in the APP's process rather than the extension's — that is the
/// whole reason these types exist, and it is what lets a Lock Screen tap drive the real
/// `FocusSessionService` instead of some serialized shadow of it. So each intent ships TWO paths,
/// and until now neither was exercised: the live engine, reached through
/// `FocusSprintIntentActions` (populated at launch by `FocusSessionService.withLiveActivityMirroring`),
/// and an orphan sweep for the case the system cold-launched the app purely to run the intent, where
/// no engine exists and whatever is on the Lock Screen belongs to a sprint that is already dead.
///
/// **The sweep's loop body is deliberately not asserted.** Ending a real `Activity` needs an
/// entitled process, so `Activity.activities` is always empty here — the same exclusion
/// `FocusActivityContentStateTests` records for the mirror's own `Activity` calls.
@available(iOS 17.0, *)
@MainActor
final class FocusSprintIntentsTests: XCTestCase {
    /// Records a call instead of driving the engine — the house recording-fake pattern, sized to
    /// the one thing these actions are: a closure that either ran or did not.
    private final class ActionRecorder {
        private(set) var pauseResumeCalls = 0
        private(set) var stopCalls = 0

        func recordPauseResume() { pauseResumeCalls += 1 }
        func recordStop() { stopCalls += 1 }
    }

    private var recorder = ActionRecorder()
    private var savedPauseResume: (() async -> Void)?
    private var savedStop: (() async -> Void)?

    override func setUp() async throws {
        try await super.setUp()
        // The host app populates these at launch, and they are process-wide statics — capture
        // whatever was there so a later test never sees this one's nil.
        savedPauseResume = FocusSprintIntentActions.pauseResume
        savedStop = FocusSprintIntentActions.stop
        recorder = ActionRecorder()
    }

    override func tearDown() async throws {
        FocusSprintIntentActions.pauseResume = savedPauseResume
        FocusSprintIntentActions.stop = savedStop
        try await super.tearDown()
    }

    private func installRecordingActions() {
        let recorder = recorder
        FocusSprintIntentActions.pauseResume = { recorder.recordPauseResume() }
        FocusSprintIntentActions.stop = { recorder.recordStop() }
    }

    // MARK: - The live-engine path

    func testPauseResumeIntent_withALiveEngine_callsThePauseResumeAction() async throws {
        installRecordingActions()

        _ = try await PauseResumeFocusSprintIntent().perform()

        XCTAssertEqual(recorder.pauseResumeCalls, 1)
        XCTAssertEqual(recorder.stopCalls, 0, "Pause/Resume must never reach the stop action")
    }

    func testStopIntent_withALiveEngine_callsTheStopAction() async throws {
        installRecordingActions()

        _ = try await StopFocusSprintIntent().perform()

        XCTAssertEqual(recorder.stopCalls, 1)
        XCTAssertEqual(recorder.pauseResumeCalls, 0, "Stop must never reach the pause/resume action")
    }

    /// The two actions are wired independently, so a single intent firing both would be a live bug
    /// on the Lock Screen — a Pause tap that also killed the sprint.
    func testTheTwoIntents_areWiredToSeparateActions() async throws {
        installRecordingActions()

        _ = try await PauseResumeFocusSprintIntent().perform()
        _ = try await StopFocusSprintIntent().perform()

        XCTAssertEqual(recorder.pauseResumeCalls, 1)
        XCTAssertEqual(recorder.stopCalls, 1)
    }

    // MARK: - The cold-launch path

    /// A tap that cold-launches the app finds no engine. The intent must still return — trapping on
    /// the nil action would surface as a Lock Screen button that does nothing and spins.
    func testPauseResumeIntent_withNoEngine_sweepsOrphansInsteadOfCallingThrough() async throws {
        FocusSprintIntentActions.pauseResume = nil
        FocusSprintIntentActions.stop = { [recorder] in recorder.recordStop() }

        _ = try await PauseResumeFocusSprintIntent().perform()

        XCTAssertEqual(recorder.stopCalls, 0, "the fallback is a sweep, not the other action")
        XCTAssertTrue(Activity<FocusActivityAttributes>.activities.isEmpty)
    }

    func testStopIntent_withNoEngine_sweepsOrphansInsteadOfCallingThrough() async throws {
        FocusSprintIntentActions.stop = nil
        FocusSprintIntentActions.pauseResume = { [recorder] in recorder.recordPauseResume() }

        _ = try await StopFocusSprintIntent().perform()

        XCTAssertEqual(recorder.pauseResumeCalls, 0, "the fallback is a sweep, not the other action")
        XCTAssertTrue(Activity<FocusActivityAttributes>.activities.isEmpty)
    }

    /// The sweep is also the mirror's launch cleanup, so it has to be safe to call with nothing
    /// running — which, in an unentitled test process, is the only state there is.
    func testEndAllActivities_withNothingRunning_isANoOp() async throws {
        await FocusActivityAttributes.endAllActivities()

        XCTAssertTrue(Activity<FocusActivityAttributes>.activities.isEmpty)
    }
}
