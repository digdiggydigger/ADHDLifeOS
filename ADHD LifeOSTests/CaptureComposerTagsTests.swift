//
//  CaptureComposerTagsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Tags at the point of capture (E's review directive, 2026-08-25): the composer's selected
/// tags attach to the created capture through the EXISTING addTag seam, a failed attach warns
/// without failing the save (the capture exists; re-saving would duplicate it), and the
/// selection resets with the rest of the draft.
@MainActor
final class CaptureComposerTagsTests: XCTestCase {
    func testCreateCapture_attachesEverySelectedTagToTheCreatedCapture() async {
        let client = FakeCaptureClientAdapting()
        let service = CaptureInboxService(client: client)
        let first = UUID()
        let second = UUID()
        service.content = "Ask the GP about the referral letter"
        service.newCaptureTagIds = [first, second]

        let created = await service.createCapture()

        XCTAssertTrue(created)
        XCTAssertEqual(client.addTagCallCount, 2)
        let expectedCaptureId = (try? client.createCaptureResult.get())?.id
        XCTAssertEqual(client.lastAddTagCaptureId, expectedCaptureId)
        XCTAssertEqual(client.lastAddTagTagId, second)
        XCTAssertTrue(service.newCaptureTagIds.isEmpty)
        XCTAssertNil(service.warningMessage)
    }

    func testCreateCapture_tagAttachFailureWarnsWithoutFailingTheSave() async {
        let client = FakeCaptureClientAdapting()
        client.addTagResult = .failure(URLError(.notConnectedToInternet))
        let service = CaptureInboxService(client: client)
        service.content = "Loose thought"
        service.newCaptureTagIds = [UUID()]

        let created = await service.createCapture()

        XCTAssertTrue(created, "The capture exists — failing the save would invite a duplicate")
        XCTAssertNotNil(service.warningMessage)
    }

    func testCreateCapture_withoutTags_neverTouchesTheTagSeam() async {
        let client = FakeCaptureClientAdapting()
        let service = CaptureInboxService(client: client)
        service.content = "Loose thought"

        _ = await service.createCapture()

        XCTAssertEqual(client.addTagCallCount, 0)
    }

    func testCreateTagForDraft_createsAndSelects() async {
        let client = FakeCaptureClientAdapting()
        let expected = Tag(id: UUID(), name: "errand")
        client.createTagResult = .success(expected)
        let service = CaptureInboxService(client: client)

        let tag = await service.createTagForDraft(name: "errand")

        XCTAssertEqual(tag, expected)
        XCTAssertEqual(service.newCaptureTagIds, [expected.id])
    }
}

/// Voice transcripts on the full capture view (E's review directive): the headline stops
/// swallowing the transcript, which gets its own labelled block at reading size.
@MainActor
final class CaptureVoiceTranscriptTests: XCTestCase {
    private func voiceCapture(title: String? = nil, content: String) -> Capture {
        var capture = Capture(id: UUID(), content: content, kind: .voice, processed: false, createdAt: .now)
        capture.title = title
        return capture
    }

    func testHeadline_voiceWithoutATitleReadsVoiceNote_notTheTranscript() {
        let capture = voiceCapture(content: "Ask the GP about the referral letter from March")
        XCTAssertEqual(CaptureDetailPresentation.headline(for: capture), "Voice note")
    }

    func testHeadline_voiceWithATitleKeepsIt() {
        let capture = voiceCapture(title: "GP call", content: "Ask the GP about the referral letter")
        XCTAssertEqual(CaptureDetailPresentation.headline(for: capture), "GP call")
    }

    func testHeadline_otherKindsUnchanged() {
        var note = Capture(id: UUID(), content: "Buy stamps", kind: .note, processed: false, createdAt: .now)
        note.title = nil
        XCTAssertEqual(CaptureDetailPresentation.headline(for: note), "Buy stamps")
    }

    func testTranscript_onlyForVoice() {
        let voice = voiceCapture(content: "Ask the GP about the referral letter")
        XCTAssertEqual(
            CaptureDetailPresentation.transcript(for: voice),
            "Ask the GP about the referral letter"
        )
        let note = Capture(id: UUID(), content: "Buy stamps", kind: .note, processed: false, createdAt: .now)
        XCTAssertNil(CaptureDetailPresentation.transcript(for: note))
    }
}
