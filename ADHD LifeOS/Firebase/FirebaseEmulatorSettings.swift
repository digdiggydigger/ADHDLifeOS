//
//  FirebaseEmulatorSettings.swift
//  ADHD LifeOS
//

import Foundation

/// Where the Firebase Emulator Suite is listening, resolved from the process environment.
///
/// This exists so `FirebaseManager`'s own extensions — `+Seed`, `+Tags`, `+AccountDeletion`,
/// `+Storage` — can be exercised against a real Firestore/Auth/Storage without a real project.
/// Those four are the app's only remaining untested Firebase surface, and account deletion in
/// particular cannot be tested any other way: running it against the live project erases the
/// signed-in user's entire dataset.
///
/// Which makes the safety property here the important one. **Emulator mode is opt-in on an
/// explicit host, and any malformed input resolves to `nil` (off) rather than falling back to a
/// default.** A silent fallback is the dangerous direction: a mistyped port that quietly became
/// 8080 would point a destructive test at a different database than its author intended. Off is
/// recoverable — `FirebaseEmulatorHarness` refuses to run when it cannot prove emulator mode is
/// active — whereas "connected to the wrong thing" is not.
///
/// Deliberately free of any Firebase import: this is the decision, `FirebaseManager+Emulator`
/// is the application of it. That split keeps the rule testable from a test target that does not
/// link the Firebase SDK (see CLAUDE.md — linking it into both app and hosted test bundle
/// realises every Objective-C class twice).
struct FirebaseEmulatorSettings: Equatable {
    /// Presence of a non-blank value here is the single switch that turns emulator mode on.
    static let hostKey = "LIFEOS_FIREBASE_EMULATOR_HOST"
    static let authPortKey = "LIFEOS_FIREBASE_EMULATOR_AUTH_PORT"
    static let firestorePortKey = "LIFEOS_FIREBASE_EMULATOR_FIRESTORE_PORT"
    static let storagePortKey = "LIFEOS_FIREBASE_EMULATOR_STORAGE_PORT"

    /// The Emulator Suite's published defaults, matching the `emulators` block in `firebase.json`.
    static let defaultAuthPort = 9099
    static let defaultFirestorePort = 8080
    static let defaultStoragePort = 9199

    let host: String
    let authPort: Int
    let firestorePort: Int
    let storagePort: Int

    /// Firestore's `Settings.host` is one `host:port` string, unlike Auth and Storage which take
    /// the two separately. Joined here so no call site has to remember the difference.
    var firestoreHost: String {
        "\(host):\(firestorePort)"
    }

    /// `nil` means "not running against an emulator" — the production answer, and the answer to
    /// anything malformed.
    static func resolve(from environment: [String: String] = ProcessInfo.processInfo.environment)
        -> FirebaseEmulatorSettings? {
        let host = (environment[hostKey] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { return nil }

        guard let authPort = port(environment[authPortKey], default: defaultAuthPort),
              let firestorePort = port(environment[firestorePortKey], default: defaultFirestorePort),
              let storagePort = port(environment[storagePortKey], default: defaultStoragePort) else {
            return nil
        }

        return FirebaseEmulatorSettings(
            host: host,
            authPort: authPort,
            firestorePort: firestorePort,
            storagePort: storagePort
        )
    }

    /// An absent variable takes the default; a *present but unusable* one fails the whole
    /// resolution. Setting the key at all is a statement of intent, and honouring it as the
    /// default instead would silently contradict that intent.
    private static func port(_ raw: String?, default fallback: Int) -> Int? {
        guard let raw else { return fallback }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), (1...65535).contains(value) else { return nil }
        return value
    }
}
