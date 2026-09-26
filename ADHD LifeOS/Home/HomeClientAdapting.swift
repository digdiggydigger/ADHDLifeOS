//
//  HomeClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over the Home backend so `HomeService` is testable without a network.
protocol HomeClientAdapting: Sendable {
    func fetchLifeAreas() async throws -> [LifeArea]
    func fetchOpenTasks() async throws -> [TaskSummary]
    /// Every task including closed ones — the Momentum scoreboard derives the closure ring,
    /// streak and per-area weekly rates from `completed_at` stamps client-side.
    func fetchAllTasks() async throws -> [TaskItem]
}
