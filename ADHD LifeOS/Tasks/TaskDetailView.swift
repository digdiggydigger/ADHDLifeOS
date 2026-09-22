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
    /// Held BESIDE the service, not read off it (`F-C3-RecentlyDeleted`). The delete's undo
    /// closure outlives this screen — `performDelete()` dismisses — so it captures the adapter
    /// and the id the way `ComposerDraftFiler` does, rather than a `@StateObject` the dismissal
    /// is tearing down. The service keeps its own `client` private; this is the same value the
    /// init already receives.
    let client: TaskDetailClientAdapting
    let taskId: UUID
    let lifeAreas: [LifeArea]
    /// Starts an app-level focus sprint (owned by `RootView`'s `FocusSessionService`). `nil` in
    /// hosts with no focus wiring, which hides the launch row but keeps the config editable.
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// S3's context (streak + "Momentum here" line), computed by the pushing screen — see
    /// `TaskDetailMomentumSection`. `.empty` degrades both to their pre-Momentum reading.
    let momentumContext: MomentumTaskContext.Context
    let onUpdated: () -> Void

    @Environment(\.dismiss) var dismiss
    /// `F-C1-UndoCapsule`: the app's one undo slot. Internal, not private — the Close button lives
    /// in `TaskDetailFormSections.swift`, and Swift `private` is file-scoped.
    @Environment(\.recordAction) var recordAction

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

    // Staged-vs-immediate clarity state: the "Saved" affordance and its haptic trigger (Part 3),
    // and the delete confirmation (F-V3-Tasks-rebuild — delete moved here from the list's swipe).
    //
    // **The discard-on-back gate that used to live here is GONE** (`F-C2-DraftsToInbox`, E's round
    // 2): *"Task detail's blocking 'Discard changes?' becomes autosave with swipe-back restored."*
    // Leaving the screen commits instead of asking — see `autosaveOnLeaving()`.
    @State var showSavedConfirmation = false
    @State var saveHapticTrigger = false

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
        self.client = client
        self.taskId = taskId
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
        // **The system back button is back, and with it interactive swipe-back.** It used to be
        // hidden so a custom control could intercept the tap and raise the discard gate; the view's
        // own comment called losing the gesture "an accepted outcome". E's round 2 stopped
        // accepting it, and there is nothing left to intercept — leaving commits.
        //
        // **`.onDisappear` rather than a hook on the back control, and that is the point.** The
        // system button cannot be intercepted at all, and it is no longer the only way off this
        // screen: the swipe gesture and a tab switch both leave without touching any control.
        // One hook on the screen's own disappearance catches every one of them.
        .onDisappear { autosaveOnLeaving() }
        .task {
            await service.load()
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
