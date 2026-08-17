//
//  TaskCreateView.swift
//  ADHD LifeOS
//

import SwiftUI

struct TaskCreateView: View {
    @StateObject private var service: TaskCreateService
    let lifeAreas: [LifeArea]
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isAddMoreInfoExpanded = false
    @State private var hasDueDate = false

    init(
        client: TaskCreateClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        lifeAreas: [LifeArea],
        onCreated: @escaping () -> Void
    ) {
        _service = StateObject(wrappedValue: TaskCreateService(client: client, schedulingClient: schedulingClient))
        self.lifeAreas = lifeAreas
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $service.title)
                        .accessibilityIdentifier("taskCreateTitleField")
                }

                DisclosureGroup("Add More Info", isExpanded: $isAddMoreInfoExpanded) {
                    dueDateSection
                    notesSection
                    lifeAreaSection
                    tagSection
                }

                TaskCountdownNudgeControl(dueDate: service.dueDate, selection: $service.nudgeSelection)

                Section {
                    Toggle("Notify me when this is due", isOn: $service.dueMomentNotificationEnabled)
                        .disabled(service.dueDate == nil)
                        .accessibilityIdentifier("taskCreateDueMomentNotificationToggle")
                }

                if let warningMessage = service.warningMessage {
                    Text(warningMessage)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("taskCreateWarningMessage")
                }
                if let errorMessage = service.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("taskCreateErrorMessage")
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            if await service.createTask() {
                                onCreated()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!service.isTitleValid || service.isSubmitting)
                    .accessibilityIdentifier("taskCreateSubmitButton")
                }
            }
            .task { await service.loadTags() }
        }
    }

    private var dueDateSection: some View {
        Group {
            Toggle("Due Date", isOn: $hasDueDate)
                .onChange(of: hasDueDate) { newValue in
                    service.dueDate = newValue ? (service.dueDate ?? Date()) : nil
                }
            if hasDueDate {
                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { service.dueDate ?? Date() },
                        set: { service.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var notesSection: some View {
        TextField("Notes", text: $service.notes, axis: .vertical)
            .accessibilityIdentifier("taskCreateNotesField")
    }

    private var lifeAreaSection: some View {
        LifeAreaPicker(
            title: "Life Area",
            noSelectionLabel: "None",
            lifeAreas: lifeAreas,
            selection: $service.lifeAreaId,
            accessibilityID: "taskCreateLifeAreaPicker"
        )
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch service.tagsState {
            case .idle, .loading:
                ProgressView()
            case .failed(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .loaded:
                ForEach(service.availableTags) { tag in
                    Button {
                        service.toggleTagSelection(tag)
                    } label: {
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if service.selectedTagIds.contains(tag.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            HStack {
                TextField("New tag", text: $service.newTagName)
                    .accessibilityIdentifier("taskCreateNewTagField")
                Button("Add") {
                    Task { await service.addNewTag() }
                }
                .disabled(service.newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("taskCreateAddTagButton")
            }
        }
    }
}

#if DEBUG
private struct PreviewTaskCreateClientAdapting: TaskCreateClientAdapting {
    func fetchTags() async throws -> [Tag] {
        [Tag(id: UUID(), name: "urgent"), Tag(id: UUID(), name: "errand")]
    }
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem { fatalError("unused in preview") }
    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {}
}

private struct PreviewNudgeSchedulingClientAdapting: TaskCountdownNudgeSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {}
    func cancelNudges(taskId: UUID) async {}
    func hasScheduledNudges(taskId: UUID) async -> Bool { false }
    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {}
    func cancelDueMomentNotification(taskId: UUID) async {}
    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool { false }
}

#Preview {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        schedulingClient: PreviewNudgeSchedulingClientAdapting(),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)]
    ) {}
}
#endif
