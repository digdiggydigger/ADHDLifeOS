//
//  AWSTagEditorClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TagEditorClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token — same "thin JSON-over-HTTP" pattern as
/// `AWSTaskDetailClientAdapter`. **It deliberately does NOT collapse every non-2xx into one failure
/// string** the way the fetch-only adapters do: this feature's whole merge flow is built from the
/// `409` conflict body, and cascade delete returns a bodyless `204`. So this adapter branches on the
/// status code — decoding `409` into a typed `.needsMerge`, distinguishing `POST /tags`' `201`
/// (created) from `200` (server-side dedup), and treating `204` as success without running an empty
/// body through a decoder. Every tag id in a `PATCH`/`DELETE` path goes through
/// `UUID.lowercaseUUIDString` because DynamoDB key lookups are case-sensitive and `uuidString` is
/// uppercase (see `LifeOSAPIConfig`).
struct AWSTagEditorClientAdapter: TagEditorClientAdapting {
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

    func fetchTags() async throws -> [EditableTag] {
        let (data, status) = try await perform(path: "tags", method: "GET", body: nil)
        guard status == 200 else { throw error(from: data, status: status) }
        let envelope = try decode(TagsWithCountEnvelope.self, from: data)
        return envelope.tags.map { EditableTag(id: $0.id, name: $0.name, usageCount: $0.usageCount) }
    }

    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome {
        let (data, status) = try await perform(
            path: "tags/\(id.lowercaseUUIDString)",
            method: "PATCH",
            body: try JSONEncoder().encode(RenameRequestBody(name: name, onConflict: nil))
        )
        switch status {
        case 200:
            return .renamed
        case 409:
            let envelope = try decode(ConflictEnvelope.self, from: data)
            return .needsMerge(
                TagRenameConflict(
                    id: envelope.conflict.id,
                    name: envelope.conflict.name,
                    usageCount: envelope.conflict.usageCount
                )
            )
        default:
            throw error(from: data, status: status)
        }
    }

    func mergeTag(id: UUID, into name: String) async throws {
        let (data, status) = try await perform(
            path: "tags/\(id.lowercaseUUIDString)",
            method: "PATCH",
            body: try JSONEncoder().encode(RenameRequestBody(name: name, onConflict: "merge"))
        )
        guard status == 200 else { throw error(from: data, status: status) }
    }

    func deleteTag(id: UUID) async throws {
        let (data, status) = try await perform(
            path: "tags/\(id.lowercaseUUIDString)",
            method: "DELETE",
            body: nil
        )
        // 204 No Content carries an empty body — success, and it must NOT be run through a decoder.
        guard (200..<300).contains(status) else { throw error(from: data, status: status) }
    }

    func createTag(name: String) async throws -> TagCreateOutcome {
        let (data, status) = try await perform(
            path: "tags",
            method: "POST",
            body: try JSONEncoder().encode(CreateRequestBody(name: name))
        )
        switch status {
        case 201:
            return .created(try editableTag(fromCreate: data))
        case 200:
            // Server-side dedup: the name was already taken and the existing tag was returned.
            return .alreadyExisted(try editableTag(fromCreate: data))
        default:
            throw error(from: data, status: status)
        }
    }

    // MARK: - HTTP

    /// One request → `(body, statusCode)`. Unlike the fetch-only adapters, this returns the status
    /// code so each caller can branch on it (200 vs 201 vs 204 vs 409). Only transport-level errors
    /// throw here; an HTTP error status is returned for the caller to interpret.
    private func perform(path: String, method: String, body: Data?) async throws -> (Data, Int) {
        do {
            let token = try await authClient.validIDToken()
            var request = URLRequest(url: baseURL.appendingPathComponent(path))
            request.httpMethod = method
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw TagEditorServiceError.failed("The Tag Editor service returned an unexpected response.")
            }
            return (data, http.statusCode)
        } catch let error as TagEditorServiceError {
            throw error
        } catch {
            throw TagEditorServiceError.failed(Self.message(for: error))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TagEditorServiceError.failed("The Tag Editor service returned data it couldn't read.")
        }
    }

    private func editableTag(fromCreate data: Data) throws -> EditableTag {
        // `POST /tags` returns the raw tag (`id`/`name`) with no counts — a freshly created tag has
        // zero usage, and for the dedup case the service reloads for the real count anyway.
        let dto = try decode(CreatedTagDTO.self, from: data)
        return EditableTag(id: dto.id, name: dto.name, usageCount: 0)
    }

    /// Turn a non-success HTTP status into a readable `TagEditorServiceError`, preferring the
    /// backend's `{"error": "..."}` body (now populated for every failure since the block-2 fix).
    private func error(from data: Data, status: Int) -> TagEditorServiceError {
        if let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data), !decoded.error.isEmpty {
            return .failed(decoded.error)
        }
        return .failed("The Tag Editor service returned an error (HTTP \(status)).")
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

// MARK: - Wire types (private per this migration's per-file-private-DTO precedent)

private struct TagsWithCountEnvelope: Decodable {
    let tags: [TagWithCountDTO]
}

private struct TagWithCountDTO: Decodable {
    let id: UUID
    let name: String
    let usageCount: Int
}

private struct CreatedTagDTO: Decodable {
    let id: UUID
    let name: String
}

private struct ConflictEnvelope: Decodable {
    let conflict: ConflictDTO
}

private struct ConflictDTO: Decodable {
    let id: UUID
    let name: String
    let usageCount: Int
}

private struct ErrorBody: Decodable {
    let error: String
}

private struct RenameRequestBody: Encodable {
    let name: String
    let onConflict: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if let onConflict {
            try container.encode(onConflict, forKey: .onConflict)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name, onConflict
    }
}

private struct CreateRequestBody: Encodable {
    let name: String
}
