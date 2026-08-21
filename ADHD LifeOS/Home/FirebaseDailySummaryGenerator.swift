//
//  FirebaseDailySummaryGenerator.swift
//  ADHD LifeOS
//

import FirebaseAuth
import Foundation

/// Failures worth telling the user apart. The card shows `errorDescription` verbatim, so each one
/// has to say what happened *and* imply what to do — "not signed in" and "the model declined" need
/// different reactions from the reader.
enum DailySummaryEndpointError: LocalizedError, Equatable {
    case notSignedIn
    case notConfigured
    case unauthorized
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You're signed out — sign in to generate a summary."
        case .notConfigured:
            return "The summary service isn't configured yet."
        case .unauthorized:
            return "Your session expired. Sign out and back in, then try again."
        case .server(let message):
            return message
        case .badResponse:
            return "The summary came back in a shape the app couldn't read."
        }
    }
}

/// What the Cloud Function returns. Mirrors the web's `{ success, summary, source }` envelope so
/// the two backends stayed interchangeable while this one was being built.
struct DailySummaryEnvelope: Decodable, Equatable {
    /// Optional because an error body carries only `error` — a non-optional `Bool` makes the whole
    /// decode fail on exactly the responses whose message is most worth showing, and the user gets
    /// a generic status code instead of what the server actually said.
    let success: Bool?
    let source: String?
    let summary: DailySummaryContent?
    /// Present instead of `summary` on a 4xx/5xx, and shown to the user as-is.
    let error: String?
}

/// Calls the `dailySummary` Cloud Function, which holds the Anthropic key and does the model call.
///
/// The key never reaches the device — that is the whole reason this is a proxy rather than a
/// direct SDK call from the app. Auth is a Firebase ID token: short-lived, per-user, revocable,
/// and refreshed by the SDK, so nothing long-lived ships in the binary.
struct FirebaseDailySummaryGenerator: DailySummaryGenerating {
    var source: DailySummarySource { .model }

    private let endpoint: URL?
    private let send: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(
        endpoint: URL? = Self.defaultEndpoint,
        send: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = {
            try await URLSession.shared.data(for: $0)
        }
    ) {
        self.endpoint = endpoint
        self.send = send
    }

    /// The deployed function's URL. 2nd-gen functions run on Cloud Run, so this is the Cloud Run
    /// form with a generated hostname — it cannot be derived from the project id, and is read off
    /// `gcloud run services list` after a deploy. Not a secret: the endpoint authenticates every
    /// caller with a Firebase ID token, so knowing the URL grants nothing.
    static let defaultEndpoint: URL? = URL(string: "https://dailysummary-dg5rypfbaq-uc.a.run.app")

    func generate(_ request: DailySummaryRequest) async throws -> DailySummaryContent {
        guard let endpoint else { throw DailySummaryEndpointError.notConfigured }
        guard let user = Auth.auth().currentUser else { throw DailySummaryEndpointError.notSignedIn }

        let token = try await user.idToken()

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try Self.encoder.encode(request)
        // The model call is the slow part; the default 60s timeout is tight for a cold start plus
        // a thinking model, and a spurious timeout looks identical to a real failure to the user.
        urlRequest.timeoutInterval = 90

        let (data, response) = try await send(urlRequest)
        return try Self.decode(data: data, response: response)
    }

    /// ISO-8601 dates, because the function reads `date` as a string. Swift's default strategy
    /// encodes a `Date` as seconds since the 2001 reference date — a bare number the function
    /// would have no way to interpret as a day.
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// Split out and `static` so the response contract is testable without a network or a signed-in
    /// user — which is most of what can go wrong here.
    static func decode(data: Data, response: URLResponse) throws -> DailySummaryContent {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let envelope = try? JSONDecoder().decode(DailySummaryEnvelope.self, from: data)

        guard (200..<300).contains(status) else {
            if status == 401 { throw DailySummaryEndpointError.unauthorized }
            // Prefer the server's own wording — it is written for the user, unlike a status code.
            throw DailySummaryEndpointError.server(
                envelope?.error ?? "The summary service returned an error (\(status))."
            )
        }
        guard let envelope, envelope.success == true, let summary = envelope.summary else {
            throw DailySummaryEndpointError.badResponse
        }
        return summary
    }
}

private extension User {
    /// `getIDToken` is callback-based in the Firebase SDK; this is the async bridge.
    func idToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            getIDToken { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: DailySummaryEndpointError.notSignedIn)
                }
            }
        }
    }
}
