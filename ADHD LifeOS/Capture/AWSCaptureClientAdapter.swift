//
//  AWSCaptureClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `CaptureClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSTaskDetailClientAdapter`/`AWSTaskCreateClientAdapter`.
/// `createdAt` decodes via the same tolerant fractional/standard/bare ISO8601 parser as
/// `AWSTaskDetailClientAdapter` (the Lambda's `_now_iso()` omits a timezone designator).
/// `createTask` reuses `POST /tasks` (the same route `AWSTaskCreateClientAdapter` calls) and must
/// send `"source":"capture"` explicitly — the Lambda defaults an absent `source` to `"manual"`.
struct AWSCaptureClientAdapter: CaptureClientAdapting {
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

    func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
        let body = CreateCaptureRequestBody(
            content: input.content,
            kind: input.kind,
            title: input.title,
            lifeAreaId: input.lifeAreaId,
            mediaKey: input.mediaKey,
            mediaContentType: input.mediaContentType,
            thumbnailKey: input.thumbnailKey
        )
        let dto: CaptureDTO = try await post(path: "captures", body: body)
        return dto.capture
    }

    func fetchUnprocessedCaptures() async throws -> [Capture] {
        let envelope: CapturesEnvelope = try await get(
            path: "captures", queryItems: [URLQueryItem(name: "processed", value: "false")]
        )
        return envelope.captures.map(\.capture)
    }

    func fetchCapture(id: UUID) async throws -> Capture {
        let dto: CaptureDTO = try await get(path: "captures/\(id.lowercaseUUIDString)")
        return dto.capture
    }

    func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
        let body = CreateCaptureTaskRequestBody(
            title: input.title,
            lifeAreaId: input.lifeAreaId,
            dueDate: input.dueDate.map(Self.dueDateFormatter.string(from:)),
            priority: input.priority,
            source: "capture"
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

    func markProcessed(captureId: UUID) async throws {
        _ = try await patch(
            path: "captures/\(captureId.lowercaseUUIDString)",
            body: StatusUpdateRequestBody(status: .processed)
        ) as CaptureDTO
    }

    func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
        let dto: CaptureDTO = try await patch(
            path: "captures/\(id.lowercaseUUIDString)",
            body: UpdateCaptureRequestBody(changes: changes)
        )
        return dto.capture
    }

    func fetchAllTags() async throws -> [Tag] {
        let envelope: TagsEnvelope = try await get(path: "tags")
        return envelope.tags
    }

    func createTag(name: String) async throws -> Tag {
        try await post(path: "tags", body: CreateTagRequestBody(name: name))
    }

    func fetchTags(captureId: UUID) async throws -> [Tag] {
        let envelope: TagsEnvelope = try await get(path: "captures/\(captureId.lowercaseUUIDString)/tags")
        return envelope.tags
    }

    func addTag(captureId: UUID, tagId: UUID) async throws {
        _ = try await requestData(
            path: "captures/\(captureId.lowercaseUUIDString)/tags",
            method: "POST",
            httpBody: try JSONEncoder().encode(AttachTagRequestBody(tagId: tagId))
        )
    }

    func removeTag(captureId: UUID, tagId: UUID) async throws {
        _ = try await requestData(
            path: "captures/\(captureId.lowercaseUUIDString)/tags/\(tagId.lowercaseUUIDString)",
            method: "DELETE",
            httpBody: nil
        )
    }

    func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
        let dto: UploadURLDTO = try await post(
            path: "captures/upload-url",
            body: UploadURLRequestBody(kind: kind, contentType: contentType)
        )
        guard let uploadURL = URL(string: dto.uploadURL) else {
            throw CaptureServiceError.fetchFailed("The Capture service returned an invalid upload URL.")
        }
        return CaptureUploadTarget(uploadURL: uploadURL, mediaKey: dto.mediaKey, thumbnailKey: dto.thumbnailKey)
    }

    func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {
        do {
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "PUT"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = data

            let (_, response) = try await session.data(for: request)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                throw CaptureServiceError.fetchFailed("The Capture service couldn't upload the media file.")
            }
        } catch let error as CaptureServiceError {
            throw error
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        try await send(path: path, method: "GET", httpBody: nil, queryItems: queryItems)
    }

    private func post<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        try await send(path: path, method: "POST", httpBody: try JSONEncoder().encode(body))
    }

    private func patch<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        try await send(path: path, method: "PATCH", httpBody: try JSONEncoder().encode(body))
    }

    private func send<T: Decodable>(
        path: String, method: String, httpBody: Data?, queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let data = try await requestData(path: path, method: method, httpBody: httpBody, queryItems: queryItems)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private func requestData(
        path: String, method: String, httpBody: Data?, queryItems: [URLQueryItem] = []
    ) async throws -> Data {
        do {
            let token = try await authClient.validIDToken()

            let url = try Self.url(baseURL: baseURL, path: path, queryItems: queryItems)
            var request = URLRequest(url: url)
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
                throw CaptureServiceError.fetchFailed("The Capture service returned an unexpected response.")
            }
            return data
        } catch let error as CaptureServiceError {
            throw error
        } catch {
            throw CaptureServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func url(baseURL: URL, path: String, queryItems: [URLQueryItem]) throws -> URL {
        let pathURL = baseURL.appendingPathComponent(path)
        guard queryItems.isEmpty == false else { return pathURL }
        guard var components = URLComponents(url: pathURL, resolvingAgainstBaseURL: false) else {
            throw CaptureServiceError.fetchFailed("The Capture service request URL was invalid.")
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw CaptureServiceError.fetchFailed("The Capture service request URL was invalid.")
        }
        return url
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

private struct CapturesEnvelope: Decodable {
    let captures: [CaptureDTO]
}

/// Only the fields this block's `createCapture` sends are included on the wire, and only when
/// present — matching `AWSTaskCreateClientAdapter`'s "omit absent optionals, don't send null"
/// precedent.
private struct CreateCaptureRequestBody: Encodable {
    let content: String
    let kind: CaptureKind
    let title: String?
    let lifeAreaId: UUID?
    let mediaKey: String?
    let mediaContentType: String?
    let thumbnailKey: String?

    private enum CodingKeys: String, CodingKey {
        case content, kind, title, lifeAreaId, mediaKey, mediaContentType, thumbnailKey
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(kind, forKey: .kind)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(lifeAreaId, forKey: .lifeAreaId)
        try container.encodeIfPresent(mediaKey, forKey: .mediaKey)
        try container.encodeIfPresent(mediaContentType, forKey: .mediaContentType)
        try container.encodeIfPresent(thumbnailKey, forKey: .thumbnailKey)
    }
}

private struct CreateCaptureTaskRequestBody: Encodable {
    let title: String
    let lifeAreaId: UUID?
    let dueDate: String?
    let priority: TaskPriority
    let source: String

    private enum CodingKeys: String, CodingKey {
        case title, lifeAreaId, dueDate, priority, source
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(lifeAreaId, forKey: .lifeAreaId)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(source, forKey: .source)
    }
}

private struct StatusUpdateRequestBody: Encodable {
    let status: CaptureStatus
}

/// Mirrors `AWSTaskDetailClientAdapter`'s `UpdateTaskRequestBody`: outer `nil` on a `CaptureUpdate`
/// field omits the key entirely ("unchanged"); `lifeAreaId`'s nested `.some(nil)` encodes explicit
/// JSON `null` ("clear this field") via `Optional`'s own conditional `Encodable` conformance.
private struct UpdateCaptureRequestBody: Encodable {
    let changes: CaptureUpdate

    private enum CodingKeys: String, CodingKey {
        case status, lifeAreaId, title
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let status = changes.status {
            try container.encode(status, forKey: .status)
        }
        if let title = changes.title {
            try container.encode(title, forKey: .title)
        }
        if let lifeAreaId = changes.lifeAreaId {
            try container.encode(lifeAreaId, forKey: .lifeAreaId)
        }
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

private struct UploadURLRequestBody: Encodable {
    let kind: CaptureKind
    let contentType: String
}

private struct UploadURLDTO: Decodable {
    let uploadURL: String
    let mediaKey: String
    let thumbnailKey: String?

    private enum CodingKeys: String, CodingKey {
        case uploadURL = "uploadUrl"
        case mediaKey, thumbnailKey
    }
}

/// Mirrors `AWSTaskCreateClientAdapter`'s private `TaskItemDTO`, duplicated per that block's own
/// per-file-private-DTO precedent rather than shared.
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
        dueDate = dueDateRaw.flatMap(AWSCaptureDateFormatting.parse)
    }
}

/// Own private DTO (camelCase, per-file-private-DTO precedent — not shared with the Supabase
/// model's snake_case `CodingKeys`). Decodes the AWS capture shape into `Capture`, including
/// tolerant `createdAt` parsing and the optional media/status/link-preview fields.
private struct CaptureDTO: Decodable {
    let capture: Capture

    private enum CodingKeys: String, CodingKey {
        case id, content, kind, status, processed, createdAt, title, lifeAreaId, aiAssessment
        case mediaURL = "mediaUrl"
        case mediaContentType
        case thumbnailURL = "thumbnailUrl"
        case linkPreview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let content = try container.decode(String.self, forKey: .content)
        let kind = try container.decode(CaptureKind.self, forKey: .kind)
        let processed = try container.decode(Bool.self, forKey: .processed)
        let title = try container.decodeIfPresent(String.self, forKey: .title)
        let status = try container.decodeIfPresent(CaptureStatus.self, forKey: .status)
        let lifeAreaId = try container.decodeIfPresent(UUID.self, forKey: .lifeAreaId)
        let aiAssessment = try container.decodeIfPresent(String.self, forKey: .aiAssessment)
        let mediaURL = try container.decodeIfPresent(URL.self, forKey: .mediaURL)
        let mediaContentType = try container.decodeIfPresent(String.self, forKey: .mediaContentType)
        let thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        let linkPreview = try container.decodeIfPresent(CaptureLinkPreviewDTO.self, forKey: .linkPreview)

        let createdAtRaw = try container.decode(String.self, forKey: .createdAt)
        guard let createdAt = AWSCaptureDateFormatting.parse(createdAtRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: container,
                debugDescription: "createdAt \"\(createdAtRaw)\" did not match any known date format."
            )
        }

        capture = Capture(
            id: id, content: content, kind: kind, processed: processed, createdAt: createdAt,
            title: title, status: status, lifeAreaId: lifeAreaId, mediaURL: mediaURL,
            mediaContentType: mediaContentType, thumbnailURL: thumbnailURL,
            linkPreview: linkPreview?.linkPreview, aiAssessment: aiAssessment
        )
    }
}

private struct CaptureLinkPreviewDTO: Decodable {
    let linkPreview: CaptureLinkPreview

    private enum CodingKeys: String, CodingKey {
        case url, title, description
        case thumbnailURL = "thumbnailUrl"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        linkPreview = CaptureLinkPreview(
            url: try container.decode(String.self, forKey: .url),
            title: try container.decodeIfPresent(String.self, forKey: .title),
            description: try container.decodeIfPresent(String.self, forKey: .description),
            thumbnailURL: try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        )
    }
}

/// Three-fallback parser, duplicated from `AWSTaskDetailClientAdapter`'s equivalent per this
/// migration's established per-file-private-DTO precedent.
private enum AWSCaptureDateFormatting {
    static func parse(_ string: String) -> Date? {
        withFractionalSeconds.date(from: string)
            ?? standard.date(from: string)
            ?? bare.date(from: string)
    }

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
