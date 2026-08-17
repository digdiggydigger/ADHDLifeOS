//
//  SupabaseTaskCreateClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `TaskCreateClientAdapting` backed by `supabase-swift`'s `PostgrestClient`. Mirrors
/// `SupabaseTasksClientAdapter`'s auth-refresh-before-query pattern. RLS's `WITH CHECK` on INSERT
/// validates `user_id` but does not populate it — no column default, no `BEFORE INSERT` trigger
/// exists (`ARCHITECTURE.md` §4) — so `createTag` and `createTask` set `user_id` explicitly from
/// the freshly-fetched session. `attachTags`' `task_tags` insert is the one exception: that table
/// has no `user_id` column at all (confirmed live via Supabase MCP) — its INSERT policy scopes
/// via a `WITH CHECK` join back to `tasks.user_id`/`tags.user_id`, so there is no column to set.
/// `fetchTags` still never filters by `user_id` manually — RLS's `USING` clause auto-scopes reads.
struct SupabaseTaskCreateClientAdapter: TaskCreateClientAdapting {
    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchTags() async throws -> [Tag] {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("tags")
                .select("id,name")
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createTag(name: String) async throws -> Tag {
        do {
            let (client, userId) = try await authorizedClient()
            return try await client
                .from("tags")
                .insert(TagInsertPayload(name: name, userId: userId))
                .select("id,name")
                .single()
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem {
        do {
            let (client, userId) = try await authorizedClient()
            let payload = TaskInsertPayload(
                title: input.title,
                notes: input.notes,
                lifeAreaId: input.lifeAreaId,
                dueDate: input.dueDate,
                priority: input.priority,
                status: .open,
                source: "manual",
                userId: userId
            )
            return try await client
                .from("tasks")
                .insert(payload)
                .select("id,life_area_id,title,status,priority,due_date")
                .single()
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {
        do {
            let (client, _) = try await authorizedClient()
            let payloads = tagIds.map { TaskTagInsertPayload(taskId: taskId, tagId: $0) }
            try await client
                .from("task_tags")
                .insert(payloads)
                .execute()
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
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

struct TagInsertPayload: Encodable {
    let name: String
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case userId = "user_id"
    }
}

struct TaskInsertPayload: Encodable {
    let title: String
    let notes: String?
    let lifeAreaId: UUID?
    let dueDate: Date?
    let priority: TaskPriority
    let status: TaskStatus
    let source: String
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case title, notes, priority, status, source
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case userId = "user_id"
    }
}

private struct TaskTagInsertPayload: Encodable {
    let taskId: UUID
    let tagId: UUID

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case tagId = "tag_id"
    }
}
