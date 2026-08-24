//
//  TaskDetailView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

struct TaskDetailView: View {
    @StateObject private var service: TaskDetailService
    let lifeAreas: [LifeArea]
    /// Starts an app-level focus sprint (owned by `RootView`'s `FocusSessionService`). `nil` in
    /// hosts with no focus wiring, which hides the launch row but keeps the config editable.
    let onStartFocus: ((FocusSprintPlan) -> Void)?
    /// S3's context (streak + "Momentum here" line), computed by the pushing screen — see
    /// `TaskDetailMomentumSection`. `.empty` degrades both to their pre-Momentum reading.
    let momentumContext: MomentumTaskContext.Context
    let onUpdated: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hasInitializedFields = false
    @State private var title = ""
    @State private var notes = ""
    @State private var lifeAreaId: UUID?
    @State private var priority: TaskPriority = .p4
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var newTagName = ""
    @State private var pendingNudgeSelection: NudgeCountdownSelection = .none
    @State private var focusDurationSeconds = FocusSprintConfiguration.defaultDurationSeconds
    @State private var focusNudgeCount = 2

    // Staged-vs-immediate clarity state: discard-on-back gate (Part 4), the "Saved" affordance and
    // its haptic trigger (Part 3).
    @State private var showDiscardAlert = false
    @State private var showSavedConfirmation = false
    @State private var saveHapticTrigger = false

