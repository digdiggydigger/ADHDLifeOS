//
//  SupabaseTasksClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `TasksClientAdapting` backed by `supabase-swift`'s `PostgrestClient`, authorized
/// per request with the current Supabase Auth session's access token — RLS requires it. Mirrors
/// `SupabaseHomeClientAdapter`'s auth-refresh-before-query pattern.
struct SupabaseTasksClientAdapter: TasksClientAdapting {
    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        do {
            let client = try await authorizedClient()
            return try await client
                .from("life_areas")
                .select("id,name,colour,sort_order")
                .order("sort_order")
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        do {
            let client = try await authorizedClient()
            return try await client
                .from("tasks")
                .select("id,life_area_id,title,status,priority,due_date")
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
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
