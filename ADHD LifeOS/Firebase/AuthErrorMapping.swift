//
//  AuthErrorMapping.swift
//  ADHD LifeOS
//

import FirebaseAuth
import Foundation

/// Firebase Auth's error facts, in one place — the `FirestoreErrorMapping` counterpart.
///
/// One Auth failure is worth distinguishing: `requiresRecentLogin`, which the account-deletion flow
/// turns into a *pause* for reauthentication rather than a terminal error. Getting that backwards
/// either strands the user on a failure they could have cleared, or hides a real failure behind a
/// password prompt that cannot fix it.
///
/// `errorDomain` and `requiresRecentLoginCode` are exposed so a test can build a genuine
/// Auth-shaped error without importing the SDK — the unit-test target deliberately does not link
/// it (see `FirestoreDocumentCoder`). Hardcoding `"FIRAuthErrorDomain"`/`17014` in a test would
/// work today and drift silently.
enum AuthErrorMapping {
    static var errorDomain: String { AuthErrorDomain }
    static var requiresRecentLoginCode: Int { AuthErrorCode.requiresRecentLogin.rawValue }

    /// Whether Firebase is demanding a fresh sign-in before honouring a destructive call.
    ///
    /// The domain check is load-bearing: the same numeric code from another domain is not this
    /// demand, and prompting for a password would be answering a question nobody asked.
    static func isRecentLoginRequired(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == errorDomain && nsError.code == requiresRecentLoginCode
    }
}
