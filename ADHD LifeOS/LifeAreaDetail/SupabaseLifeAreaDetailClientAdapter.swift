//
//  SupabaseLifeAreaDetailClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `LifeAreaDetailClientAdapting` backed by `supabase-swift`'s `PostgrestClient`.
/// Mirrors `SupabaseTasksClientAdapter`/`SupabaseJournalClientAdapter`'s auth-refresh-before-query
/// pattern. Read-only screen — no inserts, so `authorizedClient()` only needs the Postgrest
/// client, not the session's `userId`.
struct SupabaseLifeAreaDetailClientAdapter: LifeAreaDetailClientAdapting {
    private static let taskColumns = "id,life_area_id,title,status,priority,due_date"
    private static let logColumns = "id,life_area_id,type,body,entry_date,created_at"

    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        do {
            let client = try await authorizedClient()
            return try await client
                .from("tasks")
                .select(Self.taskColumns)
                .eq("life_area_id", value: lifeAreaId)
                .execute()
                .value
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        do {
            let client = try await authorizedClient()
            return try await client
                .from("logs")
                .select(Self.logColumns)
                .eq("life_area_id", value: lifeAreaId)
                .order("entry_date", ascending: false)
                .execute()
                .value
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private func authorizedClient() async throws -> PostgrestClient {
        let session = try await authClient.session
        return postgrestClient.setAuth(session.accessToken)
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
