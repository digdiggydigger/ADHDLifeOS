//
//  SupabaseJournalClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `JournalClientAdapting` backed by `supabase-swift`'s `PostgrestClient`. Mirrors
/// prior adapters' auth-refresh-before-query pattern. RLS's `WITH CHECK` on INSERT validates
/// `user_id` but does not populate it — no column default, no `BEFORE INSERT` trigger exists
/// (`ARCHITECTURE.md` §4) — so `createLog` sets `user_id` explicitly from the freshly-fetched
/// session, fetched immediately before the insert. Reads/updates still never filter by
/// `user_id` manually — RLS's `USING` clause auto-scopes those. `createLog`'s insert payload
/// omits `entry_date` entirely — it defaults to "now" server-side, matching web's `createLog`'s
/// `input.entryDate ?? now` and its composer's lack of a date picker.
struct SupabaseJournalClientAdapter: JournalClientAdapting {
    private static let logColumns = "id,life_area_id,type,body,entry_date,created_at"

    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("life_areas")
                .select("id,name,colour,sort_order")
                .order("sort_order")
                .execute()
                .value
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLogs() async throws -> [Log] {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("logs")
                .select(Self.logColumns)
                .order("entry_date", ascending: false)
                .execute()
                .value
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log {
        do {
            let (client, userId) = try await authorizedClient()
            let payload = LogInsertPayload(
                body: input.body,
                type: input.type,
                lifeAreaId: input.lifeAreaId,
                userId: userId
            )
            return try await client
                .from("logs")
                .insert(payload)
                .select(Self.logColumns)
                .single()
                .execute()
                .value
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private func authorizedClient() async throws -> (client: PostgrestClient, userId: UUID) {
        let session = try await authClient.session
        return (postgrestClient.setAuth(session.accessToken), session.user.id)
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

struct LogInsertPayload: Encodable {
    let body: String
    let type: LogType
    let lifeAreaId: UUID?
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case body, type
        case lifeAreaId = "life_area_id"
        case userId = "user_id"
    }
}
