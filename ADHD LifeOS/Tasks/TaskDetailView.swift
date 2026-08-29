//
//  TaskDetailView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

struct TaskDetailView: View {
    /// Internal, not private, throughout this struct's stored state: the `Form` and every section
    /// it holds live in `TaskDetailFormSections.swift`, and `private` does not cross a file. The
    /// pair is the unit — nothing else should reach in here.
    @StateObject var service: TaskDetailService
    let lifeAreas: [LifeArea]
    /// Starts an app-level focus sprint (owned by `RootView`'s `FocusSessionService`). `nil` in
    /// hosts with no focus wiring, which hides the launch row but keeps the config editable.
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// S3's context (streak + "Momentum here" line), computed by the pushing screen — see
    /// `TaskDetailMomentumSection`. `.empty` degrades both to their pre-Momentum reading.
    let momentumContext: MomentumTaskContext.Context
    let onUpdated: () -> Void

    @Environment(\.dismiss) var dismiss

    @State var hasInitializedFields = false
    @State var title = ""
    @State var notes = ""
    @State var lifeAreaId: UUID?
    @State var priority: TaskPriority = .p4
    @State var dueDate: Date?
    @State var hasDueDate = false
    @State var newTagName = ""
    @State var focusDurationSeconds = FocusSprintConfiguration.defaultDurationSeconds
    @State var focusNudgeCount = 2
    @State var atPlaceId: UUID?

    // Staged-vs-immediate clarity state: discard-on-back gate (Part 4), the "Saved" affordance and
    // its haptic trigger (Part 3), and the delete confirmation (F-V3-Tasks-rebuild — delete moved
    // here from the list's swipe).
    /// The one that stays private: the discard gate is raised and answered entirely by this
    /// file's back control, so no section needs it.
    @State private var showDiscardAlert = false
    @State var showSavedConfirmation = false
    @State var saveHapticTrigger = false
    @State var showDeleteConfirmation = false

    init(
        taskId: UUID,
        lifeAreas: [LifeArea],
        client: TaskDetailClientAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        momentumContext: MomentumTaskContext.Context = .empty,
        onUpdated: @escaping () -> Void
    ) {
        _service = StateObject(
            wrappedValue: TaskDetailService(taskId: taskId, client: client)
        )
        self.lifeAreas = lifeAreas
        self.onStartFocus = onStartFocus
        self.momentumContext = momentumContext
        self.onUpdated = onUpdated
    }

    var body: some View {
        Group {
            switch service.state {
            case .loading:
                ProgressView()
                    .accessibilityIdentifier("taskDetailLoadingIndicator")
            case .failed(let message):
                VStack(spacing: 8) {
                    Text("Couldn't load this task")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .accessibilityIdentifier("taskDetailErrorMessage")
            case .loaded(let task):
                formView(for: task)
            }
        }
        // Top-anchored banner on the STABLE outer container, not the inner Form: saving sets
        // `state = .loaded(updated)`, which tears down and rebuilds the Form (and resets its scroll to
        // the top), so an overlay on the Form is torn down with it just as the confirmation fires. The
        // Group persists across that reload, and the top is exactly where the user's eye lands after
        // the scroll jump — and never occluded by the app's floating tab bar (device-verified).
        .overlay(alignment: .top) {
            if showSavedConfirmation {
                savedConfirmationToast
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: showSavedConfirmation)
        .haptic(.solid, trigger: saveHapticTrigger)
        .navigationTitle("Task")
        // The system back button can't be intercepted, so it's hidden and replaced with a custom
        // control running the unsaved-changes check (Part 4). Hiding it also disables interactive
        // swipe-back — an accepted outcome here, flagged as a screen-wide change in the build report.
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .alert("Discard changes?", isPresented: $showDiscardAlert) {
            Button("Discard Changes", role: .destructive) { dismiss() }
                .accessibilityIdentifier("taskDetailDiscardChangesButton")
            Button("Keep Editing", role: .cancel) {}
                .accessibilityIdentifier("taskDetailKeepEditingButton")
        } message: {
            Text("Your unsaved edits to this task will be lost.")
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                Haptics.play(.solid)
                Task { await performDelete() }
            }
            .accessibilityIdentifier("taskDetailConfirmDeleteButton")
        } message: {
            Text("This can't be undone.")
        }
        .task {
            await service.load()
        }
    }

    // MARK: - Custom back control (Part 4)

    /// Mirrors the system back button (chevron + label) so the screen still reads as a normal pushed
    /// detail, but routes through `attemptBack()` so unsaved staged edits prompt before leaving.
    private var backButton: some View {
        Button {
            attemptBack()
        } label: {
            Label("Back", systemImage: "chevron.backward")
                .labelStyle(.titleAndIcon)
        }
        .accessibilityIdentifier("taskDetailBackButton")
        .accessibilityLabel("Back")
    }

    private func attemptBack() {
        if case .loaded(let task) = service.state, dirtyState(for: task).hasUnsavedChanges {
            Haptics.play(.warning)
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    // MARK: - Dirty-state (Part 1 engine, consumed by Parts 2/4/5)

    var currentEditedFields: TaskEditedFields {
        TaskEditedFields(
            title: title, notes: notes, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate,
            focusDurationSeconds: focusDurationSeconds, nudgesCount: focusNudgeCount,
            atPlaceId: atPlaceId
        )
    }

    /// Guarding on `hasInitializedFields` returns a clean state until `.onAppear` seeds the fields
    /// (whose empty defaults would otherwise read as "everything changed"), so Save never flickers
    /// enabled and back-out never prompts on a screen the user only looked at.
    func dirtyState(for task: TaskDetail) -> TaskDetailDirtyState {
        guard hasInitializedFields else {
            return TaskDetailDirtyState(original: task, edited: TaskEditedFields(
                title: task.title, notes: task.notes ?? "", lifeAreaId: task.lifeAreaId,
                priority: task.priority, dueDate: task.dueDate, atPlaceId: task.atPlaceId
            ), defaultSprintSeconds: service.defaultSprintSeconds)
        }
        return TaskDetailDirtyState(
            original: task, edited: currentEditedFields,
            defaultSprintSeconds: service.defaultSprintSeconds
        )
    }
}
