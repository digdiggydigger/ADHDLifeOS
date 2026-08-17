//
//  SupabaseTaskDetailClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `TaskDetailClientAdapting` backed by `supabase-swift`'s `PostgrestClient`. Mirrors
/// `SupabaseTaskCreateClientAdapter`'s auth-refresh-before-query pattern. RLS's `WITH CHECK` on
/// INSERT validates `user_id` but does not populate it — no column default, no `BEFORE INSERT`
/// trigger exists (`ARCHITECTURE.md` §4) — so `createTag` sets `user_id` explicitly from the
/// freshly-fetched session. `addTagToTask`'s `task_tags` insert is the one exception: that table
/// has no `user_id` column at all — its INSERT policy scopes via a join back to
/// `tasks.user_id`/`tags.user_id`, so there is no column to set (same as
/// `SupabaseTaskCreateClientAdapter.attachTags`). Reads/updates still never filter by `user_id`
/// manually — RLS's `USING` clause auto-scopes those.
struct SupabaseTaskDetailClientAdapter: TaskDetailClientAdapting {
    private static let taskColumns = "id,life_area_id,title,notes,status,priority,due_date,created_at"

    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func fetchTask(id: UUID) async throws -> TaskDetail {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("tasks")
                .select(Self.taskColumns)
                .eq("id", value: id)
                .single()
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] {
        do {
            let (client, _) = try await authorizedClient()
            let rows: [TaskTagJoinRow] = try await client
                .from("task_tags")
                .select("tags(id,name)")
                .eq("task_id", value: taskId)
                .execute()
                .value
            return rows.map(\.tags)
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchAllTags() async throws -> [Tag] {
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

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("tasks")
                .update(TaskUpdateEncodablePayload(payload: payload))
                .eq("id", value: id)
                .select(Self.taskColumns)
                .single()
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("tasks")
                .update(StatusUpdatePayload(status: status))
                .eq("id", value: id)
                .select(Self.taskColumns)
                .single()
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
                .insert(TaskDetailTagInsertPayload(name: name, userId: userId))
                .select("id,name")
                .single()
                .execute()
                .value
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func addTagToTask(taskId: UUID, tagId: UUID) async throws {
        do {
            let (client, _) = try await authorizedClient()
            try await client
                .from("task_tags")
                .insert(TaskTagInsertPayload(taskId: taskId, tagId: tagId))
                .execute()
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {
        do {
            let (client, _) = try await authorizedClient()
            try await client
                .from("task_tags")
                .delete()
                .eq("task_id", value: taskId)
                .eq("tag_id", value: tagId)
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

private struct TaskTagJoinRow: Decodable {
    let tags: Tag
}

struct TaskDetailTagInsertPayload: Encodable {
    let name: String
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case name
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

private struct StatusUpdatePayload: Encodable {
    let status: TaskStatus
}

/// Custom `Encodable` so the JSON body only contains the fields that actually changed:
/// `title`/`priority` are omitted entirely when their outer `Optional` is `nil`; `notes`/
/// `lifeAreaId`/`dueDate` encode explicit JSON `null` when the payload's nested optional is
/// `.some(nil)`, distinguishing "clear this field" from "leave it untouched."
private struct TaskUpdateEncodablePayload: Encodable {
    let payload: TaskUpdatePayload

    enum CodingKeys: String, CodingKey {
        case title, notes, priority
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let title = payload.title {
            try container.encode(title, forKey: .title)
        }
        if let notes = payload.notes {
            try container.encode(notes, forKey: .notes)
        }
        if let priority = payload.priority {
            try container.encode(priority, forKey: .priority)
        }
        if let lifeAreaId = payload.lifeAreaId {
            try container.encode(lifeAreaId, forKey: .lifeAreaId)
        }
        if let dueDate = payload.dueDate {
            try container.encode(dueDate, forKey: .dueDate)
        }
    }
}
