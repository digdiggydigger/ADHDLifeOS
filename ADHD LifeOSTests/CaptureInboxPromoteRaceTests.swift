//
//  CaptureInboxPromoteRaceTests.swift
//  ADHD LifeOSTests
//
//  Part 1 of the "Inbox promote — Create Task as a real primary action" block: a double-tap on
//  Create Task must create exactly one task. Before the in-flight guard, two concurrent
//  `promoteToTask` calls both found `pendingTaskIdsByCapture` empty and both passed the
//  `!processed` re-fetch guard, so both created a task.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxPromoteRaceTests: XCTestCase {
    func testPromoteToTask_twoConcurrentCallsForSameCapture_createExactlyOneTask() async {
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let fake = PromoteRaceCaptureClientFake(capture: capture)
        fake.hold(fetchCaptureOrdinal: 1) // park the first promote genuinely in-flight
        let sut = CaptureInboxService(client: fake)

        // First tap: sets the in-flight flag synchronously, then parks at `fetchCapture`.
        let first = Task {
            await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)
        }
        await fake.waitUntilFetchCaptureStarted(ordinal: 1)

        // Second tap while the first is genuinely in flight — must be a no-op.
        let second = Task {
            await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)
        }
        let secondResult = await second.value

        // Let the first promote complete.
        fake.releaseFetchCapture(ordinal: 1)
        let firstResult = await first.value

        XCTAssertTrue(firstResult, "The first (real) promote should succeed")
        XCTAssertFalse(secondResult, "A concurrent second tap must be a no-op, not a second create")
        XCTAssertEqual(fake.createTaskCallCount, 1, "A double-tap must create exactly one task")
        XCTAssertEqual(fake.fetchCaptureCallCount, 1, "The blocked second tap must not even re-fetch the capture")
        XCTAssertEqual(fake.markProcessedCallCount, 1)
    }

    func testPromoteToTask_afterInFlightCompletes_flagCleared_secondPromoteReachesClient() async {
        // Proves the in-flight flag clears on success so a *sequential* second promote is not blocked.
        let capture = Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
        let fake = PromoteRaceCaptureClientFake(capture: capture)
        let sut = CaptureInboxService(client: fake)

        _ = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)
        _ = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertEqual(fake.createTaskCallCount, 2, "Sequential promotes are not blocked once the flag clears")
    }
}
