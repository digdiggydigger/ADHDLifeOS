//
//  AWSTaskDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskDetailClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSTaskCreateClientAdapter`. `updateTask` mirrors the
/// Supabase adapter's encode-if-present/encode-explicit-null semantics with camelCase keys;
/// `updateStatus` reuses the same `PATCH /tasks/{id}` route (the Lambda has one merge-update
/// endpoint, not a dedicated status route). Date parsing (`createdAt`/`dueDate`) tries
/// fractional-seconds ISO8601, then standard ISO8601, then a bare `"yyyy-MM-dd'T'HH:mm:ss"` UTC
/// formatter — the Lambda's `_now_iso()` omits a timezone designator on every `createdAt` it
/// writes, confirmed live (`'2026-07-23T04:47:46'`, no `Z`/offset suffix).
struct AWSTaskDetailClientAdapter: TaskDetailClientAdapting {
    private let session: URLSession
    private let baseURL: URL
    private let authClient: AuthClientAdapting

    init(
        authClient: AuthClientAdapting,
        session: URLSession = .shared,
        baseURL: URL = LifeOSAPIConfig.baseURL
    ) {
        self.authClient = authClient
        self.session = session
        self.baseURL = baseURL
    }

    func fetchTask(id: UUID) async throws -> TaskDetail {
        let dto: TaskDetailDTO = try await get(path: "tasks/\(id.lowercaseUUIDString)")
        return dto.taskDetail
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] {
        let envelope: TagsEnvelope = try await get(path: "tasks/\(taskId.lowercaseUUIDString)/tags")
        return envelope.tags
    }

    func fetchAllTags() async throws -> [Tag] {
        let envelope: TagsEnvelope = try await get(path: "tags")
        return envelope.tags
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        let dto: TaskDetailDTO = try await patch(
            path: "tasks/\(id.lowercaseUUIDString)",
            body: UpdateTaskRequestBody(payload: payload)
        )
        return dto.taskDetail
    }

    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        let dto: TaskDetailDTO = try await patch(
            path: "tasks/\(id.lowercaseUUIDString)",
            body: StatusUpdateRequestBody(status: status)
        )
        return dto.taskDetail
    }

    func createTag(name: String) async throws -> Tag {
        try await post(path: "tags", body: CreateTagRequestBody(name: name))
    }

    func addTagToTask(taskId: UUID, tagId: UUID) async throws {
        try await sendNoContent(
            path: "tasks/\(taskId.lowercaseUUIDString)/tags",
            method: "POST",
            httpBody: try JSONEncoder().encode(AttachTagRequestBody(tagId: tagId))
        )
    }

    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {
        try await sendNoContent(
            path: "tasks/\(taskId.lowercaseUUIDString)/tags/\(tagId.lowercaseUUIDString)",
            method: "DELETE",
            httpBody: nil
        )
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        try await send(path: path, method: "GET", httpBody: nil)
    }

    private func post<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        try await send(path: path, method: "POST", httpBody: try JSONEncoder().encode(body))
    }

    private func patch<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        try await send(path: path, method: "PATCH", httpBody: try JSONEncoder().encode(body))
    }

    private func send<T: Decodable>(path: String, method: String, httpBody: Data?) async throws -> T {
        let data = try await requestData(path: path, method: method, httpBody: httpBody)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private func sendNoContent(path: String, method: String, httpBody: Data?) async throws {
        _ = try await requestData(path: path, method: method, httpBody: httpBody)
    }

    private func requestData(path: String, method: String, httpBody: Data?) async throws -> Data {
        do {
            let token = try await authClient.validIDToken()

            var request = URLRequest(url: baseURL.appendingPathComponent(path))
            request.httpMethod = method
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let httpBody {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = httpBody
            }

            let (data, response) = try await session.data(for: request)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                throw TasksServiceError.fetchFailed("The Tasks service returned an unexpected response.")
            }
            return data
        } catch let error as TasksServiceError {
            throw error
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

private struct TagsEnvelope: Decodable {
    let tags: [Tag]
}

private struct CreateTagRequestBody: Encodable {
    let name: String
}

private struct AttachTagRequestBody: Encodable {
    let tagId: UUID

    private enum CodingKeys: String, CodingKey {
        case tagId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagId.lowercaseUUIDString, forKey: .tagId)
    }
}

private struct StatusUpdateRequestBody: Encodable {
    let status: TaskStatus
}

/// Mirrors `SupabaseTaskDetailClientAdapter`'s `TaskUpdateEncodablePayload`: outer `nil` on a
/// `TaskUpdatePayload` field omits the key entirely ("unchanged"); a nested `.some(nil)` encodes
/// explicit JSON `null` ("clear this field") by encoding the inner `Optional` value directly —
/// `Optional`'s own conditional `Encodable` conformance writes `null` for `.none`. `title`/
/// `priority` are single-level optionals (never nullable server-side), so they're only ever
/// omitted or encoded with a value, never explicitly nulled.
private struct UpdateTaskRequestBody: Encodable {
    let payload: TaskUpdatePayload

    private enum CodingKeys: String, CodingKey {
        case title, notes, priority
        case lifeAreaId, dueDate
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
            let dueDateString: String? = dueDate.map(AWSTaskDetailDateFormatting.outgoing.string(from:))
            try container.encode(dueDateString, forKey: .dueDate)
        }
    }
}

