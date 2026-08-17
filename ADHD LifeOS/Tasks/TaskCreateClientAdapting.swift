//
//  TaskCreateClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Supabase Postgrest client so `TaskCreateService` is testable without a
/// network. Mirrors the Task Create feature's creation flow: insert the task first, then attach
/// tags — no cross-table transaction available.
protocol TaskCreateClientAdapting: Sendable {
    func fetchTags() async throws -> [Tag]
    func createTag(name: String) async throws -> Tag
    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem
    func attachTags(taskId: UUID, tagIds: [UUID]) async throws
}
