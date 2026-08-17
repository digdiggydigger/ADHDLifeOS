//
//  SupabaseCaptureClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation
import PostgREST

/// Production `CaptureClientAdapting` backed by `supabase-swift`'s `PostgrestClient`. Mirrors
/// `SupabaseTaskCreateClientAdapter`'s auth-refresh-before-query pattern. RLS's `WITH CHECK` on
/// INSERT validates `user_id` but does not populate it — no column default, no `BEFORE INSERT`
/// trigger exists (`ARCHITECTURE.md` §4) — so both `createCapture` and `createTask` set `user_id`
/// explicitly from the freshly-fetched session. Reads/the `markProcessed` update still never
/// filter by `user_id` manually — RLS's `USING` clause auto-scopes those.
struct SupabaseCaptureClientAdapter: CaptureClientAdapting {
    private let authClient: AuthClient
    private let postgrestClient: PostgrestClient
    private static let captureColumns = "id,content,kind,processed,created_at"

    init(authClient: AuthClient, postgrestClient: PostgrestClient) {
        self.authClient = authClient
        self.postgrestClient = postgrestClient
    }

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        do {
            let (client, userId) = try await authorizedClient()
            let payload = CaptureInsertPayload(
                content: input.content,
                kind: input.kind,
                processed: false,
                userId: userId
            )
            return try await client
                .from("captures")
                .insert(payload)
                .select(Self.captureColumns)
                .single()
                .execute()
                .value
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("captures")
                .select(Self.captureColumns)
                .eq("processed", value: false)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        do {
            let (client, _) = try await authorizedClient()
            return try await client
                .from("captures")
                .select(Self.captureColumns)
                .eq("id", value: id)
                .single()
                .execute()
                .value
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        do {
            let (client, userId) = try await authorizedClient()
            let payload = CaptureTaskInsertPayload(
                title: input.title,
                lifeAreaId: input.lifeAreaId,
                dueDate: input.dueDate,
                priority: input.priority,
                status: .open,
                source: "capture",
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
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func markProcessed(captureId: UUID) async throws {
        do {
            let (client, _) = try await authorizedClient()
            try await client
                .from("captures")
                .update(CaptureProcessedUpdatePayload(processed: true))
                .eq("id", value: captureId)
                .execute()
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    /// No-op stub — media upload has no Supabase equivalent, and this adapter is no longer the
    /// active capture client (see `AWSCaptureClientAdapter`). Kept only so this file still
    /// compiles, per the stub-and-hide precedent (Stage C.1 magic-link).
    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        throw CaptureServiceError.fetchFailed("Media upload is unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `requestUploadURL`.
    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        throw CaptureServiceError.fetchFailed("Media upload is unavailable on the Supabase adapter.")
    }

    /// No-op stub — triage (Life Area + Tag editing) is AWS-only, same precedent as
    /// `requestUploadURL`.
    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        throw CaptureServiceError.fetchFailed("Updating a capture is unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `updateCapture`.
    func fetchAllTags() async throws -> [Tag] {
        throw CaptureServiceError.fetchFailed("Tags are unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `updateCapture`.
    func createTag(name: String) async throws -> Tag {
        throw CaptureServiceError.fetchFailed("Tags are unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `updateCapture`.
    func fetchTags(captureId: UUID) async throws -> [Tag] {
        throw CaptureServiceError.fetchFailed("Tags are unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `updateCapture`.
    func addTag(captureId: UUID, tagId: UUID) async throws {
        throw CaptureServiceError.fetchFailed("Tags are unavailable on the Supabase adapter.")
    }

    /// No-op stub — see `updateCapture`.
    func removeTag(captureId: UUID, tagId: UUID) async throws {
        throw CaptureServiceError.fetchFailed("Tags are unavailable on the Supabase adapter.")
    }

    private func authorizedClient() async throws -> (client: PostgrestClient, userId: UUID) {
        let session = try await authClient.session
        return (postgrestClient.setAuth(session.accessToken), session.user.id)
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

struct CaptureInsertPayload: Encodable {
    let content: String
    let kind: CaptureKind
    let processed: Bool
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case content, kind, processed
        case userId = "user_id"
    }
}

struct CaptureTaskInsertPayload: Encodable {
    let title: String
    let lifeAreaId: UUID?
    let dueDate: Date?
    let priority: TaskPriority
    let status: TaskStatus
    let source: String
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case title, priority, status, source
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case userId = "user_id"
    }
}

private struct CaptureProcessedUpdatePayload: Encodable {
    let processed: Bool
}
