//
//  FocusNotificationPlanningTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Turns a running sprint into the local notifications it needs on the system's schedule.
///
/// This is the gap that made the sprint's nudges invisible: checkpoints only ever raised an in-app
/// banner and moved the Live Activity's count, so a locked phone — the exact ADHD case the nudges
/// exist for — got nothing at all. Notifications must be handed to the OS UP FRONT, because the app
/// is suspended when they are due and cannot post them itself.
final class FocusNotificationPlanningTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func session(
        duration: Int = 900,
        checkpoints: [Int] = [225, 450, 675],
        remaining: Int? = nil,
        paused: Bool = false
    ) -> FocusSession {
        var sut = FocusSession(
            taskId: UUID(), taskTitle: "Take a 10-minute walk", lifeAreaEmoji: "🫀",
            durationSeconds: duration, nudgeCheckpoints: checkpoints
        )
        if let remaining {
            _ = sut.advance(toRemaining: remaining)
        }
        sut.isPaused = paused
        return sut
    }

    private func plan(_ session: FocusSession, deadline: Date?) -> [ScheduledFocusNotification] {
        FocusNotificationPlanning.plan(session: session, deadline: deadline, now: now)
    }

    // MARK: - Checkpoints

    func testPlan_schedulesEveryCheckpointStillAhead() {
        let notifications = plan(session(), deadline: now.addingTimeInterval(900))

        let checkpoints = notifications.filter { $0.kind != .sprintComplete }
        XCTAssertEqual(checkpoints.count, 3)
        XCTAssertEqual(checkpoints.map(\.fireDate), [
            now.addingTimeInterval(225), now.addingTimeInterval(450), now.addingTimeInterval(675)
        ])
    }

    func testPlan_skipsCheckpointsAlreadyCrossed() {
        // 300s elapsed: the 225s mark has fired and must not be scheduled again.
        let notifications = plan(session(remaining: 600), deadline: now.addingTimeInterval(600))

        let checkpoints = notifications.filter { $0.kind != .sprintComplete }
        XCTAssertEqual(checkpoints.map(\.kind), [.checkpoint(index: 1), .checkpoint(index: 2)])
        XCTAssertEqual(checkpoints.map(\.fireDate), [
            now.addingTimeInterval(150), now.addingTimeInterval(375)
        ], "fire dates are relative to the playhead, not to the sprint's start")
    }

    func testPlan_carriesTheCoachingPromptAsTheBody() {
        let notifications = plan(session(), deadline: now.addingTimeInterval(900))

        XCTAssertEqual(
            notifications.first?.body,
            FocusSession.checkpointPrompt(index: 0, total: 3),
            "the same ADHD coaching copy the in-app banner shows"
        )
        XCTAssertTrue(notifications.first?.title.contains("Take a 10-minute walk") == true)
    }

    func testPlan_titleCarriesTheCheckpointPosition() {
        let notifications = plan(session(), deadline: now.addingTimeInterval(900))

        XCTAssertTrue(
            notifications.first?.title.contains("1 of 3") == true,
            "a glanceable position, so a Lock Screen stack reads as progress: \(notifications.first?.title ?? "")"
        )
    }

    // MARK: - Completion

    func testPlan_schedulesASprintCompleteNotificationAtTheDeadline() {
        let notifications = plan(session(), deadline: now.addingTimeInterval(900))

        let completion = notifications.last
        XCTAssertEqual(completion?.kind, .sprintComplete)
        XCTAssertEqual(completion?.fireDate, now.addingTimeInterval(900))
    }

    /// The completion notification is not just an acknowledgement — it is the deliberate route out
    /// of a Live Activity iOS won't let the app dismiss on time while suspended. The copy has to say
    /// so, or the tap that clears the Lock Screen is a secret.
    func testPlan_theCompletionCopy_tellsTheUserThatTappingClearsTheLockScreen() {
        let completion = plan(session(), deadline: now.addingTimeInterval(900)).last

        XCTAssertEqual(
            completion?.body.contains("Tap"), true,
            "the body must name the action: \(completion?.body ?? "")"
        )
        XCTAssertEqual(
            completion?.body.contains("Lock Screen"), true,
            "and what the action clears: \(completion?.body ?? "")"
        )
    }

    func testPlan_sprintWithNoCheckpoints_stillAnnouncesCompletion() {
        let notifications = plan(session(checkpoints: []), deadline: now.addingTimeInterval(900))

        XCTAssertEqual(notifications.map(\.kind), [.sprintComplete])
    }

    // MARK: - States that schedule nothing

    func testPlan_whilePaused_isEmpty() {
        // A paused sprint has no deadline, so nothing can be dated — and a nudge that fired during
        // a pause would be actively wrong.
        XCTAssertTrue(plan(session(paused: true), deadline: nil).isEmpty)
    }

    func testPlan_withNoDeadline_isEmpty() {
        XCTAssertTrue(plan(session(), deadline: nil).isEmpty)
    }

    func testPlan_forAFinishedSprint_isEmpty() {
        XCTAssertTrue(plan(session(remaining: 0), deadline: now).isEmpty)
    }

    func testPlan_dropsCheckpointsWhoseMomentHasPassedButNeverFired() {
        // The app was suspended past a checkpoint: it is behind the playhead now, so scheduling it
        // would fire it immediately and late. The engine's own resync reports it instead.
        let stale = FocusSession(
            taskId: nil, taskTitle: "x", lifeAreaEmoji: "🎯",
            durationSeconds: 900, remainingSeconds: 600, nudgeCheckpoints: [225, 450, 675]
        )

        let notifications = plan(stale, deadline: now.addingTimeInterval(600))

        XCTAssertFalse(
            notifications.contains { $0.kind == .checkpoint(index: 0) },
            "225s is behind the 300s playhead"
        )
    }

    // MARK: - Identifiers

    func testIdentifiers_areStableAndDistinctPerKind() {
        let notifications = plan(session(), deadline: now.addingTimeInterval(900))

        let identifiers = notifications.map(\.identifier)
        XCTAssertEqual(Set(identifiers).count, identifiers.count, "no two requests may collide")
        XCTAssertTrue(identifiers.allSatisfy { $0.hasPrefix("focusSprint.") })
    }
}
