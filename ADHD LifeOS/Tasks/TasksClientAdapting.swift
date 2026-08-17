//
//  TasksClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Supabase Postgrest client so `TasksService` is testable without a network.
protocol TasksClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchAllTasks() async throws -> [TaskItem]
}
