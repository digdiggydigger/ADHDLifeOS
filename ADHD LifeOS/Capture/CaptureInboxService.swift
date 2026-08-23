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

    /// Which slice of the captures collection is on screen. Grew out of the web's
    /// `activeTabFilter`; since the Captures tab (2026-08-23) the slices are split across two
    /// screens — the Inbox offers only `.unprocessed`, the Captures tab `.seen` + `.promoted` —
    /// so which filters a given screen offers is an init parameter, not this enum's business.
    enum Filter: String, CaseIterable, Identifiable, Equatable, Sendable {
        case unprocessed
        case seen
        case promoted

        var id: String { rawValue }

        var title: String {
            switch self {
            case .unprocessed: return "To triage"
            case .seen: return "Seen"
            case .promoted: return "Promoted"
            }
        }
    }

    @Published private(set) var state: ListState = .loading
    @Published private(set) var filter: Filter = .unprocessed
    @Published var content = ""
    @Published var kind: CaptureKind = CaptureValidation.defaultKind
    /// `private(set)` relaxed to internal so `CaptureInboxService+Media` can drive it — the
    /// media capture flows moved there to keep this type inside its length budget.
    @Published var isSubmittingCapture = false
    @Published var createCaptureErrorMessage: String?
    @Published private(set) var createdTask: TaskItem?
    @Published var warningMessage: String?
    @Published var errorMessage: String?
    @Published var triageErrorMessage: String?

    let client: CaptureClientAdapting
    /// Used only by `logToJournal` — the triage exit that writes a journal entry instead of a task.
    /// Injected rather than folded into `CaptureClientAdapting` so the journal keeps one owner.
    let journalClient: JournalClientAdapting?
    let transcriber: VoiceTranscribing
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

    /// `transcriber` defaults via `nil` rather than `= SFSpeechVoiceTranscriber()`: a default
    /// argument is evaluated in the caller's context, which is synchronous nonisolated — calling
    /// the main-actor-isolated `SFSpeechVoiceTranscriber.init` there was a concurrency warning.
    /// Resolving the default inside this `@MainActor` init is isolation-correct.
    /// The slices this screen offers, in picker order. The default is the Inbox's pure to-triage
    /// queue; the Captures tab passes `[.seen, .promoted]`. Filters not in this list are never
    /// fetched — not even for the decoration counts.
    let availableFilters: [Filter]

    init(
        client: CaptureClientAdapting,
        journalClient: JournalClientAdapting? = nil,
        transcriber: VoiceTranscribing? = nil,
        availableFilters: [Filter] = [.unprocessed]
    ) {
        self.client = client
        self.journalClient = journalClient
        self.transcriber = transcriber ?? SFSpeechVoiceTranscriber()
        self.availableFilters = availableFilters
        self.filter = availableFilters.first ?? .unprocessed
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

    /// Per-tab counts for the filter picker, so both tabs carry a number the way the web original's
    /// do ("Unprocessed (3)"). A filter with no entry has simply never loaded — the tab renders
    /// without a count rather than claiming zero, which is a different and much worse statement.
    @Published private(set) var counts: [Filter: Int] = [:]

    func load() async {
        state = .loading
        do {
            let captures = try await fetchCurrentFilter()
            counts[filter] = captures.count
            state = .loaded(captures)
        } catch {
            state = .failed(Self.message(for: error))
        }
        await refreshInactiveCount()
    }

    /// Learns the count for every OTHER offered tab so the picker isn't half-labelled on a cold
    /// start. A single-filter screen (the Inbox) has no other tabs and fetches nothing here.
    ///
    /// Deliberately after the main load and deliberately failure-tolerant: this is decoration on
    /// tabs the user is not looking at, and it must never delay the list they are, nor turn a
    /// perfectly good load into an error. A failure just leaves that count unknown.
    private func refreshInactiveCount() async {
        for inactive in availableFilters where inactive != filter {
            guard let captures = try? await fetch(inactive) else { continue }
            counts[inactive] = captures.count
        }
    }

    /// Switches tabs and loads that slice. Re-selecting the tab already showing is a no-op — the
    /// user tapping where they already are shouldn't cost a fetch or blank the list mid-read. A
    /// filter this screen doesn't offer is refused outright.
    func select(filter newFilter: Filter) async {
        guard availableFilters.contains(newFilter), newFilter != filter else { return }
        filter = newFilter
        await load()
    }

    private func fetchCurrentFilter() async throws -> [Capture] {
        try await fetch(filter)
    }

    private func fetch(_ filter: Filter) async throws -> [Capture] {
        switch filter {
        case .unprocessed: return try await client.fetchUnprocessedCaptures()
        case .seen: return try await client.fetchSeenCaptures()
        case .promoted: return try await client.fetchProcessedCaptures()
        }
    }

    /// Pull-to-refresh reload. Unlike `load()`, this never flips `state` to `.loading` first: the
    /// List (and the `.refreshable` task it owns) stays mounted throughout the fetch. Flipping to
    /// `.loading` mid-gesture would swap the List out for the loading view, tearing down and
    /// cancelling the in-flight refresh task. A failed refresh leaves the previously loaded
    /// captures on screen rather than surfacing an error — a transient refresh hiccup shouldn't
    /// blank a list the user can already see.
    func refresh() async {
        guard let captures = try? await fetchCurrentFilter() else { return }
        counts[filter] = captures.count
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

    /// The detail screen's re-fetch (the `TaskDetailView` precedent: the push carries an id, the
    /// screen re-reads the server's document rather than trusting a possibly stale list row).
    /// Throws rather than publishing a message — the failure belongs to the detail screen's own
    /// local state, not to the list behind it.
    func fetchCaptureDetail(id: UUID) async throws -> Capture {
        try await client.fetchCapture(id: id)
    }

    /// Drops a retired capture from the loaded list without a refetch. Lives here rather than in
    /// `CaptureInboxService+Triage` because `state` has a `private(set)` setter — the only writers
    /// must be in this file.
    func removeCapture(id: UUID) {
        guard case .loaded(let captures) = state else { return }
        state = .loaded(captures.filter { $0.id != id })
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

    static func message(for error: Error) -> String {
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

    static let photoContentType = "image/jpeg"
    static let voiceContentType = "audio/m4a"
}
