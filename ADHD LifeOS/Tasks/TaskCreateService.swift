//
//  TaskCreateService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class TaskCreateService: ObservableObject {
    enum TagsLoadState: Equatable {
        case idle
        case loading
        case loaded([Tag])
        case failed(String)
    }

    @Published var title = ""
    @Published var notes = ""
    @Published var lifeAreaId: UUID?
    @Published var dueDate: Date?
    @Published private(set) var tagsState: TagsLoadState = .idle
    @Published private(set) var selectedTagIds: Set<UUID> = []
    @Published var newTagName = ""
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    @Published private(set) var createdTask: TaskItem?
    @Published var nudgeSelection: NudgeCountdownSelection = .none
    @Published var dueMomentNotificationEnabled = false

    private let client: TaskCreateClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting

    init(client: TaskCreateClientAdapting, schedulingClient: TaskCountdownNudgeSchedulingAdapting) {
        self.client = client
        self.schedulingClient = schedulingClient
    }

    var availableTags: [Tag] {
        if case .loaded(let tags) = tagsState {
            return tags
        }
        return []
    }

    var isTitleValid: Bool {
        if case .success = TaskCreateValidation.normalizeCreateTaskInput(
            title: title, notes: nil, lifeAreaId: nil, dueDate: nil
        ) {
            return true
        }
        return false
    }

    func loadTags() async {
        tagsState = .loading
        do {
            let tags = try await client.fetchTags()
            tagsState = .loaded(tags)
        } catch {
            tagsState = .failed(Self.message(for: error))
        }
    }

    func toggleTagSelection(_ tag: Tag) {
        if selectedTagIds.contains(tag.id) {
            selectedTagIds.remove(tag.id)
        } else {
            selectedTagIds.insert(tag.id)
        }
    }

    func addNewTag() async {
        guard case .success(let name) = TaskCreateValidation.normalizeCreateTagInput(name: newTagName) else {
            return
        }
        newTagName = ""

        if let existing = TagDedup.matchExisting(tags: availableTags, name: name) {
            selectedTagIds.insert(existing.id)
            return
        }

        do {
            let created = try await client.createTag(name: name)
            tagsState = .loaded(availableTags + [created])
            selectedTagIds.insert(created.id)
        } catch {
            warningMessage = "Couldn't create tag \"\(name)\"."
        }
    }

    @discardableResult
    func createTask() async -> Bool {
        errorMessage = nil
        warningMessage = nil

        guard case .success(let normalized) = TaskCreateValidation.normalizeCreateTaskInput(
            title: title, notes: notes, lifeAreaId: lifeAreaId, dueDate: dueDate
        ) else {
            errorMessage = TaskCreateValidationError.emptyTitle.errorDescription
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let task: TaskItem
        do {
            task = try await client.createTask(normalized)
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }

        if !selectedTagIds.isEmpty {
            do {
                try await client.attachTags(taskId: task.id, tagIds: Array(selectedTagIds))
            } catch {
                warningMessage = "Task created, but couldn't attach one or more tags."
            }
        }

        await scheduleNudgesIfNeeded(for: task, dueDate: normalized.dueDate)
        await scheduleDueMomentNotificationIfNeeded(for: task, dueDate: normalized.dueDate)

        createdTask = task
        return true
    }

    private func scheduleNudgesIfNeeded(for task: TaskItem, dueDate: Date?) async {
        guard let dueDate else { return }
        let resolved = TaskCountdownNudgeScheduling.resolveFireDates(
            selection: nudgeSelection, now: Date(), dueDate: dueDate
        )
        guard !resolved.isEmpty else { return }

        guard await schedulingClient.requestAuthorizationIfNeeded() else {
            let denialNote = "Task created, but notifications permission was denied — nudges were not scheduled."
            warningMessage = warningMessage.map { "\($0) \(denialNote)" } ?? denialNote
            return
        }
        await schedulingClient.scheduleNudges(taskId: task.id, taskTitle: task.title, fireDates: resolved)
    }

    private func scheduleDueMomentNotificationIfNeeded(for task: TaskItem, dueDate: Date?) async {
        guard dueMomentNotificationEnabled, let dueDate else { return }

        guard await schedulingClient.requestAuthorizationIfNeeded() else {
            let denialNote =
                "Task created, but notifications permission was denied — due-moment notification was not scheduled."
            warningMessage = warningMessage.map { "\($0) \(denialNote)" } ?? denialNote
            return
        }
        await schedulingClient.scheduleDueMomentNotification(taskId: task.id, taskTitle: task.title, dueDate: dueDate)
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
