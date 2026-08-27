//
//  TaskDetailService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class TaskDetailService: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded(TaskDetail)
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var tags: [Tag] = []
    /// Every tag the user has, for the composer-parity chip row (E's follow-up): the detail
    /// screen shows them all, with the attached ones highlighted, exactly like the create sheet.
    @Published private(set) var allTags: [Tag] = []
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    /// The named places, for the at-place picker and chip (block 4a). Garnish, never
    /// load-bearing — the same non-blocking posture as the journal's side streams.
    @Published private(set) var places: [Place] = []

    /// The Settings-chosen sprint length a task with no stored config opens at, resolved ONCE at
    /// construction (E's 2026-08-28 fix). The planner seeds from it and the save diff compares
    /// against it, so both must read the same value — re-reading the store per use would let a
    /// mid-screen Settings change split them and make an untouched screen look edited.
    let defaultSprintSeconds: Int

    private let taskId: UUID
    private let client: TaskDetailClientAdapting
    private let placesClient: PlacesClientAdapting
    private var task: TaskDetail?

    init(
        taskId: UUID,
        client: TaskDetailClientAdapting,
        placesClient: PlacesClientAdapting? = nil,
        preferencesStore: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) {
        self.taskId = taskId
        self.client = client
        self.placesClient = placesClient ?? FirebasePlacesClientAdapter()
        defaultSprintSeconds = FocusSprintConfiguration.clampDuration(
            preferencesStore.read().defaultSprintMinutes * 60
        )
    }

    func load() async {
        state = .loading
        do {
            async let taskResult = client.fetchTask(id: taskId)
            async let tagsResult = client.fetchTagsForTask(taskId: taskId)
            async let allTagsResult = client.fetchAllTags()
            let fetchedTask = try await taskResult
            let fetchedTags = try await tagsResult
            allTags = try await allTagsResult
            task = fetchedTask
            tags = fetchedTags
            state = .loaded(fetchedTask)
        } catch {
            state = .failed(Self.message(for: error))
        }
        // After the task settles, deliberately: a places failure must never take the screen down.
        places = (try? await placesClient.fetchPlaces()) ?? []
    }

    @discardableResult
    func save(edited: TaskEditedFields) async -> Bool {
        errorMessage = nil
        guard let original = task else { return false }

        switch TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: edited, defaultSprintSeconds: defaultSprintSeconds
        ) {
        case .failure(let error):
            errorMessage = error.errorDescription
            return false
        case .success(let payload):
            guard !payload.isEmpty else { return true }

            isSaving = true
            defer { isSaving = false }
            do {
                let updated = try await client.updateTask(id: taskId, payload: payload)
                task = updated
                state = .loaded(updated)
                return true
            } catch {
                errorMessage = Self.message(for: error)
                return false
            }
        }
    }

    /// One-way close (F-V3-Tasks-rebuild, E's addendum): a done task never reopens, so this is a
    /// no-op unless the task is open.
    func close() async {
        guard let original = task, original.status == .open else { return }
        do {
            let updated = try await client.updateStatus(id: taskId, status: .done)
            task = updated
            state = .loaded(updated)
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// Hard delete — the detail screen owns deletion since F-V3-Tasks-rebuild. Returns whether it
    /// landed, so the view only dismisses a screen whose task is actually gone.
    func delete() async -> Bool {
        do {
            try await client.deleteTask(id: taskId)
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Composer-parity chip tap: attached → detach, not attached → attach. Applies immediately,
    /// same precedent as every other tag edit on this screen.
    func toggleTag(_ tag: Tag) async {
        if tags.contains(where: { $0.id == tag.id }) {
            await removeTag(tag)
        } else {
            await attach(tag)
        }
    }

    func addTag(name: String) async {
        guard case .success(let normalized) = TaskCreateValidation.normalizeCreateTagInput(name: name) else {
            return
        }

        if let existing = TagDedup.matchExisting(tags: allTags, name: normalized) {
            await attach(existing)
            return
        }

        do {
            let created = try await client.createTag(name: normalized)
            allTags.append(created)
            await attach(created)
        } catch {
            warningMessage = "Couldn't create tag \"\(normalized)\"."
        }
    }

    func removeTag(_ tag: Tag) async {
        do {
            try await client.removeTagFromTask(taskId: taskId, tagId: tag.id)
            tags.removeAll { $0.id == tag.id }
        } catch {
            warningMessage = "Couldn't remove tag \"\(tag.name)\"."
        }
    }

    private func attach(_ tag: Tag) async {
        guard !tags.contains(where: { $0.id == tag.id }) else { return }
        do {
            try await client.addTagToTask(taskId: taskId, tagId: tag.id)
            tags.append(tag)
        } catch {
            warningMessage = "Couldn't attach tag \"\(tag.name)\"."
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
