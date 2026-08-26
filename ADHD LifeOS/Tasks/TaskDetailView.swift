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
    @State private var focusDurationSeconds = FocusSprintConfiguration.defaultDurationSeconds
    @State private var focusNudgeCount = 2

    // Staged-vs-immediate clarity state: discard-on-back gate (Part 4), the "Saved" affordance and
    // its haptic trigger (Part 3), and the delete confirmation (F-V3-Tasks-rebuild — delete moved
    // here from the list's swipe).
    @State private var showDiscardAlert = false
    @State private var showSavedConfirmation = false
    @State private var saveHapticTrigger = false
    @State private var showDeleteConfirmation = false

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
        .confirmationDialog(
            "Delete this task?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
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
            messagesSection
            saveSection(dirty: dirty)
            deleteSection
            createdAtFootnote(for: task)
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

            // v3's S3 chips: the task's identity at a glance — area tint, priority, due, effort.
            // They mirror the STAGED edits, so a changed area shows before Save commits it.
            TaskDetailChipsRow(
                area: lifeAreas.first { $0.id == lifeAreaId },
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                effortMinutes: focusDurationSeconds / 60
            )
            .listRowSeparator(.hidden)

            // Closing is one-way since F-V3-Tasks-rebuild (E's addendum): an open task gets the
            // close button; a closed one gets a quiet, display-only confirmation. No Reopen.
            if task.status == .open {
                Button {
                    Task { await service.close() }
                } label: {
                    Label(
                        MomentumTaskContext.closeButtonLabel(streak: momentumContext.streak),
                        systemImage: "checkmark.circle.fill"
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                .buttonStyle(MomentumSolidButtonStyle(
                    fill: Color("StateGo"),
                    foreground: Color("OnStateGo")
                ))
                .accessibilityIdentifier("taskDetailStatusToggle")
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } else {
                Label("Closed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color("StateGo"))
                    .accessibilityIdentifier("taskDetailClosedBadge")
            }
        } footer: {
            if task.status == .open {
                // Scoped to the status action — the Title field above is staged behind Save (Part 6).
                Text("Marking this done applies immediately — no Save needed.")
            }
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
        TaskDetailTagsSection(
            tags: service.tags,
            newTagName: $newTagName,
            onAdd: { name in await service.addTag(name: name) },
            onRemove: { tag in await service.removeTag(tag) }
        )
    }

    /// Delete lives here since F-V3-Tasks-rebuild (the list's swipe-left is gone). Destructive
    /// styling plus a confirmation dialog — deletion is the one action on this screen with no
    /// undo, so it never fires on a single tap.
    var deleteSection: some View {
        Section {
            Button("Delete Task", role: .destructive) {
                showDeleteConfirmation = true
            }
            .accessibilityIdentifier("taskDetailDeleteButton")
        }
    }

    /// The created date demoted to a quiet closing footnote (E's b11 addendum) — reference
    /// information, not a control, so it no longer wears a card of its own.
    func createdAtFootnote(for task: TaskDetail) -> some View {
        Section {
        } footer: {
            Text("Created \(task.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("taskDetailCreatedFootnote")
        }
    }

    /// Only on a landed delete: refresh the list and pop. A failed delete leaves
    /// `taskDetailErrorMessage` on screen and stays put.
    func performDelete() async {
        guard await service.delete() else { return }
        onUpdated()
        dismiss()
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
