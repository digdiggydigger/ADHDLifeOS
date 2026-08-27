//
//  TaskDetailClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Supabase Postgrest client so `TaskDetailService` is testable without a
/// network. Status toggles and tag add/remove are separate, immediately-applied operations —
/// `updateTask` only ever carries the staged title/life-area/priority/due-date/notes fields.
protocol TaskDetailClientAdapting: Sendable {
    func fetchTask(id: UUID) async throws -> TaskDetail
    func fetchTagsForTask(taskId: UUID) async throws -> [Tag]
    func fetchAllTags() async throws -> [Tag]
    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail
    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail
    /// Hard delete — the detail screen owns deletion since F-V3-Tasks-rebuild (the list's
    /// swipe-left is gone).
    func deleteTask(id: UUID) async throws
    func createTag(name: String) async throws -> Tag
    func addTagToTask(taskId: UUID, tagId: UUID) async throws
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws
}
