//
//  UITestEmulator.swift
//  ADHD LifeOSUITests
//

import XCTest

/// Provisioning and sign-in for the signed-in UI journeys, driven against the Firebase Emulator
/// Suite rather than a real project.
///
/// These four journeys — task create, settings dismiss, detail-field population, nudge dismissal —
/// existed once, against a seeded Supabase account reached through a gitignored
/// `TestCredentials.swift`. They were deleted rather than stubbed in the 2026-08-19 slimming, and
/// `ADHD_LifeOSUITests`'s header recorded what reviving them would take: "a dedicated Firebase
/// test user (ideally against the Auth/Firestore emulators)". This is that.
///
/// Nothing here is a secret and nothing reaches production: every account is created on the local
/// emulator, at a random address, and is discarded when the emulator stops. The suite still
/// compiles and passes on a fresh clone with zero local setup, because without the emulator these
/// tests SKIP.
enum UITestEmulator {
    static let host = "127.0.0.1"
    static let authPort = 9099
    static let firestorePort = 8080
    /// Must match `GoogleService-Info.plist`, or the app addresses a different (empty) project
    /// inside the emulator and every read comes back empty.
    static let projectID = "adhdlifeos-acb49"
    static let password = "emulator-password-123"

    // MARK: - Availability

    /// `XCTSkip`s the calling test when the Emulator Suite is not up. Integration tests must not
    /// fail a machine that has never started it — see CLAUDE.md's "Firebase emulator" section.
    static func skipUnlessRunning() throws {
        guard isRunning else {
            throw XCTSkip(
                """
                Firebase Emulator Suite is not running at \(host):\(firestorePort). \
                Start it with `scripts/emulators.sh` (needs Java 21+), then re-run.
                """
            )
        }
    }

    /// Whether the Emulator Suite is answering.
    ///
    /// Exposed rather than kept behind `skipUnlessRunning` because a test can want to ADAPT to
    /// the emulator instead of skipping on it. `UITestSession.launchSignedOut()` is the case:
    /// it must reach the login screen on a fresh clone with no emulator at all, AND sign out of
    /// an emulator session a journey left in the keychain — so it asks, rather than assuming
    /// either way.
    static var isRunning: Bool {
        guard let url = URL(string: "http://\(host):\(firestorePort)/") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        return send(request) != nil
    }

    // MARK: - Accounts

    /// A brand-new account on the emulator, created through the Auth REST API because the app has
    /// no sign-up UI — accounts are made in the console on the real project.
    ///
    /// Each test gets its own address, so no test can observe another's data and none needs a
    /// teardown wipe to be correct.
    @discardableResult
    static func createAccount(email: String) throws -> String {
        // The emulator accepts any API key; it never validates one.
        let endpoint = "http://\(host):\(authPort)/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator"
        guard let url = URL(string: endpoint) else {
            throw UITestEmulatorError("could not build the Auth emulator URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ])
        request.timeoutInterval = 15

        guard let data = send(request) else {
            throw UITestEmulatorError("the Auth emulator did not answer accounts:signUp")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uid = json["localId"] as? String else {
            let body = String(bytes: data, encoding: .utf8) ?? "<undecodable>"
            throw UITestEmulatorError("accounts:signUp returned no localId: \(body)")
        }
        return uid
    }

    static func uniqueEmail(_ label: String) -> String {
        "uitest-\(label)-\(UUID().uuidString.prefix(8).lowercased())@example.test"
    }

    // MARK: - Firestore seeding

    /// Writes one document straight into the emulator's Firestore, bypassing the app.
    ///
    /// `Authorization: Bearer owner` is the emulator's admin escape hatch — it bypasses
    /// `firestore.rules`, which is what lets a test arrange state (a nudge that is already
    /// overdue, say) that the app itself has no UI to produce.
    static func writeDocument(path: String, fields: [String: Any]) throws {
        let endpoint = "http://\(host):\(firestorePort)/v1/projects/\(projectID)"
            + "/databases/(default)/documents/\(path)"
        guard let url = URL(string: endpoint) else {
            throw UITestEmulatorError("could not build the Firestore emulator URL for \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["fields": fields])
        request.timeoutInterval = 15

        guard send(request) != nil else {
            throw UITestEmulatorError("the Firestore emulator did not accept a write to \(path)")
        }
    }

    /// Whether a collection holds at least one document. `Bearer owner` again, for the same
    /// reason: this must observe what the APP wrote without being subject to the app's rules.
    ///
    /// Exists so a journey can wait on SEEDED DATA rather than on a screen. Waiting on the UI
    /// conflates "the seed has not landed" with "this view has not drawn yet", and those want
    /// different fixes — the two intermittent captures-journey failures (2026-08-29) were the
    /// former while reading exactly like the latter.
    static func collectionHasDocuments(path: String) -> Bool {
        let endpoint = "http://\(host):\(firestorePort)/v1/projects/\(projectID)"
            + "/databases/(default)/documents/\(path)?pageSize=1"
        guard let url = URL(string: endpoint) else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer owner", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        guard
            let data = send(request),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return false }
        return (json["documents"] as? [Any])?.isEmpty == false
    }

    static func string(_ value: String) -> [String: Any] { ["stringValue": value] }
    static func bool(_ value: Bool) -> [String: Any] { ["booleanValue": value] }
    static func timestamp(_ date: Date) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return ["timestampValue": formatter.string(from: date)]
    }

    // MARK: - Transport

    /// Synchronous on purpose: XCUITest bodies are synchronous, and a semaphore here keeps the
    /// call sites free of async plumbing that adds nothing. Returns `nil` on any transport
    /// failure, which is how `isRunning()` distinguishes "not listening" from "answered".
    private static func send(_ request: URLRequest) -> Data? {
        var result: Data?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                result = data ?? Data()
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + request.timeoutInterval + 2)
        return result
    }
}

struct UITestEmulatorError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
