//
//  AWSLifeAreaDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `LifeAreaDetailClientAdapting` backed by a plain `URLSession` against
/// `life-os-api-gw`, authorized per request with a Cognito ID token from
/// `AuthClientAdapting.validIDToken()` — same "thin JSON-over-HTTP" pattern as
/// `AWSTasksClientAdapter`/`AWSJournalClientAdapter`. **The AWS backend has no life-area route
/// parameter** (`GET /tasks` only supports `?status=`; `GET /logs` takes no query params at all),
/// so both fetches pull the full list and filter client-side by `lifeAreaId` equality — the same
/// fetch-all/filter-in-Swift precedent `AWSTasksClientAdapter` already set for status filtering.
/// Rows with a `nil` `lifeAreaId` are excluded, matching Supabase's `.eq` (which also excludes
/// nulls). Decodes into private DTOs duplicated verbatim from `AWSTasksClientAdapter`/
/// `AWSJournalClientAdapter` per this migration's per-file-private-DTO precedent — `TaskItem`/`Log`
/// still carry snake_case `CodingKeys` for the still-present Supabase adapter.
struct AWSLifeAreaDetailClientAdapter: LifeAreaDetailClientAdapting {
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

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        let envelope: TasksEnvelope = try await get(path: "tasks")
        return envelope.tasks
            .map { dto in
                TaskItem(
                    id: dto.id,
                    lifeAreaId: dto.lifeAreaId,
                    title: dto.title,
                    status: dto.status,
                    priority: dto.priority,
                    dueDate: dto.dueDate
                )
            }
            .filter { $0.lifeAreaId == lifeAreaId }
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        let envelope: LogsEnvelope = try await get(path: "logs")
        return envelope.logs.map(\.log).filter { $0.lifeAreaId == lifeAreaId }
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
                throw LifeAreaDetailServiceError.fetchFailed(
                    "The LifeAreaDetail service returned an unexpected response."
                )
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as LifeAreaDetailServiceError {
            throw error
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

/// Duplicated verbatim from `AWSTasksClientAdapter`'s `TaskItemDTO` per this migration's
/// per-file-private-DTO precedent.
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
        dueDate = dueDateRaw.flatMap(AWSLifeAreaDetailTaskDueDateParsing.parse)
    }
}

private struct TasksEnvelope: Decodable {
    let tasks: [TaskItemDTO]
}

/// Duplicated verbatim (minus its name) from `AWSTasksClientAdapter`'s `AWSTaskDueDateParsing`.
private enum AWSLifeAreaDetailTaskDueDateParsing {
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

private struct LogsEnvelope: Decodable {
    let logs: [LogDTO]
}

/// Duplicated verbatim from `AWSJournalClientAdapter`'s `LogDTO` per this migration's
/// per-file-private-DTO precedent. Do NOT decode `Log` directly — its `CodingKeys` are snake_case
/// for the still-present `SupabaseLifeAreaDetailClientAdapter`.
private struct LogDTO: Decodable {
    let log: Log

    private enum CodingKeys: String, CodingKey {
        case id, lifeAreaId, type, body, entryDate, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let lifeAreaId = try container.decodeIfPresent(UUID.self, forKey: .lifeAreaId)
        let type = try container.decode(LogType.self, forKey: .type)
        let body = try container.decode(String.self, forKey: .body)

        let entryDateRaw = try container.decode(String.self, forKey: .entryDate)
        guard let entryDate = AWSLifeAreaDetailLogDateFormatting.parse(entryDateRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .entryDate, in: container,
                debugDescription: "entryDate \"\(entryDateRaw)\" did not match any known date format."
            )
        }

        let createdAtRaw = try container.decode(String.self, forKey: .createdAt)
        guard let createdAt = AWSLifeAreaDetailLogDateFormatting.parse(createdAtRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: container,
                debugDescription: "createdAt \"\(createdAtRaw)\" did not match any known date format."
            )
        }

        log = Log(id: id, lifeAreaId: lifeAreaId, type: type, body: body, entryDate: entryDate, createdAt: createdAt)
    }
}

/// Duplicated verbatim (minus its name) from `AWSJournalClientAdapter`'s `AWSJournalDateFormatting`.
private enum AWSLifeAreaDetailLogDateFormatting {
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
