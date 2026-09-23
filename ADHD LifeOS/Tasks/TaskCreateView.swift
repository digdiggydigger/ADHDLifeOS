//
//  TaskCreateView.swift
//  ADHD LifeOS
//
//  The task composer — and since `F-D1-ComposerBothDoors`, the ONLY one. E, round 6: *"One
//  composer, both doors"*: the Tasks "+" and a life area's "Add to <area>" present it as a sheet,
//  the capture disc's Task tile (and the widget's door, which routes the same way) as a full-screen
//  cover — same view, two chromes, inherited from the doors rather than chosen here.
//
//  Its content is round 6's, verbatim in intent: a title, the four "when" chips, and an Area and a
//  Time menu ("menus, not sheets"). Tags, place and notes live on the task. The LAYOUT is still the
//  v3 vertical one; round 7b's "rides on the keyboard" layout is `F-D2`.
//

import SwiftUI

struct TaskCreateView: View {
    @StateObject var service: TaskCreateService
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var dueChoice: TaskDueChoice = .notYet

    /// `F-C2-DraftsToInbox`: the seam an abandoned title is filed through. **Optional with an
    /// inert default, exactly as `CaptureInboxView`'s `celebrate:` is** — every preview builds
    /// this screen unchanged, and the app's own wiring is asserted by
    /// `ComposerDraftCallSiteTests` rather than left to a default that would hide a missed
    /// call site (the `dead-shared-component-pattern` failure, seven times over in this repo).
    let captureClient: CaptureClientAdapting?
    /// A composer that SUBMITTED files no draft: the title is still in the service when the sheet
    /// dismisses, and the just-created task's words would be filed again as an abandoned draft.
    @State var didSubmit = false

    @Environment(\.recordAction) var recordAction
    @Environment(\.openCapture) var openCapture

    /// - Parameters:
    ///   - taskDetailClient: the Time menu writes through it — required, so a door cannot forget it.
    ///   - lifeAreas: the areas a door already holds; `homeClient` fetches them for a door that
    ///     holds none (the capture disc, in `RootView`).
    init(
        client: TaskCreateClientAdapting,
        taskDetailClient: TaskDetailClientAdapting,
        lifeAreas: [LifeArea] = [],
        homeClient: HomeClientAdapting? = nil,
        preselectedLifeAreaId: UUID? = nil,
        captureClient: CaptureClientAdapting? = nil,
        onCreated: @escaping () -> Void
    ) {
        self.captureClient = captureClient
        _service = StateObject(wrappedValue: {
            let service = TaskCreateService(
                client: client, taskDetailClient: taskDetailClient,
                lifeAreas: lifeAreas, homeClient: homeClient
            )
            // The v3 area screen's "Add to <area>" opens the form already filed there.
            service.lifeAreaId = preselectedLifeAreaId
            return service
        }())
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
                    areaAndTimeSection
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
                    // **"Close", not "Cancel"** (E, round 2). `sheets.md › Best practices`:
                    // Cancel means *without saving*, and this control no longer discards.
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("taskCreateCloseButton")
                }
                ToolbarItem(placement: .principal) {
                    Text("New task")
                        .font(.headline)
                }
            }
            // **`F-C2-DraftsToInbox`.** `.onDisappear` catches the swipe, the Close button and —
            // since `F-D1` — the capture disc's full-screen cover alike (Step 0 answer 2: file
            // once the composer has ACTUALLY gone, so a swipe keeps dismissing as it does today),
            // and a half-swipe that springs back never calls it — so a cancelled dismissal files
            // nothing by construction rather than by a guard.
            .onDisappear { fileDraftIfNeeded() }
            .task {
                dueChoice = TaskDueChoice.choice(for: service.dueDate, asOf: .now)
                await service.loadLifeAreas()
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
            Haptics.play(.selection)
            dueChoice = choice
            service.dueDate = choice.resolvedDueDate(existing: service.dueDate, asOf: .now)
        } label: {
            Text(choice.title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ChoiceChipButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("taskCreateDue-\(choice.title)")
    }

    // MARK: - Area and time

    /// Round 6's "area and time pop-up chips (menus, not sheets)". Carded like the custom date
    /// picker above — this composer's treatment for a control that is not a chip — and 48pt,
    /// because round 7 kept the composer's own controls at 48 ("the composer's own chips stay 48").
    /// Both always show: Time has no empty state, and Area hides only when there are no areas to
    /// offer, which is a question with no answers.
    private var areaAndTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ComposerSectionHeader(title: "Area and time", detail: "optional")
            if !service.offeredLifeAreas.isEmpty {
                LifeAreaPicker(
                    title: "Area",
                    noSelectionLabel: "None",
                    lifeAreas: service.offeredLifeAreas,
                    selection: $service.lifeAreaId,
                    accessibilityID: "taskCreateLifeAreaPicker",
                    showsPopUpIndicator: true
                )
                .menuCard()
            }
            timeMenu
                .menuCard()
        }
    }

    private var timeMenu: some View {
        Menu {
            ForEach(TaskEffortChoice.allCases, id: \.seconds) { choice in
                Button {
                    service.effort = choice
                } label: {
                    if service.effort == choice {
                        Label(choice.title, systemImage: "checkmark")
                    } else {
                        Text(choice.title)
                    }
                }
            }
        } label: {
            // `LabeledContent` for the §7 house reason: it reflows at accessibility Dynamic Type
            // sizes instead of clipping into narrow columns.
            LabeledContent("Time") {
                HStack(spacing: 4) {
                    Text(service.effort.title)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("taskCreateTimeMenu")
    }

    // MARK: - Footer

    private var footerBar: some View {
        VStack(spacing: 8) {
            Text("Lands in your list — nothing else happens until you decide it does.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(service.isSubmitting ? "Adding…" : "Add the task") {
                Task {
                    if await service.createTask() {
                        didSubmit = true
                        Haptics.play(.solid)
                        onCreated()
                        dismiss()
                    } else {
                        Haptics.play(.error)
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
        .composerFooterSurface()
    }
}

private extension View {
    /// The composer's card for a Menu row: full width, 48pt tall, the label tinted primary so the
    /// row reads as a setting with its value rather than as a run of accent-blue link text.
    func menuCard() -> some View {
        self
            .tint(.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color("CardSurfaceSecondary"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#if DEBUG
private struct PreviewTaskCreateClientAdapting: TaskCreateClientAdapting {
    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem { fatalError("unused in preview") }
}

private struct PreviewTaskCreateDetailClient: TaskDetailClientAdapting {
    func fetchTask(id: UUID) async throws -> TaskDetail { fatalError("unused in preview") }
    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] { [] }
    func fetchAllTags() async throws -> [Tag] { [] }
    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail { fatalError("unused in preview") }
    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail { fatalError("unused in preview") }
    func softDeleteTask(id: UUID) async throws {}
    func restoreTask(id: UUID) async throws {}
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func addTagToTask(taskId: UUID, tagId: UUID) async throws {}
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {}
}

#Preview("Light") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskCreateDetailClient(),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskCreateDetailClient(),
        lifeAreas: [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]
    ) {}
    .preferredColorScheme(.dark)
}
#endif
