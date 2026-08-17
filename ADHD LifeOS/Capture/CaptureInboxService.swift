//
//  CaptureInboxService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class CaptureInboxService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Capture])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading
    @Published var content = ""
    @Published var kind: CaptureKind = CaptureValidation.defaultKind
    @Published private(set) var isSubmittingCapture = false
    @Published var createCaptureErrorMessage: String?
    @Published private(set) var createdTask: TaskItem?
    @Published var warningMessage: String?
    @Published var errorMessage: String?
    @Published var triageErrorMessage: String?

    private let client: CaptureClientAdapting
    private let transcriber: VoiceTranscribing
    /// Tracks a capture whose task was already created but whose `markProcessed` call failed, so a
    /// retry tap on the same still-unprocessed row only retries the mark-processed step rather than
    /// creating a second task.
    private var pendingTaskIdsByCapture: [UUID: UUID] = [:]
    /// Captures whose promote is currently in flight. A second `promoteToTask` for the same capture
    /// while its first is still running is a no-op — without this, a double-tap creates two tasks:
    /// both calls find `pendingTaskIdsByCapture` empty and both pass the `!processed` re-fetch guard
    /// (neither has reached `markProcessed` yet). The guard-and-insert below runs synchronously
    /// before the first `await`, so on this `@MainActor` the second call always observes the flag.
    /// Distinct from `pendingTaskIdsByCapture`, which guards a *sequential* retry after a partial
    /// failure; this guards *concurrency*. Cleared on every exit path via `defer`.
    private var capturesBeingPromoted: Set<UUID> = []

    init(client: CaptureClientAdapting, transcriber: VoiceTranscribing = SFSpeechVoiceTranscriber()) {
        self.client = client
        self.transcriber = transcriber
    }

    var captures: [Capture] {
        if case .loaded(let captures) = state {
            return captures
        }
        return []
    }

    var isContentValid: Bool {
        if case .success = CaptureValidation.normalizeCreateCaptureInput(content: content, kind: kind) {
            return true
        }
        return false
    }

    func load() async {
        state = .loading
        do {
            let captures = try await client.fetchUnprocessedCaptures()
            state = .loaded(captures)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Pull-to-refresh reload. Unlike `load()`, this never flips `state` to `.loading` first: the
    /// List (and the `.refreshable` task it owns) stays mounted throughout the fetch. Flipping to
    /// `.loading` mid-gesture would swap the List out for the loading view, tearing down and
    /// cancelling the in-flight refresh task. A failed refresh leaves the previously loaded
    /// captures on screen rather than surfacing an error — a transient refresh hiccup shouldn't
    /// blank a list the user can already see.
    func refresh() async {
        guard let captures = try? await client.fetchUnprocessedCaptures() else { return }
        state = .loaded(captures)
    }

    @discardableResult
    func createCapture() async -> Bool {
        createCaptureErrorMessage = nil

        let normalized: NormalizedCreateCaptureInput
        switch CaptureValidation.normalizeCreateCaptureInput(content: content, kind: kind) {
        case .success(let value):
            normalized = value
        case .failure(let error):
            createCaptureErrorMessage = error.errorDescription
            return false
        }

        isSubmittingCapture = true
        defer { isSubmittingCapture = false }

        do {
            _ = try await client.createCapture(normalized)
            content = ""
            kind = CaptureValidation.defaultKind
            return true
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }
    }

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
                content: content, kind: .photo, mediaKey: target.mediaKey,
                mediaContentType: Self.photoContentType, thumbnailKey: target.thumbnailKey
            ) else {
                createCaptureErrorMessage = CaptureValidationError.emptyContent.errorDescription
                return false
            }

            _ = try await client.createCapture(normalized)
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
                content: trimmedTranscription, kind: .voice, mediaKey: target.mediaKey,
                mediaContentType: Self.voiceContentType, thumbnailKey: target.thumbnailKey
            ) else {
                createCaptureErrorMessage = CaptureValidationError.emptyContent.errorDescription
                return false
            }

            _ = try await client.createCapture(normalized)
            content = ""
            kind = CaptureValidation.defaultKind
            return true
        } catch {
            createCaptureErrorMessage = Self.message(for: error)
            return false
        }
    }

    @discardableResult
    func promoteToTask(capture: Capture, lifeAreaId: UUID?, priority: TaskPriority, dueDate: Date?) async -> Bool {
        guard !capturesBeingPromoted.contains(capture.id) else { return false }
        capturesBeingPromoted.insert(capture.id)
        defer { capturesBeingPromoted.remove(capture.id) }

        errorMessage = nil
        warningMessage = nil

        let taskId: UUID
        if let pendingTaskId = pendingTaskIdsByCapture[capture.id] {
            taskId = pendingTaskId
        } else {
            guard let createdTaskId = await createTaskIfNotAlreadyProcessed(
                capture: capture, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate
            ) else {
                return false
            }
            taskId = createdTaskId
        }

        do {
            try await client.markProcessed(captureId: capture.id)
            pendingTaskIdsByCapture[capture.id] = nil
            state = .loaded(captures.filter { $0.id != capture.id })
            return true
        } catch {
            pendingTaskIdsByCapture[capture.id] = taskId
            warningMessage = "Task created, but couldn't mark the capture as processed."
            return false
        }
    }

    /// Assigns (or clears, via `lifeAreaId: nil`) a capture's Life Area. Updates the loaded list
    /// in place on success so the row reflects the change without a full reload.
    @discardableResult
    func updateLifeArea(capture: Capture, lifeAreaId: UUID?) async -> Bool {
        triageErrorMessage = nil
        do {
            let updated = try await client.updateCapture(
                id: capture.id, changes: CaptureUpdate(lifeAreaId: .some(lifeAreaId))
            )
            replaceCapture(updated)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Failures here are swallowed to an empty list rather than surfaced — a failed tag-search
    /// fetch shouldn't block the rest of the triage UI, same "non-blocking" spirit as
    /// `refresh()`.
    func fetchAllTags() async -> [Tag] {
        (try? await client.fetchAllTags()) ?? []
    }

    func fetchTags(for capture: Capture) async -> [Tag] {
        (try? await client.fetchTags(captureId: capture.id)) ?? []
    }

    @discardableResult
    func addExistingTag(capture: Capture, tagId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.addTag(captureId: capture.id, tagId: tagId)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Creates a new tag (server dedups by name) then attaches it to the capture. Returns the
    /// created/deduped tag on success so the caller can update its local tag list without a
    /// second fetch.
    @discardableResult
    func createAndAddTag(capture: Capture, name: String) async -> Tag? {
        triageErrorMessage = nil
        do {
            let tag = try await client.createTag(name: name)
            try await client.addTag(captureId: capture.id, tagId: tag.id)
            return tag
        } catch {
            triageErrorMessage = Self.message(for: error)
            return nil
        }
    }

    @discardableResult
    func removeTag(capture: Capture, tagId: UUID) async -> Bool {
        triageErrorMessage = nil
        do {
            try await client.removeTag(captureId: capture.id, tagId: tagId)
            return true
        } catch {
            triageErrorMessage = Self.message(for: error)
            return false
        }
    }

    private func replaceCapture(_ updated: Capture) {
        guard case .loaded(let captures) = state else { return }
        state = .loaded(captures.map { $0.id == updated.id ? updated : $0 })
    }

    private func createTaskIfNotAlreadyProcessed(
        capture: Capture, lifeAreaId: UUID?, priority: TaskPriority, dueDate: Date?
    ) async -> UUID? {
        do {
            let current = try await client.fetchCapture(id: capture.id)
            guard !current.processed else {
                errorMessage = CaptureServiceError.alreadyProcessed.errorDescription
                return nil
            }
        } catch {
            errorMessage = Self.message(for: error)
            return nil
        }

        let input = NormalizedPromoteToTaskInput(
            title: Self.taskTitle(for: capture), lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate
        )
        do {
            let task = try await client.createTask(input)
            createdTask = task
            return task.id
        } catch {
            errorMessage = Self.message(for: error)
            return nil
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    /// A photo capture may have no caption (`content` empty, per C.6a's photo-content-optional
    /// rule), so promoting it needs a non-empty fallback title — every other kind already has
    /// non-empty content by validation. A link capture prefers its server-unfurled preview title,
    /// falling back to the raw URL when the preview hasn't arrived yet (or unfurl failed).
    private static func taskTitle(for capture: Capture) -> String {
        if capture.kind == .photo {
            return capture.content.isEmpty ? "Photo capture" : capture.content
        }
        if capture.kind == .link, let previewTitle = capture.linkPreview?.title,
           !previewTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return previewTitle
        }
        return capture.content
    }

    private static let photoContentType = "image/jpeg"
    private static let voiceContentType = "audio/m4a"
}
