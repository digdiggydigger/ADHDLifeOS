//
//  LifeAreaDetailPreviews.swift
//  ADHD LifeOS
//

import SwiftUI

#if DEBUG
private struct PreviewLifeAreaDetailClient: LifeAreaDetailClientAdapting {
    let areaId: UUID

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        [
            TaskItem(
                id: UUID(), lifeAreaId: areaId, title: "Break down Q3 Project Proposal",
                status: .open, priority: .p1, dueDate: .now, focusDurationSeconds: 1500
            ),
            TaskItem(
                id: UUID(), lifeAreaId: areaId, title: "Reply to the recruiter",
                status: .done, priority: .p4, dueDate: nil, completedAt: .now
            )
        ]
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        [Log(id: UUID(), lifeAreaId: areaId, type: .journal, body: "Great flow state today.",
             entryDate: .now, createdAt: .now)]
    }
}

private struct PreviewTaskDetailClient: TaskDetailClientAdapting {
    func fetchTask(id: UUID) async throws -> TaskDetail { fatalError("unused in preview") }
    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] { [] }
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

private func previewDetail() -> some View {
    let work = LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 0)
    let health = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 1)
    return NavigationStack {
        LifeAreaDetailView(
            lifeArea: work,
            client: PreviewLifeAreaDetailClient(areaId: work.id),
            taskDetailClient: PreviewTaskDetailClient(),
            allAreas: [work, health]
        )
    }
}

#Preview("Light") {
    previewDetail()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    previewDetail()
        .preferredColorScheme(.dark)
}
#endif
