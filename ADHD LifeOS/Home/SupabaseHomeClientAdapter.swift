//
//  SupabaseHomeClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `HomeClientAdapting` backed by `supabase-swift`'s `PostgrestClient`, authorized
/// per request with the current Supabase Auth session's access token — RLS requires it.
struct SupabaseHomeClientAdapter: HomeClientAdapting {
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
            throw HomeServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        do {
            let client = try await authorizedClient()
            return try await client
                .from("tasks")
                .select("life_area_id,status")
                .eq("status", value: "open")
                .execute()
                .value
        } catch {
            throw HomeServiceError.fetchFailed(Self.message(for: error))
        }
    }

    /// The legacy Supabase path is dead — no code constructs `SupabaseHomeClientAdapter` anywhere
    /// (the app wires `AWSHomeClientAdapter`). Reorder is an AWS-only route, so rather than build a
    /// Supabase `sort_order` write that would never run, this throws a clear unsupported error.
    func reorder(order: [UUID]) async throws {
        throw HomeServiceError.fetchFailed("Reordering life areas is not supported on the legacy Supabase path.")
    }

    private func authorizedClient() async throws -> PostgrestClient {
        let session = try await authClient.session
        return postgrestClient.setAuth(session.accessToken)
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
