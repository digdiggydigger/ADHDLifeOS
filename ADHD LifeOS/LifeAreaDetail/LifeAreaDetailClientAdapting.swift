//
//  LifeAreaDetailClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

enum LifeAreaDetailServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

/// Thin seam over the Supabase Postgrest client so `LifeAreaDetailService` is testable without a
/// network. Both fetches are scoped server-side to one life area (`life_area_id` equality), not
/// filtered client-side over the full tasks/logs lists.
protocol LifeAreaDetailClientAdapting: Sendable {
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem]
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log]
}
