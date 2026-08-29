//
//  TaskDetailFormSections.swift
//  ADHD LifeOS
//
//  The task detail screen's `Form` and its sections, split out of `TaskDetailView.swift` when
//  that file went over its 400-line budget (F-DiscClearance, 2026-08-29) — the same arrangement
//  `HomeMomentumSections`, `CaptureInboxSections` and `JournalTimelineSections` already use.
//
//  Splitting it costs one thing, stated rather than glossed: the sections read the view's staged
//  edit state, and `private` does not cross a file. So those properties are now internal, each
//  carrying the house note saying why. Nothing outside this pair should touch them.
//

import SwiftUI
import UIKit

extension TaskDetailView {
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
        .captureDiscClearance()
        .onAppear {
            guard !hasInitializedFields else { return }
            title = task.title
            notes = task.notes ?? ""
            lifeAreaId = task.lifeAreaId
            priority = task.priority
            dueDate = task.dueDate
            hasDueDate = task.dueDate != nil
            focusDurationSeconds = FocusSprintConfiguration.resolvedDuration(
                explicit: task.focusDurationSeconds, defaultSeconds: service.defaultSprintSeconds
            )
            focusNudgeCount = FocusSprintConfiguration.resolvedNudgeCount(
                explicit: task.nudgesCount, durationSeconds: focusDurationSeconds
            )
            atPlaceId = task.atPlaceId
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
                effortMinutes: focusDurationSeconds / 60,
                atPlace: service.places.first { $0.id == atPlaceId }
            )
            .listRowSeparator(.hidden)

            // Closing is one-way since F-V3-Tasks-rebuild (E's addendum): an open task gets the
            // close button; a closed one gets a quiet, display-only confirmation. No Reopen.
            if task.status == .open {
                Button {
                    Haptics.play(.taskClose)
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
        Section {
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
            .haptic(.selection, trigger: priority)
            .accessibilityIdentifier("taskDetailPriorityPicker")

            // Shown only once places exist — a picker whose menu holds nothing but "None" is a
            // dead control, and Places are created from Settings, not here.
            if !service.places.isEmpty {
                TaskAtPlacePicker(
                    places: service.places,
                    selection: $atPlaceId,
                    accessibilityID: "taskDetailAtPlacePicker"
                )
            }
        } header: {
            Text("Add More Info")
        } footer: {
            if !service.places.isEmpty {
                Text("At Place is where this task can be done — separate from where it ends up being closed.")
            }
        }
    }

    var tagsSection: some View {
        TaskDetailTagsSection(
            allTags: service.allTags,
            attachedTagIds: Set(service.tags.map(\.id)),
            newTagName: $newTagName,
            onToggle: { tag in await service.toggleTag(tag) },
            onAdd: { name in await service.addTag(name: name) }
        )
    }

    /// Delete lives here since F-V3-Tasks-rebuild (the list's swipe-left is gone). Destructive
    /// styling plus a confirmation dialog — deletion is the one action on this screen with no
    /// undo, so it never fires on a single tap.
    var deleteSection: some View {
        Section {
            Button("Delete Task", role: .destructive) {
                Haptics.play(.warning)
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
                .foregroundStyle(Color("StateWarn"))
                .accessibilityIdentifier("taskDetailWarningMessage")
        }
        if let errorMessage = service.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.octagon.fill")
                .foregroundStyle(Color("StateRisk"))
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
