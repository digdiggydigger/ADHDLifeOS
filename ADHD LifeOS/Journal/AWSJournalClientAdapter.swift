//
//  AWSJournalClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `JournalClientAdapting` backed by a plain `URLSession` against `life-os-api-gw`,
/// authorized per request with a Cognito ID token from `AuthClientAdapting.validIDToken()` — same
/// "thin JSON-over-HTTP" pattern as `AWSCaptureClientAdapter`/`AWSTasksClientAdapter`. Decodes into
/// a private camelCase `LogDTO` rather than `Log` directly — `Log`'s `CodingKeys` are snake_case
/// for the still-present Supabase adapter, and would silently mis-decode this backend's JSON.
/// `entryDate`/`createdAt` parse via the tolerant fractional/standard/bare ISO8601 parser (the
/// Lambda's `_now_iso()` omits a timezone designator).
struct AWSJournalClientAdapter: JournalClientAdapting {
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
        // Carry `archived` through — the Journal filter picker greys archived areas and `LogRowView`
        // renders a log belonging to an archived area as "Unassigned". A missing field reads as false.
        return envelope.lifeAreas.map { dto in
            LifeArea(id: dto.id, name: dto.name, colour: dto.colour, sortOrder: dto.sortOrder,
                     archived: dto.archived ?? false)
        }
    }

    func fetchLogs() async throws -> [Log] {
        let envelope: LogsEnvelope = try await get(path: "logs")
        return envelope.logs.map(\.log)
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log {
        let body = CreateLogRequestBody(body: input.body, type: input.type, lifeAreaId: input.lifeAreaId)
        let dto: LogDTO = try await post(path: "logs", body: body)
        return dto.log
    }

    private func get<T: Decodable>(path: String) async throws -> T {
        try await send(path: path, method: "GET", httpBody: nil)
    }

    private func post<T: Decodable>(path: String, body: some Encodable) async throws -> T {
        try await send(path: path, method: "POST", httpBody: try JSONEncoder().encode(body))
    }

    private func send<T: Decodable>(path: String, method: String, httpBody: Data?) async throws -> T {
        let data = try await requestData(path: path, method: method, httpBody: httpBody)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
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
                throw JournalServiceError.fetchFailed("The Journal service returned an unexpected response.")
            }
            return data
        } catch let error as JournalServiceError {
            throw error
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

/// Mirrors `AWSHomeClientAdapter`/`AWSTasksClientAdapter`'s `LifeAreaDTO`, duplicated per this
/// migration's per-file-private-DTO precedent rather than shared.
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

private struct LogsEnvelope: Decodable {
    let logs: [LogDTO]
}

/// Only the fields `createLog` sends are included on the wire, and only when present — matching
/// `CreateCaptureRequestBody`'s omit-absent-optionals precedent. `userId`/`entryDate` are never
/// sent: the server scopes `userId` from the JWT and sets `entryDate` itself.
private struct CreateLogRequestBody: Encodable {
    let body: String
    let type: LogType
    let lifeAreaId: UUID?

    private enum CodingKeys: String, CodingKey {
        case body, type, lifeAreaId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(body, forKey: .body)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(lifeAreaId, forKey: .lifeAreaId)
    }
}

/// Own private DTO (camelCase) — do NOT decode `Log` directly, its `CodingKeys` are snake_case
/// for the still-present `SupabaseJournalClientAdapter`. `entryDate`/`createdAt` use the tolerant
/// three-fallback parser since the Lambda's bare `_now_iso()` has no timezone designator.
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
        guard let entryDate = AWSJournalDateFormatting.parse(entryDateRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .entryDate, in: container,
                debugDescription: "entryDate \"\(entryDateRaw)\" did not match any known date format."
            )
        }

        let createdAtRaw = try container.decode(String.self, forKey: .createdAt)
        guard let createdAt = AWSJournalDateFormatting.parse(createdAtRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: container,
                debugDescription: "createdAt \"\(createdAtRaw)\" did not match any known date format."
            )
        }

        log = Log(id: id, lifeAreaId: lifeAreaId, type: type, body: body, entryDate: entryDate, createdAt: createdAt)
    }
}

/// Three-fallback parser, duplicated from `AWSCaptureClientAdapter`'s `AWSCaptureDateFormatting`
/// per this migration's established per-file-private-DTO precedent.
private enum AWSJournalDateFormatting {
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
