//
//  SupabaseNudgesClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `NudgesClientAdapting` backed by `supabase-swift`'s `PostgrestClient`. Mirrors prior
/// adapters' auth-refresh-before-query pattern. RLS's `WITH CHECK` on INSERT validates `user_id`
/// but does not populate it — no column default, no `BEFORE INSERT` trigger exists
/// (`ARCHITECTURE.md` §4) — so `createNudge` sets `user_id` explicitly from the freshly-fetched
/// session. Reads/updates still never filter by `user_id` manually — RLS's `USING` clause
/// auto-scopes those.
struct SupabaseNudgesClientAdapter: NudgesClientAdapting {
    private static let nudgeColumns = "id,label,schedule,active,last_fired_at,created_at,updated_at"

    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchNudges() async throws -> [Nudge] {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("nudges")
                .select(Self.nudgeColumns)
                .order("created_at")
                .execute()
                .value
        } catch {
            throw NudgesServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
        do {
            let (client, userId) = try await authorizedClient()
            let payload = NudgeInsertPayload(label: label, schedule: schedule.encode(), active: true, userId: userId)
            return try await client
                .from("nudges")
                .insert(payload)
                .select(Self.nudgeColumns)
                .single()
                .execute()
                .value
        } catch {
            throw NudgesServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("nudges")
                .update(NudgeUpdateEncodablePayload(payload: payload))
                .eq("id", value: id)
                .select(Self.nudgeColumns)
                .single()
                .execute()
                .value
        } catch {
            throw NudgesServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func markFired(id: UUID) async throws -> Nudge {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("nudges")
                .update(NudgeMarkFiredPayload(lastFiredAt: Date()))
                .eq("id", value: id)
                .select(Self.nudgeColumns)
                .single()
                .execute()
                .value
        } catch {
            throw NudgesServiceError.fetchFailed(Self.message(for: error))
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

struct NudgeInsertPayload: Encodable {
    let label: String
    let schedule: String
    let active: Bool
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case label, schedule, active
        case userId = "user_id"
    }
}

private struct NudgeMarkFiredPayload: Encodable {
    let lastFiredAt: Date

    enum CodingKeys: String, CodingKey {
        case lastFiredAt = "last_fired_at"
    }
}

/// Custom `Encodable` so the JSON body only contains the fields that actually changed — `label`/
/// `schedule`/`active` are omitted entirely when their `Optional` is `nil`, matching
/// `NudgeUpdatePayload`'s partial-update semantics.
private struct NudgeUpdateEncodablePayload: Encodable {
    let payload: NudgeUpdatePayload

    enum CodingKeys: String, CodingKey {
        case label, schedule, active
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let label = payload.label {
            try container.encode(label, forKey: .label)
        }
        if let schedule = payload.schedule {
            try container.encode(schedule.encode(), forKey: .schedule)
        }
        if let active = payload.active {
            try container.encode(active, forKey: .active)
        }
    }
}