    init(
        taskId: UUID,
        lifeAreas: [LifeArea],
        client: TaskDetailClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        onStartFocus: ((FocusSprintPlan) -> Void)? = nil,
        momentumContext: MomentumTaskContext.Context = .empty,
        onUpdated: @escaping () -> Void
    ) {
        _service = StateObject(
            wrappedValue: TaskDetailService(taskId: taskId, client: client, schedulingClient: schedulingClient)
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
        .saveSuccessHaptic(trigger: saveHapticTrigger)
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
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    // MARK: - Dirty-state (Part 1 engine, consumed by Parts 2/4/5)

    var currentEditedFields: TaskEditedFields {
        TaskEditedFields(
            title: title, notes: notes, lifeAreaId: lifeAreaId, priority: priority, dueDate: dueDate,
            focusDurationSeconds: focusDurationSeconds, nudgesCount: focusNudgeCount
        )
    }

    /// Guarding on `hasInitializedFields` returns a clean state until `.onAppear` seeds the fields
    /// (whose empty defaults would otherwise read as "everything changed"), so Save never flickers
    /// enabled and back-out never prompts on a screen the user only looked at.
    func dirtyState(for task: TaskDetail) -> TaskDetailDirtyState {
        guard hasInitializedFields else {
            return TaskDetailDirtyState(original: task, edited: TaskEditedFields(
                title: task.title, notes: task.notes ?? "", lifeAreaId: task.lifeAreaId,
                priority: task.priority, dueDate: task.dueDate
            ))
        }
        return TaskDetailDirtyState(original: task, edited: currentEditedFields)
    }
}

// MARK: - Form & sections
//
// Split into an extension so the primary struct body stays within SwiftLint's type_body_length
// budget; same-file, so it still reaches the view's private state.

private extension TaskDetailView {
    func formView(for task: TaskDetail) -> some View {
        let dirty = dirtyState(for: task)
        return Form {
            titleAndStatusSection(for: task)
            momentumHereSection
            TaskFocusPlanSection(
                durationSeconds: $focusDurationSeconds,
                nudgeCount: $focusNudgeCount,
                onStart: onStartFocus == nil ? nil : { Task { await startFocusSprint(for: task) } }
            )
            addMoreInfoSection
            tagsSection
            nudgesSection(isDueDateDirty: dirty.isDueDateDirty)
            dueMomentNotificationSection(isDueDateDirty: dirty.isDueDateDirty)
            createdAtSection(for: task)
            messagesSection
            saveSection(dirty: dirty)
        }
        .onAppear {
            guard !hasInitializedFields else { return }
            title = task.title
            notes = task.notes ?? ""
            lifeAreaId = task.lifeAreaId
            priority = task.priority
            dueDate = task.dueDate
            hasDueDate = task.dueDate != nil
            focusDurationSeconds = FocusSprintConfiguration.resolvedDuration(explicit: task.focusDurationSeconds)
            focusNudgeCount = FocusSprintConfiguration.resolvedNudgeCount(
                explicit: task.nudgesCount, durationSeconds: focusDurationSeconds
            )
            hasInitializedFields = true
        }
    }

    /// Save-then-start: unsaved staged edits (including the focus config itself) are persisted
    /// first, so the sprint never runs against config the stored task lacks — and a failed save
    /// aborts the launch, leaving `taskDetailErrorMessage` to explain. On success the screen pops
    /// so the app-level `FocusTimerBar` is immediately visible.
    func startFocusSprint(for task: TaskDetail) async {
        if dirtyState(for: task).hasUnsavedChanges {
            guard await service.save(edited: currentEditedFields) else { return }
        }
        onStartFocus?(FocusSprintPlan(
            taskId: task.id,
            taskTitle: title.trimmingCharacters(in: .whitespacesAndNewlines),
            lifeAreaEmoji: lifeAreas.first { $0.id == lifeAreaId }?.colour ?? "🎯",
            durationSeconds: focusDurationSeconds,
            nudgeCount: focusNudgeCount
        ))
        onUpdated()
        dismiss()
    }

    func titleAndStatusSection(for task: TaskDetail) -> some View {
        Section {
            TextField("Title", text: $title)
                .accessibilityIdentifier("taskDetailTitleField")

            Button {
                Task { await service.toggleStatus() }
            } label: {
                Text(MomentumTaskContext.closeButtonLabel(status: task.status, streak: momentumContext.streak))
            }
            .accessibilityIdentifier("taskDetailStatusToggle")
        } footer: {
            // Scoped to the status action specifically — the Title field above it is staged behind
            // Save, so the footer names the immediate control rather than the whole section (Part 6).
            Text("Marking this done or reopening it applies immediately — no Save needed.")
        }
    }

    var addMoreInfoSection: some View {
        Section("Add More Info") {
            Toggle("Due Date", isOn: $hasDueDate)
                .onChange(of: hasDueDate) { newValue in
                    dueDate = newValue ? (dueDate ?? Date()) : nil
                }
            if hasDueDate {
                DatePicker(
                    "Date",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            TextField("Notes", text: $notes, axis: .vertical)
                .accessibilityIdentifier("taskDetailNotesField")

            LifeAreaPicker(
                title: "Life Area",
                noSelectionLabel: "None",
                lifeAreas: lifeAreas,
                selection: $lifeAreaId,
                accessibilityID: "taskDetailLifeAreaPicker"
            )

            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases, id: \.self) { option in
                    Text(option.rawValue.uppercased()).tag(option)
                }
            }
            .accessibilityIdentifier("taskDetailPriorityPicker")
        }
    }

    var tagsSection: some View {
        Section {
            ForEach(service.tags) { tag in
                HStack {
                    Text(tag.name)
                    Spacer()
                    Button("Remove") {
                        Task { await service.removeTag(tag) }
                    }
                }
            }

            HStack {
                TextField("New tag", text: $newTagName)
                    .accessibilityIdentifier("taskDetailNewTagField")
                Button("Add") {
                    Task {
                        await service.addTag(name: newTagName)
                        newTagName = ""
                    }
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("taskDetailAddTagButton")
            }
        } header: {
            Text("Tags")
        } footer: {
            Text("Adding or removing a tag applies immediately — no Save needed.")
        }
    }

    /// Scheduled → summary + "Turn Off" (the exact prior selection isn't reconstructable from the
    /// pending-notifications list, so re-showing a pre-filled picker would misrepresent it). Part 5
    /// gate: while the due date is unsaved the *arming* picker (else branch) is disabled, since it
    /// schedules real OS notifications against a staged time the stored task doesn't have; "Turn Off"
    /// never arms, so it stays enabled (a saved due-date change cancels nudges anyway).
    @ViewBuilder
    func nudgesSection(isDueDateDirty: Bool) -> some View {
        if service.hasScheduledNudges {
            Section {
                Text("Nudges are scheduled for this task.")
                    .foregroundStyle(.secondary)
                Button("Turn Off Nudges") {
                    Task { await service.disableNudges() }
                }
                .accessibilityIdentifier("taskDetailDisableNudgesButton")
            } header: {
                Text("Nudges")
            } footer: {
                immediateApplyFooter
            }
        } else {
            TaskCountdownNudgeControl(dueDate: dueDate, selection: $pendingNudgeSelection)
                .disabled(isDueDateDirty)
                .onChange(of: pendingNudgeSelection) { newValue in
                    guard let dueDate else { return }
                    Task { await service.updateNudgeSelection(newValue, dueDate: dueDate) }
                }
            Section {
                if isDueDateDirty {
                    saveDueDateFirstNote
                }
            } footer: {
                immediateApplyFooter
            }
        }
    }

    /// Independent of `nudgesSection` above — a plain toggle rather than a menu, since this
    /// feature has only two states (on/off). Gated identically to the nudge picker while the
    /// due date is unsaved (Part 5).
    func dueMomentNotificationSection(isDueDateDirty: Bool) -> some View {
        Section {
            Toggle("Notify me when this is due", isOn: dueMomentNotificationBinding)
                .disabled(dueDate == nil || isDueDateDirty)
                .accessibilityIdentifier("taskDetailDueMomentNotificationToggle")
            if isDueDateDirty {
                saveDueDateFirstNote
            }
        } footer: {
            immediateApplyFooter
        }
    }

    var dueMomentNotificationBinding: Binding<Bool> {
        Binding(
            get: { service.hasDueMomentNotification },
            set: { newValue in
                guard let dueDate else { return }
                Task { await service.updateDueMomentNotification(enabled: newValue, dueDate: dueDate) }
            }
        )
    }

    func createdAtSection(for task: TaskDetail) -> some View {
        Section {
            LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
    }

    /// Warning and error are conveyed as icon + text (§4) so meaning never rides on colour alone —
    /// legible to a colour-blind user and read as a single element by VoiceOver. Identifiers verbatim.
    @ViewBuilder
    var messagesSection: some View {
        if let warningMessage = service.warningMessage {
            Label(warningMessage, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityIdentifier("taskDetailWarningMessage")
        }
        if let errorMessage = service.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                .foregroundStyle(.red)
                .accessibilityIdentifier("taskDetailErrorMessage")
        }
    }

    /// Save (Part 2) is disabled unless there is a real pending change, so it reflects state rather
    /// than looking identical whether five edits are staged or none — the disabled look is SwiftUI's
    /// semantic control styling, not an `.opacity` filter (§4).
    func saveSection(dirty: TaskDetailDirtyState) -> some View {
        Section {
            Button("Save") {
                Task { await performSave() }
            }
            .disabled(
                !dirty.hasUnsavedChanges
                    || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || service.isSaving
            )
            .accessibilityIdentifier("taskDetailSaveButton")
        }
    }

    /// Only on success: fire the confirmation, haptic and a VoiceOver announcement, then auto-fade.
    /// A failed save leaves `taskDetailErrorMessage` to carry it and never buzzes or confirms as if it
    /// landed (same rule as `4162290`'s promote haptic). Save is disabled unless dirty, so the
    /// service's empty-payload no-op (returns `true`) is unreachable here.
    ///
    /// `onUpdated()` is fired LAST, after the confirmation has shown and faded. It reloads the parent
    /// Tasks list, which rebuilds this pushed `navigationDestination` and wipes the view's `@State`
    /// (including `showSavedConfirmation`) — so calling it up front would erase the banner the instant
    /// it appeared. Deferring it keeps the confirmation visible; the detached `Task` still runs it even
    /// if the user backs out first, so the list is always refreshed.
    func performSave() async {
        guard await service.save(edited: currentEditedFields) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
            showSavedConfirmation = true
        }
        saveHapticTrigger.toggle()
        UIAccessibility.post(notification: .announcement, argument: "Saved")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation(.easeOut) { showSavedConfirmation = false }
        onUpdated()
    }
}
