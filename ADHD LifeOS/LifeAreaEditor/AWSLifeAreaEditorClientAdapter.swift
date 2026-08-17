//
//  AWSLifeAreaEditorClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `LifeAreaEditorClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token — the same "thin JSON-over-HTTP" pattern as
/// `AWSTagEditorClientAdapter`. It deliberately does **not** collapse every non-2xx into one failure
/// string the way `AWSHomeClientAdapter` does: this feature's whole conflict flow is built from the
/// `409` body, so this adapter branches on the status code and decodes `409` into a typed
/// `LifeAreaNameConflict` (carrying `archived`), distinguishing it from a `400`/`404`/network error.
/// Every id in a `PATCH` path goes through `UUID.lowercaseUUIDString` because DynamoDB key lookups
/// are case-sensitive and `uuidString` is UPPERCASE (see `LifeOSAPIConfig`) — an uppercase id would
/// `404` against an area that visibly exists.
struct AWSLifeAreaEditorClientAdapter: LifeAreaEditorClientAdapting {
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

    func fetchLifeAreas() async throws -> [EditableLifeArea] {
        let (data, status) = try await perform(path: "life-areas", method: "GET", body: nil)
        guard status == 200 else { throw error(from: data, status: status) }
        let envelope = try decode(LifeAreasEnvelope.self, from: data)
        return envelope.lifeAreas.map {
            EditableLifeArea(
                id: $0.id, name: $0.name, colour: $0.colour, sortOrder: $0.sortOrder, archived: $0.archived
            )
        }
    }

    func update(id: UUID, name: String?, colour: String?) async throws -> LifeAreaUpdateOutcome {
        let (data, status) = try await perform(
            path: "life-areas/\(id.lowercaseUUIDString)",
            method: "PATCH",
            body: try JSONEncoder().encode(UpdateRequestBody(name: name, colour: colour))
        )
        switch status {
        case 200:
            return .updated
        case 409:
            return .nameConflict(try conflict(from: data))
        default:
            throw error(from: data, status: status)
        }
    }

    func setArchived(id: UUID, archived: Bool) async throws {
        let (data, status) = try await perform(
            path: "life-areas/\(id.lowercaseUUIDString)",
            method: "PATCH",
            body: try JSONEncoder().encode(ArchivedRequestBody(archived: archived))
        )
        guard status == 200 else { throw error(from: data, status: status) }
    }

    func create(name: String, colour: String) async throws -> LifeAreaCreateOutcome {
        let (data, status) = try await perform(
            path: "life-areas",
            method: "POST",
            body: try JSONEncoder().encode(CreateRequestBody(name: name, colour: colour))
        )
        switch status {
        case 201:
            let dto = try decode(LifeAreaDTO.self, from: data)
            return .created(
                EditableLifeArea(
                    id: dto.id, name: dto.name, colour: dto.colour, sortOrder: dto.sortOrder, archived: dto.archived
                )
            )
        case 409:
            return .nameConflict(try conflict(from: data))
        default:
            throw error(from: data, status: status)
        }
    }

    // MARK: - HTTP

    /// One request → `(body, statusCode)`. Returns the status code so each caller can branch on it
    /// (200 vs 201 vs 409). Only transport-level errors throw here; an HTTP error status is returned
    /// for the caller to interpret.
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
                throw LifeAreaEditorServiceError.failed("The Life Areas service returned an unexpected response.")
            }
            return (data, http.statusCode)
        } catch let error as LifeAreaEditorServiceError {
            throw error
        } catch {
            throw LifeAreaEditorServiceError.failed(Self.message(for: error))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw LifeAreaEditorServiceError.failed("The Life Areas service returned data it couldn't read.")
        }
    }

    private func conflict(from data: Data) throws -> LifeAreaNameConflict {
        let envelope = try decode(ConflictEnvelope.self, from: data)
        return LifeAreaNameConflict(
            id: envelope.conflict.id, name: envelope.conflict.name, archived: envelope.conflict.archived
        )
    }

    /// Turn a non-success HTTP status into a readable error, preferring the backend's
    /// `{"error": "..."}` body (populated for every failure since the block-2 diagnostic fix).
    private func error(from data: Data, status: Int) -> LifeAreaEditorServiceError {
        if let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data), !decoded.error.isEmpty {
            return .failed(decoded.error)
        }
        return .failed("The Life Areas service returned an error (HTTP \(status)).")
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

// MARK: - Wire types (private per this migration's per-file-private-DTO precedent)

private struct LifeAreasEnvelope: Decodable {
    let lifeAreas: [LifeAreaDTO]
}

private struct LifeAreaDTO: Decodable {
    let id: UUID
    let name: String
    let colour: String
    let sortOrder: Int
    let archived: Bool
}

private struct ConflictEnvelope: Decodable {
    let conflict: ConflictDTO
}

private struct ConflictDTO: Decodable {
    let id: UUID
    let name: String
    let archived: Bool
}

private struct ErrorBody: Decodable {
    let error: String
}

private struct UpdateRequestBody: Encodable {
    let name: String?
    let colour: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let name { try container.encode(name, forKey: .name) }
        if let colour { try container.encode(colour, forKey: .colour) }
    }

    private enum CodingKeys: String, CodingKey {
        case name, colour
    }
}

private struct ArchivedRequestBody: Encodable {
    let archived: Bool
}

private struct CreateRequestBody: Encodable {
    let name: String
    let colour: String
}
