//
//  CaptureInboxService+Media.swift
//  ADHD LifeOS
//
//  The photo and voice capture creation flows, split out of `CaptureInboxService` on 2026-08-20 so
//  that type stays inside its body-length budget after Inbox block 2 added two triage exits. Moved
//  verbatim — `isSubmittingCapture` and `transcriber` became internal purely so this file can
//  reach them.
//

import Foundation

@MainActor
extension CaptureInboxService {
    /// Photo capture flow: mint an upload URL, PUT the (already-downscaled, JPEG-encoded) image
    /// bytes to S3, then create the capture referencing the returned keys. `content` doubles as the
    /// optional caption, same field the text-capture composer uses.
    @discardableResult
    func createPhotoCapture(imageData: Data) async -> Bool {
        createCaptureErrorMessage = nil
        isSubmittingCapture = true
        defer { isSubmittingCapture = false }

        do {
            let target = try await client.requestUploadURL(kind: .photo, contentType: Self.photoContentType)
            try await client.uploadMedia(to: target.uploadURL, data: imageData, contentType: Self.photoContentType)

            guard case .success(let normalized) = CaptureValidation.normalizeCreateCaptureInput(
                content: content, kind: .photo, lifeAreaId: newCaptureLifeAreaId,
                mediaKey: target.mediaKey,
                mediaContentType: Self.photoContentType, thumbnailKey: target.thumbnailKey
            ) else {
                createCaptureErrorMessage = CaptureValidationError.emptyContent.errorDescription
                return false
            }

            let created = try await client.createCapture(normalized)
            await attachDraftTags(to: created)
            content = ""
            kind = CaptureValidation.defaultKind
            return true
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Voice capture flow: transcribe the recorded `.m4a` on-device first (no upload attempted if
    /// transcription fails/is denied/comes back empty), then mint an upload URL, PUT the audio bytes
    /// to S3, then create the capture with the transcription as `content`. There is no server-side
    /// transcription and no thumbnail concept for audio.
    @discardableResult
    func createVoiceCapture(audioFileURL: URL) async -> Bool {
        createCaptureErrorMessage = nil
        isSubmittingCapture = true
        defer { isSubmittingCapture = false }

        let transcription: String
        do {
            transcription = try await transcriber.transcribe(audioURL: audioFileURL)
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }

        let trimmedTranscription = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscription.isEmpty else {
            createCaptureErrorMessage = VoiceTranscriptionError.emptyTranscription.errorDescription
            return false
        }

        do {
            let audioData = try Data(contentsOf: audioFileURL)
            let target = try await client.requestUploadURL(kind: .voice, contentType: Self.voiceContentType)
            try await client.uploadMedia(to: target.uploadURL, data: audioData, contentType: Self.voiceContentType)

            guard case .success(let normalized) = CaptureValidation.normalizeCreateCaptureInput(
                content: trimmedTranscription, kind: .voice, lifeAreaId: newCaptureLifeAreaId,
                mediaKey: target.mediaKey,
                mediaContentType: Self.voiceContentType, thumbnailKey: target.thumbnailKey
            ) else {
                createCaptureErrorMessage = CaptureValidationError.emptyContent.errorDescription
                return false
            }

            let created = try await client.createCapture(normalized)
            await attachDraftTags(to: created)
            content = ""
            kind = CaptureValidation.defaultKind
            return true
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }
    }
}
