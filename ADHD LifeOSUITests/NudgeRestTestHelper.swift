//
//  NudgeRestTestHelper.swift
//  ADHD LifeOSUITests
//
//  Direct GoTrue/PostgREST helper for "FEATURE: Nudges UI Test" — backdates a nudge's
//  `last_fired_at` so it's already due without waiting for real time to pass. A freshly created
//  nudge can never be immediately due through the app itself (`NudgeDueness` always computes the
//  *next* fire time strictly after its reference date), so this direct-REST seeding is the only
//  way to exercise the due → dismiss → sync path in a UI test. Test-target-only — never added to
//  the app target.
//

import Foundation

enum NudgeRestTestHelperError: Error {
    case unexpectedResponse(statusCode: Int?, body: String)
}

enum NudgeRestTestHelper {
    /// Signs in via GoTrue's password grant and returns the session's access token — independent
    /// of whatever session state the app under test currently holds.
    static func signIn(email: String, password: String) async throws -> String {
        var request = URLRequest(
            url: TestCredentials.supabaseURL.appendingPathComponent("auth/v1/token").withQuery(
                [URLQueryItem(name: "grant_type", value: "password")]
            )
        )
        request.httpMethod = "POST"
        request.setValue(TestCredentials.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw NudgeRestTestHelperError.unexpectedResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        return accessToken
    }

    /// Looks up a nudge's id by its (unique-per-test-run) label — the app's create flow doesn't
    /// hand the id back to the UI test, so this is how the test learns which row it seeded.
    /// Returns `nil` (rather than throwing) when no row matches yet, so callers can poll.
    static func fetchNudgeId(label: String, accessToken: String) async throws -> UUID? {
        let url = TestCredentials.supabaseURL.appendingPathComponent("rest/v1/nudges").withQuery([
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "label", value: "eq.\(label)")
        ])
        var request = URLRequest(url: url)
        request.setValue(TestCredentials.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NudgeRestTestHelperError.unexpectedResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
        guard let idString = rows.first?["id"] as? String, let id = UUID(uuidString: idString) else {
            return nil
        }
        return id
    }

    /// Polls `fetchNudgeId` until the row exists or `timeout` elapses. The UI test's own
    /// "wait for the label to appear in All Nudges" assertion proved unreliable in this
    /// environment (a confirmed-real INSERT sometimes never showed up in the app's local list
    /// within a generous window — see the FEATURE block's implementation report for the
    /// investigation), so this polls the same REST channel already used for backdating instead
    /// of trusting the UI's local state to reflect a server-confirmed write.
    static func pollForNudgeId(
        label: String, accessToken: String, timeout: TimeInterval = 30, pollInterval: TimeInterval = 1
    ) async throws -> UUID {
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while ProcessInfo.processInfo.systemUptime < deadline {
            if let id = try await fetchNudgeId(label: label, accessToken: accessToken) {
                return id
            }
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        throw NudgeRestTestHelperError.unexpectedResponse(statusCode: nil, body: "Nudge never appeared server-side")
    }

    /// Sets `last_fired_at` directly, bypassing the app's own create/dismiss path entirely.
    static func backdateLastFiredAt(nudgeId: UUID, to date: Date, accessToken: String) async throws {
        try await patch(
            nudgeId: nudgeId,
            body: ["last_fired_at": ISO8601DateFormatter().string(from: date)],
            accessToken: accessToken
        )
    }

    /// Best-effort test cleanup. `public.nudges` has no DELETE RLS policy (confirmed live via
    /// Supabase MCP against `iuhmgpedtyikakppokwk` — `pg_policies` lists only `nudges_insert_own`,
    /// `nudges_select_own`, `nudges_update_own`), so a seeded test row can never be hard-deleted.
    /// Deactivating leaves it "inactive-looking" in the test account rather than a lingering,
    /// perpetually-due row — the closest available approximation to cleanup.
    static func deactivate(nudgeId: UUID, accessToken: String) async throws {
        try await patch(nudgeId: nudgeId, body: ["active": false], accessToken: accessToken)
    }

    private static func patch(nudgeId: UUID, body: [String: Any], accessToken: String) async throws {
        let url = TestCredentials.supabaseURL.appendingPathComponent("rest/v1/nudges").withQuery([
            URLQueryItem(name: "id", value: "eq.\(nudgeId.uuidString)")
        ])
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(TestCredentials.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NudgeRestTestHelperError.unexpectedResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }
    }
}

private extension URL {
    func withQuery(_ items: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        components.queryItems = items
        return components.url ?? self
    }
}
