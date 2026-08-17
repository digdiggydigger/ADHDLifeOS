//
//  AWSHomeClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `HomeClientAdapting` backed by a plain `URLSession` GET against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSAuthClientAdapter`/`AWSRemindersClientAdapter`. Decodes
/// into private DTOs matching the Lambda's actual camelCase field shapes, then maps into the
/// existing, unchanged `LifeArea`/`TaskSummary` models — those still carry the snake_case
/// `CodingKeys` the Supabase adapter needs, which would silently mis-decode this backend's JSON
/// (e.g. `sortOrder` vs `sort_order`) if decoded directly.
struct AWSHomeClientAdapter: HomeClientAdapting {
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

    func fetchLifeAreas() async throws -> [LifeArea] {
        let envelope: LifeAreasEnvelope = try await get(path: "life-areas")
        // Carry `archived` THROUGH — do not filter here. An adapter must not silently delete rows
        // its other callers need: the same over-eager filter here is exactly what starved the
        // Capture triage picker of archived areas. `archived` now lives on the shared `LifeArea`,
        // and the Home grid applies the active-only filter at the view layer. A missing `archived`
        // (the nine seeded rows) reads as not-archived.
        return envelope.lifeAreas.map { dto in
            LifeArea(id: dto.id, name: dto.name, colour: dto.colour, sortOrder: dto.sortOrder,
                     archived: dto.archived ?? false)
        }
    }

    func reorder(order: [UUID]) async throws {
        // TRAP 2: one bulk PATCH — never N per-row writes. TRAP 3: ids lowercased for DynamoDB.
        // TRAP 4: the body is an explicit id-string `Encodable`, never an encoded `LifeArea`.
        let body = try JSONEncoder().encode(ReorderRequestBody(order: LifeAreaReorderPayload.wireIDs(order)))
        _ = try await send(path: "life-areas/reorder", method: "PATCH", httpBody: body)
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        let envelope: TasksEnvelope = try await get(
            path: "tasks",
            queryItems: [URLQueryItem(name: "status", value: "open")]
        )
        return envelope.tasks.map { dto in
            TaskSummary(lifeAreaId: dto.lifeAreaId, status: dto.status)
        }
    }

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let data = try await send(path: path, method: "GET", queryItems: queryItems, httpBody: nil)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HomeServiceError.fetchFailed("The Home service returned data it couldn't read.")
        }
    }

    @discardableResult
    private func send(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        httpBody: Data?
    ) async throws -> Data {
        do {
            let token = try await authClient.validIDToken()

            var components = URLComponents(
                url: baseURL.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            )
            if !queryItems.isEmpty {
                components?.queryItems = queryItems
            }
            guard let url = components?.url else {
                throw HomeServiceError.fetchFailed("Couldn't build the request URL.")
            }

            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if let httpBody {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = httpBody
            }

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HomeServiceError.fetchFailed("The Home service returned an unexpected response.")
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw HomeServiceError.fetchFailed(Self.errorMessage(from: data, status: httpResponse.statusCode))
            }
            return data
        } catch let error as HomeServiceError {
            throw error
        } catch {
            throw HomeServiceError.fetchFailed(Self.message(for: error))
        }
    }

    /// Prefer the backend's `{"error": "..."}` body (populated for every failure) so a failed
    /// reorder surfaces a readable reason rather than a raw HTTP code or decoding error.
    private static func errorMessage(from data: Data, status: Int) -> String {
        if let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data), !decoded.error.isEmpty {
            return decoded.error
        }
        return "The Home service returned an unexpected response."
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

private struct LifeAreaDTO: Decodable {
    let id: UUID
    let name: String
    let colour: String
    let sortOrder: Int
    // Optional so a response without the field (or an older backend) still decodes; absent = false.
    let archived: Bool?
}

/// TRAP 4: the reorder body is an explicit id-string type — never an encoded `LifeArea`.
private struct ReorderRequestBody: Encodable {
    let order: [String]
}

private struct ErrorBody: Decodable {
    let error: String
}

private struct LifeAreasEnvelope: Decodable {
    let lifeAreas: [LifeAreaDTO]
}

private struct TaskSummaryDTO: Decodable {
    let lifeAreaId: UUID?
    let status: TaskStatus
}

private struct TasksEnvelope: Decodable {
    let tasks: [TaskSummaryDTO]
}
