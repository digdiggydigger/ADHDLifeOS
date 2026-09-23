//
//  TaskCreateService.swift
//  ADHD LifeOS
//
//  The one task composer's state (`F-D1-ComposerBothDoors`): a title, a due date, an area and a
//  time — E's round 6 content, and nothing else. Tags, place and notes left with that block; they
//  live on the task, where `TaskDetailFormSections` edits all three right after creation.
//

import Combine
import Foundation

@MainActor
final class TaskCreateService: ObservableObject {
    @Published var title = ""
    @Published var lifeAreaId: UUID?
    @Published var dueDate: Date?
    @Published var effort: TaskEffortChoice = .standard
    @Published private(set) var isSubmitting = false
    @Published var errorMessage: String?
    /// The create succeeded and a follow-up write did not. Its only source is the Time write.
    @Published var warningMessage: String?
    @Published private(set) var createdTask: TaskItem?
    @Published private var lifeAreas: [LifeArea]

    private let client: TaskCreateClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let homeClient: HomeClientAdapting?

    /// - Parameters:
    ///   - lifeAreas: the areas a door already holds (the Tasks tab, a life area's screen).
    ///   - homeClient: for the door that holds none — the capture disc, in `RootView` — so the
    ///     composer fetches its own, `QuickCaptureView`'s pattern. `nil` means "use `lifeAreas`".
    init(
        client: TaskCreateClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        lifeAreas: [LifeArea] = [],
        homeClient: HomeClientAdapting? = nil
    ) {
        self.client = client
        self.taskDetailClient = taskDetailClient
        self.lifeAreas = lifeAreas
        self.homeClient = homeClient
    }

    /// What the Area menu lists — see `offeredAreas(_:selected:)`.
    var offeredLifeAreas: [LifeArea] {
        Self.offeredAreas(lifeAreas, selected: lifeAreaId)
    }

    /// Archived areas are hidden from a NEW task, as both old composers hid them — the shared
    /// `LifeAreaPicker` would otherwise list them greyed. The exception is the area the composer
    /// was opened filed to, which must still read as selected rather than as a blank "None".
    static func offeredAreas(_ areas: [LifeArea], selected: UUID?) -> [LifeArea] {
        areas.filter { !$0.archived || $0.id == selected }
    }

    var isTitleValid: Bool {
        if case .success = TaskCreateValidation.normalizeCreateTaskInput(
            title: title, notes: nil, lifeAreaId: nil, dueDate: nil
        ) {
            return true
        }
        return false
    }

    /// Swallows its failure on purpose: an areas outage must never stop someone adding a task, and
    /// an empty list simply hides the Area menu.
    func loadLifeAreas() async {
        guard let homeClient else { return }
        lifeAreas = (try? await homeClient.fetchLifeAreas()) ?? []
    }

    @discardableResult
    func createTask() async -> Bool {
        errorMessage = nil
        warningMessage = nil

        guard case .success(let normalized) = TaskCreateValidation.normalizeCreateTaskInput(
            title: title, notes: nil, lifeAreaId: lifeAreaId, dueDate: dueDate
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
        // The create is the commit point. Everything after it warns rather than fails, because a
        // task the user was told had failed — and so added again — would exist twice.
        createdTask = task

        // The create input has no focus fields, so the time lands as a follow-up write carrying
        // ONLY `focusDurationSeconds` — it can never overwrite what the create just wrote.
        var payload = TaskUpdatePayload()
        payload.focusDurationSeconds = effort.seconds
        do {
            _ = try await taskDetailClient.updateTask(id: task.id, payload: payload)
        } catch {
            warningMessage = "Task created, but couldn't save its time."
        }
        return true
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
