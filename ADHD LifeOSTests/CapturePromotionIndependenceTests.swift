//
//  CapturePromotionIndependenceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// **A capture is a historical record, not a draft of the task it became.**
///
/// E's rule, 2026-08-28: "if a capture is made and then promoted into a task, the capture and the
/// quality that it's given when it is originally saved must be maintained by keeping it separate
/// from whatever happens to the task promotion."
///
/// This already held — nothing links the two objects in either direction, and promotion's only
/// write to the capture is its exit flag — but "already true" is exactly the kind of property that
/// dies quietly to a later convenience. A `captureId` on `TaskDetail`, a cascade on task delete,
/// or a well-meaning "keep the capture's area in sync with its task" would each break it without
/// failing anything else. These fail instead.
@MainActor
final class CapturePromotionIndependenceTests: XCTestCase {
    private let capturedArea = UUID()
    private let taskArea = UUID()

    private func capture(_ content: String, lifeAreaId: UUID?) -> Capture {
        Capture(
            id: UUID(), content: content, kind: .note, processed: false,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lifeAreaId: lifeAreaId, notes: "why this mattered at the time"
        )
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        // Promotion re-reads the capture from the server before building the task, deliberately:
        // a note saved seconds earlier on the detail screen is what the task must start with, and
        // the list row in hand may be stale. So the fake has to answer that read with the same
        // document, or the task is built from a stranger.
        if let first = loaded.first { client.fetchCaptureResult = .success(first) }
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())
        await service.load()
        return SUT(service: service, client: client)
    }

    /// The sharp case, and the one E named. A capture filed under one area, promoted into a task
    /// filed under a DIFFERENT one, must keep its own. The new task's filing is a decision about
    /// the work; the capture's is a record of where the thought came from, and re-filing it would
    /// rewrite that history to match a choice made later.
    func testPromotion_filingTheTaskElsewhere_neverRefilesTheCapture() async {
        let thought = capture("Ask about the boiler service", lifeAreaId: capturedArea)
        let env = await makeSUT(loaded: [thought])

        let promoted = await env.service.promoteToTask(
            capture: thought, lifeAreaId: taskArea, priority: .p2, dueDate: nil
        )

        XCTAssertTrue(promoted)
        XCTAssertEqual(env.client.lastCreateTaskInput?.lifeAreaId, taskArea, "the TASK is filed as asked")
        XCTAssertNil(
            env.client.lastUpdateCaptureId,
            "promotion must not write a single field onto the capture — its area is where the "
                + "thought came from, not where the work ended up"
        )
    }

    /// Promotion's ONLY write to the capture is the exit flag. Anything else — a title rewritten
    /// to match the task's, an area synced, notes copied back — would make the record follow the
    /// work instead of standing beside it.
    func testPromotion_touchesNothingOnTheCaptureButItsExitFlag() async {
        let thought = capture("Book the boiler service", lifeAreaId: capturedArea)
        let env = await makeSUT(loaded: [thought])

        _ = await env.service.promoteToTask(
            capture: thought, lifeAreaId: taskArea, priority: .p1, dueDate: Date()
        )

        XCTAssertEqual(env.client.lastMarkProcessedCaptureId, thought.id)
        XCTAssertNil(env.client.lastUpdateCaptureId)
        XCTAssertNil(env.client.lastDeleteCaptureId, "a promoted capture is kept, never consumed")
    }

    /// The task is a NEW object. Sharing the capture's id would fuse the two records, and every
    /// later edit or delete of the task would land on the capture as well.
    func testPromotion_mintsATaskWithItsOwnIdentity() async {
        let thought = capture("Ring the dentist", lifeAreaId: capturedArea)
        let env = await makeSUT(loaded: [thought])

        _ = await env.service.promoteToTask(
            capture: thought, lifeAreaId: nil, priority: .p3, dueDate: nil
        )

        let created = try? XCTUnwrap(env.service.createdTask)
        XCTAssertNotNil(created)
        XCTAssertNotEqual(created?.id, thought.id, "the task and the capture are two records")
    }

    /// The task starts from a COPY of what the capture said — read fresh from the server at the
    /// moment of promotion, then frozen. `NormalizedPromoteToTaskInput` is plain values: no
    /// capture reference travels with it, so there is nothing for a later task edit to follow
    /// back, and nothing that keeps the two in step afterwards.
    func testPromotion_carriesValuesNotAReference() async {
        let thought = capture("Ring the dentist", lifeAreaId: capturedArea)
        let env = await makeSUT(loaded: [thought])

        _ = await env.service.promoteToTask(
            capture: thought, lifeAreaId: nil, priority: .p3, dueDate: nil
        )

        XCTAssertEqual(env.client.lastCreateTaskInput?.title, "Ring the dentist")
        XCTAssertEqual(env.client.lastCreateTaskInput?.notes, "why this mattered at the time")
    }

    /// Structural, and the cheapest guard of the lot: a task carries no way of naming the capture
    /// it came from. Adding one is the single change most likely to start a cascade, so it fails
    /// here first — where the reason is written down.
    func testTaskPayloads_holdNoCaptureReference() throws {
        let fields = FirestoreFieldPayloads.taskUpdate(TaskUpdatePayload(title: "Renamed later"))

        XCTAssertNil(fields["capture_id"])
        XCTAssertNil(fields["captureId"])
        XCTAssertEqual(fields.keys.sorted(), ["title"], "a task rename writes a title and nothing else")
    }
}
