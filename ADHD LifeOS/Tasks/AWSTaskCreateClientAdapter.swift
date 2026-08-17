//
//  AWSTaskCreateClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskCreateClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSTasksClientAdapter`. `dueDate` is sent as a
/// fractional-seconds ISO8601 string, matching what `AWSTasksClientAdapter`'s tolerant parser
/// round-trips. The Lambda has no batch tag-attach route, so `attachTags` issues one request per
/// tag id, attempting every id even if one fails so `TaskCreateService`'s existing "couldn't
/// attach one or more tags" warning still fires correctly on any failure.
struct AWSTaskCreateClientAdapter: TaskCreateClientAdapting {
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

    func fetchTags() async throws -> [Tag] {
        let envelope: TagsEnvelope = try await get(path: "tags")
        return envelope.tags
    }

    func createTag(name: String) async throws -> Tag {
        try await post(path: "tags", body: CreateTagRequestBody(name: name))
    }

    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem {
        let body = CreateTaskRequestBody(
            title: input.title,
            notes: input.notes,
            lifeAreaId: input.lifeAreaId,
            dueDate: input.dueDate.map(Self.dueDateFormatter.string(from:)),
            priority: input.priority
        )
        let dto: TaskItemDTO = try await post(path: "tasks", body: body)
        return TaskItem(
            id: dto.id,
            lifeAreaId: dto.lifeAreaId,
            title: dto.title,
            status: dto.status,
            priority: dto.priority,
            dueDate: dto.dueDate
        )
    }

    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {
        var firstError: Error?
        for tagId in tagIds {
            do {
                let _: AttachTagResponse = try await post(
                    path: "tasks/\(taskId.lowercaseUUIDString)/tags",
                    body: AttachTagRequestBody(tagId: tagId)
                )
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError {
            throw firstError
        }
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        try await send(path: path, method: "GET", httpBody: nil)
    }

    private func post<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        let httpBody = try JSONEncoder().encode(body)
        return try await send(path: path, method: "POST", httpBody: httpBody)
    }

    private func send<T: Decodable>(path: String, method: String, httpBody: Data?) async throws -> T {
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

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as TasksServiceError {
            throw error
        } catch {
            throw TasksServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private static let dueDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
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

private struct AttachTagResponse: Decodable {
    let taskId: String?
    let tagId: String?
}

/// `notes`/`lifeAreaId`/`dueDate` are only written to the outgoing JSON when non-nil — the
/// Lambda treats an absent key and an explicit `null` the same way, but omitting keeps the wire
/// body minimal and matches the "createTask with dueDate: nil omits the field" contract this
/// block's Test Plan calls for.
private struct CreateTaskRequestBody: Encodable {
    let title: String
    let notes: String?
    let lifeAreaId: UUID?
    let dueDate: String?
    let priority: TaskPriority

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(lifeAreaId, forKey: .lifeAreaId)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
    }

    private enum CodingKeys: String, CodingKey {
        case title, notes, lifeAreaId, dueDate, priority
    }
}

/// Mirrors `AWSTasksClientAdapter`'s private `TaskItemDTO`, duplicated per that block's own
/// precedent rather than shared (sharing would require widening one file's access for a small
/// struct, an undiscussed scope change).
private struct TaskItemDTO: Decodable {
    let id: UUID
    let lifeAreaId: UUID?
    let title: String
    let status: TaskStatus
    let priority: TaskPriority
    let dueDate: Date?

    private enum CodingKeys: String, CodingKey {
        case id, lifeAreaId, title, status, priority, dueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        lifeAreaId = try container.decodeIfPresent(UUID.self, forKey: .lifeAreaId)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(TaskStatus.self, forKey: .status)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        let dueDateRaw = try container.decodeIfPresent(String.self, forKey: .dueDate)
        dueDate = dueDateRaw.flatMap(AWSTaskCreateDueDateParsing.parse)
    }
}

private enum AWSTaskCreateDueDateParsing {
    static func parse(_ string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? standard.date(from: string)
    }

    private static let standard = ISO8601DateFormatter()
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
