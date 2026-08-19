//
//  TasksClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the tasks backend so `TasksService` is testable without a network. The two
/// mutations were added for the swipe-card gestures (swipe-right toggles status, swipe-left
/// deletes) so the list can write straight through to Firestore without routing every swipe
/// through the heavier `TaskDetailClientAdapting`.
protocol TasksClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchAllTasks() async throws -> [TaskItem]
    /// Write-through status flip for the swipe-to-complete / swipe-to-reopen gesture.
    func setStatus(taskId: UUID, status: TaskStatus) async throws
    /// Hard delete for the swipe-to-delete gesture.
    func deleteTask(taskId: UUID) async throws
}
