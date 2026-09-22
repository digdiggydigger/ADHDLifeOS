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
    /// Soft delete (`F-C3-RecentlyDeleted`). The detail screen owns deletion since
    /// F-V3-Tasks-rebuild (the list's swipe-left is gone) — and since this block it owns a
    /// REVERSIBLE one: the document survives with a `deleted_at` stamp, hidden from every list
    /// for thirty days.
    ///
    /// **There is deliberately no hard delete on this seam any more.** A dormant one would be an
    /// irreversible operation sitting one autocomplete away from a caller who meant this;
    /// `SoftDeleteCallSiteTests` walks the tree to keep it out.
    func softDeleteTask(id: UUID) async throws
    /// The capsule's Undo. Called from a closure that OUTLIVES this screen — `performDelete()`
    /// pops the detail view — so the capsule captures the adapter and the id rather than a
    /// service that is on its way out.
    func restoreTask(id: UUID) async throws
    func createTag(name: String) async throws -> Tag
    func addTagToTask(taskId: UUID, tagId: UUID) async throws
    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws
}
