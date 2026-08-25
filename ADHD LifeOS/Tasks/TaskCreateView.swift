//
//  TaskCreateView.swift
//  ADHD LifeOS
//
//  The v3 task composer (E's 2026-08-25 note): the stock Form became a dedicated S1-style
//  screen — the title as one big honest box, due dates as chips (`TaskDueChoice`, pure, tested),
//  every other question labelled optional out loud. The service machinery, the create seams and
//  the journey identifiers (`taskCreateTitleField`, `taskCreateSubmitButton`) are unchanged.
//

import SwiftUI

struct TaskCreateView: View {
    @StateObject private var service: TaskCreateService
    let lifeAreas: [LifeArea]
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var dueChoice: TaskDueChoice = .notYet

    init(
        client: TaskCreateClientAdapting,
        schedulingClient: TaskCountdownNudgeSchedulingAdapting,
        lifeAreas: [LifeArea],
        preselectedLifeAreaId: UUID? = nil,
        onCreated: @escaping () -> Void
    ) {
        _service = StateObject(wrappedValue: {
            let service = TaskCreateService(client: client, schedulingClient: schedulingClient)
            // The v3 area screen's "Add to <area>" opens the form already filed there.
            service.lifeAreaId = preselectedLifeAreaId
            return service
        }())
        self.lifeAreas = lifeAreas
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("One clear next action — every detail below is optional.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ComposerTextBox(
                        placeholder: "What needs doing?",
                        text: $service.title,
                        accessibilityID: "taskCreateTitleField"
                    )
                    dueSection
                    if service.dueDate != nil {
                        nudgeSection
                    }
                    areaSection
                    notesSection
                    tagsSection
                    if let warningMessage = service.warningMessage {
                        Text(warningMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateWarn"))
                            .accessibilityIdentifier("taskCreateWarningMessage")
                    }
                    if let errorMessage = service.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color("StateRisk"))
                            .accessibilityIdentifier("taskCreateErrorMessage")
                    }
                }
                .padding(16)
            }
            .background(Color.pageBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footerBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("New task")
                        .font(.headline)
                }
            }
            .task {
                dueChoice = TaskDueChoice.choice(for: service.dueDate, asOf: .now)
                await service.loadTags()
            }
        }
    }

    // MARK: - Due date

    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "When is it due?", detail: "optional")
            FlowingChips(spacing: 8) {
                ForEach(TaskDueChoice.allCases, id: \.title) { choice in
                    dueChip(choice)
                }
            }
            if dueChoice == .custom {
                DatePicker(
                    "Due",
                    selection: Binding(
                        get: { service.dueDate ?? .now },
                        set: { service.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .padding(16)
                .background(Color("CardSurfaceSecondary"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityIdentifier("taskCreateDueDatePicker")
            }
        }
    }

    private func dueChip(_ choice: TaskDueChoice) -> some View {
        let selected = dueChoice == choice
        return Button {
            dueChoice = choice
            service.dueDate = choice.resolvedDueDate(existing: service.dueDate, asOf: .now)
        } label: {
            Text(choice.title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("taskCreateDue-\(choice.title)")
    }

    /// Only on screen once a due date exists — nudges without one are impossible anyway, and S1's
    /// rule is one question at a time, never a disabled control explaining itself.
    private var nudgeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "Stay on it", detail: "optional")
            VStack(alignment: .leading, spacing: 8) {
                TaskCountdownNudgeControl(dueDate: service.dueDate, selection: $service.nudgeSelection)
                Toggle("Notify me when this is due", isOn: $service.dueMomentNotificationEnabled)
                    .accessibilityIdentifier("taskCreateDueMomentNotificationToggle")
            }
            .bentoCard()
        }
    }

    // MARK: - Area, notes, tags

    @ViewBuilder
    private var areaSection: some View {
        if !lifeAreas.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ComposerSectionHeader(title: "Life area", detail: "optional")
                ComposerAreaChips(
                    lifeAreas: lifeAreas.filter { !$0.archived },
                    noSelectionLabel: "Decide later",
                    selection: $service.lifeAreaId
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("taskCreateLifeAreaPicker")
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "Notes", detail: "optional")
            ComposerTextBox(
                placeholder: "Anything future-you needs to know",
                text: $service.notes,
                accessibilityID: "taskCreateNotesField"
            )
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "Tags", detail: "optional")
            switch service.tagsState {
            case .idle, .loading:
                ProgressView()
            case .failed(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .loaded:
                if !service.availableTags.isEmpty {
                    FlowingChips(spacing: 8) {
                        ForEach(service.availableTags) { tag in
                            tagChip(tag)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("New tag", text: $service.newTagName)
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 36)
                    .background(
                        Color("CardSurfaceSecondary"),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .accessibilityIdentifier("taskCreateNewTagField")
                Button("Add") {
                    Task { await service.addNewTag() }
                }
                .font(.caption.weight(.semibold))
                .disabled(service.newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("taskCreateAddTagButton")
            }
        }
    }

    private func tagChip(_ tag: Tag) -> some View {
        let selected = service.selectedTagIds.contains(tag.id)
        return Button {
            service.toggleTagSelection(tag)
        } label: {
            Text(tag.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? AreaPalette.work.onColor : Color("LabelSecondary"))
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(
                    selected
                        ? AnyShapeStyle(Color.accentColor)
                        : AnyShapeStyle(Color("CardSurfaceSecondary")),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("taskCreateTagChip-\(tag.id)")
    }

    // MARK: - Footer

    private var footerBar: some View {
        VStack(spacing: 8) {
            Text("Lands in your list — nothing is scheduled unless you asked for a nudge.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(service.isSubmitting ? "Adding…" : "Add the task") {
                Task {
                    if await service.createTask() {
                        onCreated()
                        dismiss()
                    }
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!service.isTitleValid || service.isSubmitting)
            .accessibilityIdentifier("taskCreateSubmitButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
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

#Preview("Light") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        schedulingClient: PreviewNudgeSchedulingClientAdapting(),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        schedulingClient: PreviewNudgeSchedulingClientAdapting(),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.dark)
}
#endif
