//
//  RemindersClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

enum RemindersServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

/// Thin seam over the AWS `poke-ios-bridge` HTTP API so `RemindersService` is testable without a
/// network — mirrors the existing `*ClientAdapting` convention used by every Supabase feature.
protocol RemindersClientAdapting: Sendable {
    func fetchReminders() async throws -> [Reminder]
}
