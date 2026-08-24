//
//  CaptureNotesServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The capture `notes` annotation: free text the user attaches to any capture from the detail
/// screen — the words that accompany a photo, voice memo or link whose main text slot is already
/// the caption, transcript or URL.
@MainActor
final class CaptureNotesServiceTests: XCTestCase {
    private func capture(_ content: String, notes: String? = nil) -> Capture {
        Capture(id: UUID(), content: content, kind: .link, processed: false, createdAt: Date(), notes: notes)
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())
        await service.load()
        return SUT(service: service, client: client)
    }

    // MARK: - Saving

    /// Returns the server's re-read document (read-after-write, like `updateLifeArea`) and swaps
    /// it into the loaded list, so the row behind the detail screen shows the note without a
    /// reload.
    func testSaveNotes_writesTrimmedNotesAndReplacesTheListCopy() async {
        let annotated = capture("https://example.com")
        let env = await makeSUT(loaded: [annotated])
        var serverCopy = annotated
        serverCopy.notes = "Read before Thursday"
        env.client.updateCaptureResult = .success(serverCopy)

        let updated = await env.service.saveNotes(capture: annotated, notes: "  Read before Thursday  ")

        XCTAssertEqual(updated, serverCopy)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges, CaptureUpdate(notes: .some("Read before Thursday")))
        XCTAssertEqual(env.service.captures.first?.notes, "Read before Thursday")
    }

    /// Erasing the text clears the field outright (`.some(nil)` → FieldValue.delete), never
    /// leaving an empty string on the document.
    func testSaveNotes_whitespaceOnly_clearsTheField() async {
        let annotated = capture("https://example.com", notes: "old note")
        let env = await makeSUT(loaded: [annotated])

        _ = await env.service.saveNotes(capture: annotated, notes: "   ")

        XCTAssertEqual(env.client.lastUpdateCaptureChanges, CaptureUpdate(notes: .some(nil)))
    }

    func testSaveNotes_failure_surfacesTheErrorAndReturnsNil() async {
        let annotated = capture("https://example.com")
        let env = await makeSUT(loaded: [annotated])
        env.client.updateCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let updated = await env.service.saveNotes(capture: annotated, notes: "Read this")

        XCTAssertNil(updated)
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
    }

    // MARK: - Promotion carries the note

    /// S2's effort chip travels into the created task's sprint config.
    func testPromoteToTask_carriesTheChosenEffort() async {
        let annotated = capture("https://example.com")
        let env = await makeSUT(loaded: [annotated])
        env.client.fetchCaptureResult = .success(annotated)

        _ = await env.service.promoteToTask(
            capture: annotated, lifeAreaId: nil, priority: .p3, dueDate: nil, focusDurationSeconds: 900
        )

        XCTAssertEqual(env.client.lastCreateTaskInput?.focusDurationSeconds, 900)
    }

    /// The note travels from the SERVER's copy of the capture (the same re-fetch that guards
    /// against promoting an already-processed capture), so a note edited moments ago is what the
    /// task starts with — not whatever a stale list row remembered.
    func testPromoteToTask_carriesTheServerCopysNotesIntoTheTask() async {
        let annotated = capture("https://example.com")
        let env = await makeSUT(loaded: [annotated])
        var serverCopy = annotated
        serverCopy.notes = "Ask about the referral"
        env.client.fetchCaptureResult = .success(serverCopy)

        let succeeded = await env.service.promoteToTask(
            capture: annotated, lifeAreaId: nil, priority: .p3, dueDate: nil
        )

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.client.lastCreateTaskInput?.notes, "Ask about the referral")
    }
}
