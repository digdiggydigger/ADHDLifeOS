//
//  JournalService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class JournalService: ObservableObject {
    enum ListState: Equatable {
        case loading
        case loaded([Log])
        case failed(String)
    }

    @Published private(set) var state: ListState = .loading
    @Published var selectedLifeAreaId: UUID? {
        didSet {
            guard hasLoadedOnce else { return }
            recomputeFeed()
        }
    }
    @Published var composerBody = ""
    @Published var composerType: LogType = .log
    @Published var composerLifeAreaId: UUID?
    /// Journal-only, and seeded to the web composer's own starting selection so a one-tap save
    /// still records something honest. `composerType` gates whether they are sent at all
    /// (`LogValidation` drops them for a quick log), so switching back to Log never smuggles a
    /// mood reading onto a note.
    @Published var composerEnergyLevel: EnergyLevel = .medium
    @Published var composerMoodEmoji: String = JournalMood.defaultEmoji
    @Published private(set) var isCreating = false
    @Published var createErrorMessage: String?
    /// The two side streams the timeline interleaves beside the logs (E's 2026-08-25 note).
    /// Garnish, never load-bearing: a failed fetch leaves them empty rather than failing the
    /// journal — the same non-blocking posture as the view's closed-task fetch.
    @Published private(set) var focusSessions: [CompletedFocusSession] = []
    @Published private(set) var captures: [Capture] = []
    /// The composer's tag selection (E's 2026-08-25 note) — sent with the create, because logs
    /// are append-only and can never be tagged after the fact.
    @Published var composerTagIds: [UUID] = []
    /// The shared tag registry, for the composer chips and the timeline rows' resolution.
    /// Non-blocking like the other side streams.
    @Published private(set) var availableTags: [Tag] = []

    private let client: JournalClientAdapting
    private(set) var lifeAreas: [LifeArea] = []
    private var logs: [Log] = []
    private var hasLoadedOnce = false

    init(client: JournalClientAdapting) {
        self.client = client
    }

    var isComposerBodyValid: Bool {
        if case .success = LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId,
            energyLevel: composerEnergyLevel, moodEmoji: composerMoodEmoji
        ) {
            return true
        }
        return false
    }

    func load() async {
        state = .loading
        do {
            async let lifeAreasResult = client.fetchLifeAreas()
            async let logsResult = client.fetchLogs()
            async let sprintsResult = client.fetchFocusSessions()
            async let capturesResult = client.fetchCaptures()
            async let tagsResult = client.fetchAllTags()
            lifeAreas = try await lifeAreasResult
            logs = try await logsResult
            focusSessions = (try? await sprintsResult) ?? []
            captures = (try? await capturesResult) ?? []
            availableTags = (try? await tagsResult) ?? []
            hasLoadedOnce = true
            recomputeFeed()
        } catch {
            hasLoadedOnce = false
            state = .failed(Self.message(for: error))
        }
    }

    @discardableResult
    func createLog() async -> Bool {
        createErrorMessage = nil

        let normalized: NormalizedCreateLogInput
        switch LogValidation.normalizeCreateLogInput(
            body: composerBody, type: composerType, lifeAreaId: composerLifeAreaId,
            energyLevel: composerEnergyLevel, moodEmoji: composerMoodEmoji,
            tagIds: composerTagIds
        ) {
        case .failure(let error):
            createErrorMessage = error.errorDescription
            return false
        case .success(let value):
            normalized = value
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await client.createLog(normalized)
            logs.append(created)
            recomputeFeed()
            composerBody = ""
            composerType = .log
            composerLifeAreaId = nil
            composerEnergyLevel = .medium
            composerMoodEmoji = JournalMood.defaultEmoji
            composerTagIds = []
            return true
        } catch {
            createErrorMessage = Self.message(for: error)
            return false
        }
    }

    /// Creates a tag from the composer (server dedups by name), selects it for the entry being
    /// written, and adds it to the visible list — the same gesture the capture composer has.
    @discardableResult
    func createTagForComposer(name: String) async -> Tag? {
        createErrorMessage = nil
        do {
            let tag = try await client.createTag(name: name)
            if !composerTagIds.contains(tag.id) {
                composerTagIds.append(tag.id)
            }
            if !availableTags.contains(tag) {
                availableTags.append(tag)
            }
            return tag
        } catch {
            createErrorMessage = Self.message(for: error)
            return nil
        }
    }

    private func recomputeFeed() {
        let filtered = LogSorting.filterByLifeArea(logs, lifeAreaId: selectedLifeAreaId)
        state = .loaded(LogSorting.sortByEntryDateDescending(filtered))
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
