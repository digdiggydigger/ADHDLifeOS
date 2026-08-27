//
//  TasksClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the tasks backend so `TasksService` is testable without a network. The one
/// mutation exists for the row's close affordances (tap-circle and swipe-right) so the list can
/// write straight through to Firestore without routing every close through the heavier
/// `TaskDetailClientAdapting`. Delete moved to the detail adapter in F-V3-Tasks-rebuild, and
/// closing is one-way — the service only ever sends `.done`.
protocol TasksClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchAllTasks() async throws -> [TaskItem]
    /// Write-through close for the row's tap-circle / swipe-right gesture.
    func setStatus(taskId: UUID, status: TaskStatus) async throws
}
