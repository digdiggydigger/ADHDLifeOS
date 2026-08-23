//
//  FirebaseManager+Tasks.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

/// Task documents. Every field name here is snake_cased (`life_area_id`, `created_at`) — see
/// `FirestoreFieldPayloads` for why that convention differs from captures'.
extension FirebaseManager {
    func fetchTasks() async throws -> [TaskItem] {
        try await fetchAll(TaskItem.self, from: .tasks, orderedBy: "created_at", descending: true)
    }

    func fetchTaskDetail(id: UUID) async throws -> TaskDetail {
        try await collection(.tasks).document(id.uuidString).getDocument(as: TaskDetail.self)
    }

    func createTask(_ task: TaskDetail) async throws {
        try await save(task, id: task.id, in: .tasks)
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.taskUpdate(payload), in: .tasks)
    }

    /// Writes the status and its completion stamp in one update — see
    /// `FirestoreFieldPayloads.taskStatus` for why the stamp is the client's clock.
    func setTaskStatus(id: UUID, status: TaskStatus, now: Date = .now) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.taskStatus(status, now: now), in: .tasks)
    }

    func deleteTask(id: UUID) async throws {
        try await delete(id: id, from: .tasks)
    }

    /// Home's badge-count query: only the open tasks, projected down to `TaskSummary`.
    func fetchOpenTaskSummaries() async throws -> [TaskSummary] {
        try await fetchWhere(TaskSummary.self, from: .tasks, field: "status", equals: TaskStatus.open.rawValue)
    }

    /// Server-side scoped to one life area, per `LifeAreaDetailClientAdapting`'s contract.
    /// Unsorted (see `fetchWhere`) — `LifeAreaDetailService` orders for display.
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        try await fetchWhere(TaskItem.self, from: .tasks, field: "life_area_id", equals: lifeAreaId.uuidString)
    }
}
