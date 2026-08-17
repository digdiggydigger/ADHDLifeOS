//
//  CaptureInboxServiceVoiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxServiceVoiceTests: XCTestCase {

    func testCreateVoiceCapture_success_callsInOrderWithTranscriptionAsContentAndResetsFields() async throws {
        let fake = FakeCaptureClientAdapting()
        let transcriber = FakeVoiceTranscribing()
        transcriber.transcribeResult = .success("Buy milk from the store")
        let target = CaptureUploadTarget(
            uploadURL: URL(string: "https://example.com/put")!, mediaKey: "captures/u1/audio.m4a", thumbnailKey: nil
        )
        fake.requestUploadURLResult = .success(target)
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01, 0x02, 0x03]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertTrue(result)
        XCTAssertEqual(transcriber.transcribeCallCount, 1)
        XCTAssertEqual(transcriber.lastAudioURL, audioURL)
        XCTAssertEqual(fake.callLog, ["requestUploadURL", "uploadMedia", "createCapture"])
        XCTAssertEqual(fake.lastRequestUploadURLKind, .voice)
        XCTAssertEqual(fake.lastRequestUploadURLContentType, "audio/m4a")
        XCTAssertEqual(fake.lastUploadMediaData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(fake.lastUploadMediaContentType, "audio/m4a")
        XCTAssertEqual(fake.lastCreateCaptureInput?.kind, .voice)
        XCTAssertEqual(fake.lastCreateCaptureInput?.content, "Buy milk from the store")
        XCTAssertEqual(fake.lastCreateCaptureInput?.mediaKey, target.mediaKey)
        XCTAssertEqual(fake.lastCreateCaptureInput?.mediaContentType, "audio/m4a")
        XCTAssertNil(fake.lastCreateCaptureInput?.thumbnailKey)
        XCTAssertEqual(sut.content, "")
        XCTAssertEqual(sut.kind, .note)
        XCTAssertNil(sut.createCaptureErrorMessage)
    }

    func testCreateVoiceCapture_permissionDenied_surfacesErrorAndDoesNotUpload() async throws {
        let fake = FakeCaptureClientAdapting()
        let transcriber = FakeVoiceTranscribing()
        transcriber.transcribeResult = .failure(VoiceTranscriptionError.permissionDenied)
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, VoiceTranscriptionError.permissionDenied.errorDescription)
        XCTAssertEqual(fake.requestUploadURLCallCount, 0)
        XCTAssertEqual(fake.uploadMediaCallCount, 0)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreateVoiceCapture_emptyTranscription_surfacesErrorAndDoesNotUpload() async throws {
        let fake = FakeCaptureClientAdapting()
        let transcriber = FakeVoiceTranscribing()
        transcriber.transcribeResult = .success("   ")
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, VoiceTranscriptionError.emptyTranscription.errorDescription)
        XCTAssertEqual(fake.requestUploadURLCallCount, 0)
    }

    func testCreateVoiceCapture_requestUploadURLFailure_surfacesErrorAndDoesNotCreate() async throws {
        let fake = FakeCaptureClientAdapting()
        fake.requestUploadURLResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let transcriber = FakeVoiceTranscribing()
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
        XCTAssertEqual(fake.uploadMediaCallCount, 0)
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreateVoiceCapture_uploadMediaFailure_surfacesErrorAndDoesNotCreateCapture() async throws {
        let fake = FakeCaptureClientAdapting()
        fake.uploadMediaResult = .failure(CaptureServiceError.fetchFailed("Upload failed"))
        let transcriber = FakeVoiceTranscribing()
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Upload failed")
        XCTAssertEqual(fake.createCaptureCallCount, 0)
    }

    func testCreateVoiceCapture_createCaptureFailure_surfacesError() async throws {
        let fake = FakeCaptureClientAdapting()
        fake.createCaptureResult = .failure(CaptureServiceError.fetchFailed("Network error"))
        let transcriber = FakeVoiceTranscribing()
        let sut = CaptureInboxService(client: fake, transcriber: transcriber)
        let audioURL = try Self.makeTempAudioFile(data: Data([0x01]))
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let result = await sut.createVoiceCapture(audioFileURL: audioURL)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createCaptureErrorMessage, "Network error")
    }

    func testPromoteToTask_voiceCapture_usesTranscriptionAsTitle() async {
        let fake = FakeCaptureClientAdapting()
        let capture = Capture(
            id: UUID(), content: "Call the dentist tomorrow", kind: .voice, processed: false, createdAt: Date()
        )
        fake.fetchUnprocessedCapturesResult = .success([capture])
        fake.fetchCaptureResult = .success(capture)
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Call the dentist tomorrow", status: .open, priority: .p4, dueDate: nil
        )
        fake.createTaskResult = .success(task)
        let sut = CaptureInboxService(client: fake)
        await sut.load()

        let result = await sut.promoteToTask(capture: capture, lifeAreaId: nil, priority: .p4, dueDate: nil)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastCreateTaskInput?.title, "Call the dentist tomorrow")
    }

    private static func makeTempAudioFile(data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        try data.write(to: url)
        return url
    }
}
