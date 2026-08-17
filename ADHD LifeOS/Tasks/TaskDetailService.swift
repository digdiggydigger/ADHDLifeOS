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
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var warningMessage: String?
    @Published private(set) var hasScheduledNudges = false
    @Published private(set) var hasDueMomentNotification = false

    private let taskId: UUID
    private let client: TaskDetailClientAdapting
    private let schedulingClient: TaskCountdownNudgeSchedulingAdapting
    private var task: TaskDetail?
    private var allTags: [Tag] = []

    init(taskId: UUID, client: TaskDetailClientAdapting, schedulingClient: TaskCountdownNudgeSchedulingAdapting) {
        self.taskId = taskId
        self.client = client
        self.schedulingClient = schedulingClient
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
            hasScheduledNudges = await schedulingClient.hasScheduledNudges(taskId: taskId)
            hasDueMomentNotification = await schedulingClient.hasDueMomentNotificationScheduled(taskId: taskId)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    @discardableResult
    func save(edited: TaskEditedFields) async -> Bool {
        errorMessage = nil
        guard let original = task else { return false }

        switch TaskUpdateValidation.normalizeUpdateTaskInput(original: original, edited: edited) {
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
                if payload.dueDate != nil {
                    if hasScheduledNudges {
                        await cancelNudges()
                    }
                    if hasDueMomentNotification {
                        await cancelDueMomentNotification()
                    }
                }
                return true
            } catch {
                errorMessage = Self.message(for: error)
                return false
            }
        }
    }

    func toggleStatus() async {
        guard let original = task else { return }
        let newStatus: TaskStatus = original.status == .open ? .done : .open
        do {
            let updated = try await client.updateStatus(id: taskId, status: newStatus)
            task = updated
            state = .loaded(updated)
            if newStatus == .done {
                if hasScheduledNudges {
                    await cancelNudges()
                }
                if hasDueMomentNotification {
                    await cancelDueMomentNotification()
                }
            }
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// Applies a new countdown-nudge selection immediately (same immediate-apply precedent as the
    /// status toggle and tag add/remove) — cancels any existing nudges for this task first, then
    /// schedules the new ones against `dueDate`, the view's live/currently-staged due date (not
    /// `task.dueDate`, which may be stale relative to an unsaved edit — see the FIX block this
    /// resolves).
    func updateNudgeSelection(_ selection: NudgeCountdownSelection, dueDate: Date) async {
        guard selection != .none else {
            await cancelNudges()
            return
        }

        let resolved = TaskCountdownNudgeScheduling.resolveFireDates(
            selection: selection, now: Date(), dueDate: dueDate
        )
        guard !resolved.isEmpty else {
            await cancelNudges()
            return
        }

        guard await schedulingClient.requestAuthorizationIfNeeded() else {
            warningMessage = "Notifications permission denied — nudges were not scheduled."
            hasScheduledNudges = false
            return
        }

        await schedulingClient.scheduleNudges(taskId: taskId, taskTitle: task?.title ?? "", fireDates: resolved)
        hasScheduledNudges = true
    }

    func disableNudges() async {
        await cancelNudges()
    }

    private func cancelNudges() async {
        await schedulingClient.cancelNudges(taskId: taskId)
        hasScheduledNudges = false
    }

    /// Applies the due-moment notification toggle immediately (no Save required — same
    /// immediate-apply precedent as the countdown-nudge selection above). Independent of
    /// countdown nudges — toggling this on/off never touches `hasScheduledNudges` or vice versa.
    func updateDueMomentNotification(enabled: Bool, dueDate: Date) async {
        guard enabled else {
            await cancelDueMomentNotification()
            return
        }

        guard await schedulingClient.requestAuthorizationIfNeeded() else {
            warningMessage = "Notifications permission denied — due-moment notification was not scheduled."
            hasDueMomentNotification = false
            return
        }

        await schedulingClient.scheduleDueMomentNotification(
            taskId: taskId, taskTitle: task?.title ?? "", dueDate: dueDate
        )
        hasDueMomentNotification = true
    }

    private func cancelDueMomentNotification() async {
        await schedulingClient.cancelDueMomentNotification(taskId: taskId)
        hasDueMomentNotification = false
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
