//
//  HomeClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Home backend so `HomeService` is testable without a network.
protocol HomeClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchOpenTasks() async throws -> [TaskSummary]
    /// `PATCH /life-areas/reorder` — one bulk write of the COMPLETE ordering (active-first, then
    /// archived). TRAP 1: the archived ids must be included or `validate_reorder` 400s on
    /// set-equality. TRAP 2: one call, never N per-row PATCHes.
    func reorder(order: [UUID]) async throws
}