/// Duplicated from `AWSTaskCreateClientAdapter`'s equivalent DTO per this migration's established
/// per-file-private-DTO precedent (Stage C.3/C.4) — not shared, to avoid an undiscussed
/// access-scope change to a small struct. Wraps `TaskDetail` construction so `fetchTask`/
/// `updateTask`/`updateStatus` share one decode path.
private struct TaskDetailDTO: Decodable {
    let taskDetail: TaskDetail

    private enum CodingKeys: String, CodingKey {
        case id, lifeAreaId, title, notes, status, priority, dueDate, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let lifeAreaId = try container.decodeIfPresent(UUID.self, forKey: .lifeAreaId)
        let title = try container.decode(String.self, forKey: .title)
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let status = try container.decode(TaskStatus.self, forKey: .status)
        let priority = try container.decode(TaskPriority.self, forKey: .priority)
        let dueDateRaw = try container.decodeIfPresent(String.self, forKey: .dueDate)
        let dueDate = dueDateRaw.flatMap(AWSTaskDetailDateFormatting.parse)

        let createdAtRaw = try container.decode(String.self, forKey: .createdAt)
        guard let createdAt = AWSTaskDetailDateFormatting.parse(createdAtRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: container,
                debugDescription: "createdAt \"\(createdAtRaw)\" did not match any known date format."
            )
        }

        taskDetail = TaskDetail(
            id: id, lifeAreaId: lifeAreaId, title: title, notes: notes, status: status,
            priority: priority, dueDate: dueDate, createdAt: createdAt
        )
    }
}

/// Three-fallback parser: fractional-seconds ISO8601, then standard ISO8601 (with `Z`/offset),
/// then a bare `"yyyy-MM-dd'T'HH:mm:ss"` UTC formatter for the Lambda's timezone-designator-less
/// `_now_iso()` output. Applies to both `createdAt` (always the bare format today) and `dueDate`
/// (kept tolerant of all three, matching Stage C.3's precedent of never throwing on a
/// parseable-but-odd date). If `_now_iso()` ever gains a `Z` suffix, the standard-ISO8601
/// fallback already covers it — no adapter change needed either direction.
private enum AWSTaskDetailDateFormatting {
    static func parse(_ string: String) -> Date? {
        withFractionalSeconds.date(from: string)
            ?? standard.date(from: string)
            ?? bare.date(from: string)
    }

    static let outgoing: ISO8601DateFormatter = withFractionalSeconds

    private static let standard = ISO8601DateFormatter()
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let bare: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
