//
//  AWSRemindersClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `RemindersClientAdapting` backed by a plain `URLSession` GET against the live,
/// unauthenticated `poke-ios-bridge` route. Deliberately sends **no credentials, no API key, no
/// `Authorization` header** — the route has no authorizer attached by design (Stage B hardens
/// this); adding auth headers here would not match the endpoint's actual contract.
struct AWSRemindersClientAdapter: RemindersClientAdapting {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = AWSConfig.remindersBaseURL) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchReminders() async throws -> [Reminder] {
        let request = URLRequest(url: baseURL.appendingPathComponent("task"))

        do {
            let (data, response) = try await session.data(for: request)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                throw RemindersServiceError.fetchFailed("The reminders service returned an unexpected response.")
            }
            let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: data)
            return envelope.tasks
        } catch let error as RemindersServiceError {
            throw error
        } catch {
            throw RemindersServiceError.fetchFailed(error.localizedDescription)
        }
    }
}
