//
//  TasksClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the tasks backend so `TasksService` is testable without a network. The one
/// mutation exists for the row's close affordances (tap-circle and swipe-right) so the list can
/// write straight through to Firestore without routing every close through the heavier
/// `TaskDetailClientAdapting`. Delete moved to the detail adapter in F-V3-Tasks-rebuild.
///
/// **`setStatus` sends `.open` as well as `.done` since `F-C1-UndoCapsule`** (2026-09-20) — the
/// undo capsule's `TasksService.reopen(_:)` writes through the same seam, so "closing is one-way"
/// no longer describes this protocol.
protocol TasksClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchAllTasks() async throws -> [TaskItem]
    /// Write-through close for the row's tap-circle / swipe-right gesture.
    func setStatus(taskId: UUID, status: TaskStatus) async throws
}
