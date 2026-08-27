//
//  TaskDetailPreviews.swift
//  ADHD LifeOS
//
//  Preview scaffolding for TaskDetailView, split out of TaskDetailView.swift to keep that file
//  within the SwiftLint 400-line file-length budget (same precedent as HomeViewPreviews /
//  CaptureInboxPreviews). DEBUG-only.
//
//  The transient staged-vs-immediate states (Save enabled/disabled, the "Saved" confirmation, and
//  the due-date-dirty gate) depend on live edits to TaskDetailView's private @State, which a static
//  #Preview can't drive without a control-relocating refactor this block forbids. So those specific
//  affordances are previewed here as isolated components inside a Form (Light + Dark), and the full
//  screen is device-verified. See screenshots/task-detail-clarity-block/.
//

import SwiftUI

#if DEBUG
private struct PreviewTaskDetailClientAdapting: TaskDetailClientAdapting {
    let taskId: UUID
    let lifeAreaId: UUID
    var dueDate: Date? = Date().addingTimeInterval(3 * 24 * 3600)

    func fetchTask(id: UUID) async throws -> TaskDetail {
        TaskDetail(
            id: taskId, lifeAreaId: lifeAreaId, title: "Drink water", notes: "Stay hydrated",
            status: .open, priority: .p2, dueDate: dueDate, createdAt: Date()
        )
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] { [Tag(id: UUID(), name: "health")] }
    func fetchAllTags() async throws -> [Tag] { [] }
    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        fatalError("unused in preview")
    }
    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        fatalError("unused in preview")
    }
        func deleteTask(id: UUID) async throws {}
    func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
    func addTagToTask(taskId: UUID, tagId: UUID) async throws {}
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {}
}

private func previewDetail(dueDate: Date?) -> some View {
    let lifeArea = LifeArea(id: UUID(), name: "Health", colour: "#4A90D9", sortOrder: 0)
    return NavigationStack {
        TaskDetailView(
            taskId: UUID(),
            lifeAreas: [lifeArea],
            client: PreviewTaskDetailClientAdapting(taskId: UUID(), lifeAreaId: lifeArea.id, dueDate: dueDate)
        ) {}
    }
}

#Preview("Loaded — Light") {
    previewDetail(dueDate: Date().addingTimeInterval(3 * 24 * 3600))
        .preferredColorScheme(.light)
}

#Preview("Loaded — Dark") {
    previewDetail(dueDate: Date().addingTimeInterval(3 * 24 * 3600))
        .preferredColorScheme(.dark)
}

#Preview("No due date — Light") {
    previewDetail(dueDate: nil)
        .preferredColorScheme(.light)
}

// The new affordances, in isolation inside a Form so their exact staged/immediate presentation and
// Dynamic Type behaviour can be eyeballed without driving live view state.

private struct AffordancePreviews: View {
    var body: some View {
        Form {
            Section {
                Button("Save") {}
                    .disabled(true)
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color("StateGo"))
            } header: {
                Text("Save — disabled (clean) + confirmation")
            }

            Section {
                Toggle("Notify me when this is due", isOn: .constant(false))
                    .disabled(true)
                Label("Save the due date first to change this.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Changes here apply immediately — no Save needed.")
            }
        }
    }
}

#Preview("Affordances — Light") {
    AffordancePreviews()
        .preferredColorScheme(.light)
}

#Preview("Affordances — Dark") {
    AffordancePreviews()
        .preferredColorScheme(.dark)
}
#endif
