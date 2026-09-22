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
        live(try await fetchAll(TaskItem.self, from: .tasks, orderedBy: "created_at", descending: true))
    }

    func fetchTaskDetail(id: UUID) async throws -> TaskDetail {
        try requireLive(try await collection(.tasks).document(id.uuidString).getDocument(as: TaskDetail.self))
    }

    func createTask(_ task: TaskDetail) async throws {
        try await save(task, id: task.id, in: .tasks)
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.taskUpdate(payload), in: .tasks)
    }

    /// Writes the status, its completion stamp and its location stamp in one update — see
    /// `FirestoreFieldPayloads.taskStatus` for why the completion stamp is the client's clock
    /// and why the location trio is value-or-erase, never absent.
    func setTaskStatus(
        id: UUID, status: TaskStatus, locationStamp: LocationStamp?, now: Date = .now
    ) async throws {
        try await update(
            id: id,
            fields: FirestoreFieldPayloads.taskStatus(status, now: now, locationStamp: locationStamp),
            in: .tasks
        )
    }

    func deleteTask(id: UUID) async throws {
        try await delete(id: id, from: .tasks)
    }

    /// Home's badge-count query: only the open tasks, projected down to `TaskSummary`.
    func fetchOpenTaskSummaries() async throws -> [TaskSummary] {
        live(try await fetchWhere(TaskSummary.self, from: .tasks, field: "status", equals: TaskStatus.open.rawValue))
    }

    /// Server-side scoped to one life area, per `LifeAreaDetailClientAdapting`'s contract.
    /// Unsorted (see `fetchWhere`) — `LifeAreaDetailService` orders for display.
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        live(try await fetchWhere(TaskItem.self, from: .tasks, field: "life_area_id", equals: lifeAreaId.uuidString))
    }

    /// Soft delete (`F-C3-RecentlyDeleted`). An UPDATE, never a `delete` — the document stays and
    /// the stamp is the only thing hiding it, which is what makes `restoreTask(id:)` possible.
    ///
    /// **`deleteTask(id:)` above KEEPS its name as the irreversible one**, used by the launch
    /// purge and by "Delete forever" alone. Re-pointing an existing method at gentler behaviour is
    /// the silent-semantics trap: a caller that wants the document gone should have to type it.
    ///
    /// Going through `update(id:fields:in:)` is load-bearing beyond tidiness — that is the write
    /// plumbing every adapter shares, and it posts `DataChangeSignal`, which is how a restored
    /// task reappears in `TaskListView` at once rather than on the next tab visit.
    func softDeleteTask(id: UUID, now: Date = .now) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.taskSoftDelete(now: now), in: .tasks)
    }

    /// The way back. The stamp is ERASED, not nulled — see `FirestoreFieldPayloads.taskRestore()`.
    func restoreTask(id: UUID) async throws {
        try await update(id: id, fields: FirestoreFieldPayloads.taskRestore(), in: .tasks)
    }

    /// Recently Deleted's own list: the one fetch here that keeps exactly what the others drop.
    /// **Not `whereField`** — a soft-delete query cannot be expressed server-side, because
    /// `isEqualTo: NSNull()` matches only documents where the key is present and null and every
    /// task written before this block has no key at all. Same reason `live(_:)` is client-side.
    func fetchDeletedTasks() async throws -> [TaskItem] {
        deleted(try await fetchAll(TaskItem.self, from: .tasks, orderedBy: "created_at", descending: true))
    }
}
