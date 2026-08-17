//
//  AWSTasksClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TasksClientAdapting` backed by a plain `URLSession` GET against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSHomeClientAdapter`. Decodes into private DTOs matching the
/// Lambda's actual camelCase field shapes, then maps into the existing, unchanged
/// `LifeArea`/`TaskItem` models — those still carry the snake_case `CodingKeys` the Supabase
/// adapter needs, which would silently mis-decode this backend's JSON if decoded directly.
struct AWSTasksClientAdapter: TasksClientAdapting {
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
        // Carry `archived` through — TaskGrouping routes archived areas' tasks to "Unassigned" and
        // the shared picker greys the area; both need the flag. A missing field reads as false.
        return envelope.lifeAreas.map { dto in
            LifeArea(id: dto.id, name: dto.name, colour: dto.colour, sortOrder: dto.sortOrder,
                     archived: dto.archived ?? false)
        }
    }

    /// No `status` query parameter — `TasksService` already filters client-side by
    /// `statusFilter`, matching this adapter's existing precedent before any AWS cutover.
    func fetchAllTasks() async throws -> [TaskItem] {
        let envelope: TasksEnvelope = try await get(path: "tasks")
        return envelope.tasks.map { dto in
            TaskItem(
                id: dto.id,
                lifeAreaId: dto.lifeAreaId,
                title: dto.title,
                status: dto.status,
                priority: dto.priority,
                dueDate: dto.dueDate
            )
        }
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        do {
            let token = try await authClient.validIDToken()

            var request = URLRequest(url: baseURL.appendingPathComponent(path))
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
}

private struct LifeAreaDTO: Decodable {
    let id: UUID
    let name: String
    let colour: String
    let sortOrder: Int
    // Absent for the nine seeded rows / an older backend → not archived.
    let archived: Bool?
}

private struct LifeAreasEnvelope: Decodable {
    let lifeAreas: [LifeAreaDTO]
}

/// `dueDate` is client-supplied and, until TaskCreate cuts over, no AWS-side code controls its
/// format — parsed tolerantly so a malformed/unparseable value becomes `nil` rather than
/// discarding the whole task or throwing.
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
        dueDate = dueDateRaw.flatMap(AWSTaskDueDateParsing.parse)
    }
}

private struct TasksEnvelope: Decodable {
    let tasks: [TaskItemDTO]
}

/// Tries a fractional-seconds ISO8601 parse first, then the plain form — mirrors Reminders'
/// two-formatter tolerance for a field whose exact upstream format isn't yet fixed.
private enum AWSTaskDueDateParsing {
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
