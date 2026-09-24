//
//  TaskCreateView.swift
//  ADHD LifeOS
//
//  The task composer — and since `F-D1-ComposerBothDoors`, the ONLY one. E, round 6: *"One
//  composer, both doors"*: the Tasks "+" and a life area's "Add to <area>" present it as a sheet,
//  the capture disc's Task tile (and the widget's door, which routes the same way) as a full-screen
//  cover — same view, two chromes, inherited from the doors rather than chosen here.
//
//  Its content is round 6's, verbatim in intent: a title, the four "when" choices, and an Area and
//  a Time menu ("menus, not sheets"). Tags, place and notes live on the task.
//
//  Its LAYOUT is round 7b's since `F-D2-ComposerKeyboardLayout`. E chose L3: *"The title owns the
//  page. Every choice and Add sit in one bar just above the keyboard."* At accessibility sizes the
//  bar cannot share the screen with the keyboard, so the composer falls back to L1's stacked form,
//  which was carried in the option E chose. The controls both layouts share are in
//  `TaskComposerControls.swift`, and the bar is `TaskComposerKeyboardBar.swift`.
//

import SwiftUI

struct TaskCreateView: View {
    @StateObject var service: TaskCreateService
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
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

    /// Round 7b's L3 up to the largest ordinary text size, and L1's stacked form at every
    /// accessibility size. The design record: *"At AX3 the bar cannot share the screen with the
    /// keyboard ... At accessibility sizes the build uses L1's stacked form instead."*
    static func usesStackedForm(at size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    var body: some View {
        NavigationStack {
            layout
                .background(Color.pageBackground.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        // **"Close", not "Cancel"** (E, round 2). `sheets.md › Best practices`:
                        // Cancel means *without saving*, and this control no longer discards.
                        // Round 7's 48 × 48 is NOT reached here: F-D2 grew the label and the bar
                        // item still measured 72 × 36 on 27.0 (the system sizes a bar item, not the
                        // view inside it). F-B1-TouchTargets owns the corner-control sweep.
                        Button("Close") { dismiss() }
                            .accessibilityIdentifier("taskCreateCloseButton")
                    }
                    ToolbarItem(placement: .principal) {
                        Text("New task")
                            .font(.headline)
                    }
                }
                // **`F-C2-DraftsToInbox`.** `.onDisappear` catches the swipe, the Close button
                // and — since `F-D1` — the capture disc's full-screen cover alike (Step 0 answer 2:
                // file once the composer has ACTUALLY gone, so a swipe keeps dismissing as it does
                // today), and a half-swipe that springs back never calls it — so a cancelled
                // dismissal files nothing by construction rather than by a guard.
                .onDisappear { fileDraftIfNeeded() }
                .task {
                    dueChoice = TaskDueChoice.choice(for: service.dueDate, asOf: .now)
                    await service.loadLifeAreas()
                }
        }
    }

    @ViewBuilder
    private var layout: some View {
        if Self.usesStackedForm(at: typeSize) {
            stackedForm
        } else {
            keyboardForm
        }
    }

    // MARK: - L3: the title owns the page

    /// The title, boxless at `.title2` (round 7b's L3), with every choice in the bar that rides
    /// the keyboard. The page scrolls, so a long title never pushes the bar off the screen.
    private var keyboardForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextField("", text: $service.title, prompt: Text("What needs doing?"), axis: .vertical)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1...6)
                    .accessibilityIdentifier("taskCreateTitleField")
                messages
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .safeAreaInset(edge: .bottom) {
            TaskComposerKeyboardBar(service: service, dueChoice: $dueChoice, onAdd: submit)
        }
    }

    // MARK: - L1 stacked, at accessibility sizes

    /// The board's L1 AX3 column: the boxed title, the segments one above the next, full-width
    /// Area and Time, all scrolling, and Add pinned alone at the bottom where it rides the keyboard.
    private var stackedForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ComposerTextBox(
                    placeholder: "What needs doing?",
                    text: $service.title,
                    accessibilityID: "taskCreateTitleField"
                )
                TaskWhenSegments(service: service, dueChoice: $dueChoice)
                if !service.offeredLifeAreas.isEmpty {
                    TaskComposerAreaMenu(service: service, compact: false)
                }
                TaskComposerTimeMenu(service: service, compact: false)
                messages
            }
            .padding(16)
        }
        .safeAreaInset(edge: .bottom) {
            TaskComposerAddButton(service: service, compact: false, action: submit)
                .padding(16)
                .composerFooterSurface()
        }
    }

    // MARK: - Shared

    @ViewBuilder
    private var messages: some View {
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

    private func submit() {
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

private let previewAreas = [LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)]

extension TaskCreateService {
    /// A service the composer's previews can build, with one area and clients that are never called.
    static func preview() -> TaskCreateService {
        TaskCreateService(
            client: PreviewTaskCreateClientAdapting(),
            taskDetailClient: PreviewTaskCreateDetailClient(),
            lifeAreas: previewAreas
        )
    }
}

#Preview("Light") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskCreateDetailClient(),
        lifeAreas: previewAreas
    ) {}
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskCreateDetailClient(),
        lifeAreas: previewAreas
    ) {}
    .preferredColorScheme(.dark)
}

#Preview("Accessibility 3 — the stacked form") {
    TaskCreateView(
        client: PreviewTaskCreateClientAdapting(),
        taskDetailClient: PreviewTaskCreateDetailClient(),
        lifeAreas: previewAreas
    ) {}
    .dynamicTypeSize(.accessibility3)
}
#endif
