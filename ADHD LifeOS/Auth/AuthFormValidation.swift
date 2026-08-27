//
//  AuthFormValidation.swift
//  ADHD LifeOS
//

import Foundation

/// What the auth screen will and won't submit — pure, so the segmented Sign in | Create account
/// form has one source of truth for its button state and its inline guidance, testable without a
/// simulator (the `TaskCreateValidation` / `PlaceEditorValidation` arrangement).
///
/// The two modes disagree on the password rule ON PURPOSE. Creating an account is the one moment
/// the floor can be enforced, so it is, at Firebase's own minimum — better a hint while typing
/// than a rejected round trip. Signing in accepts any non-empty password: the stored one predates
/// whatever rule we impose today, and second-guessing it at the door would lock someone out of
/// their own data.
enum AuthFormValidation {
    /// Firebase Auth rejects anything shorter server-side, so this is its rule restated, not ours.
    static let minimumPasswordLength = 6
    /// Long enough for a real name, short enough for a greeting line. Truncates rather than
    /// rejects — the `PlaceEditorValidation.normalizedName` precedent.
    static let maximumDisplayNameLength = 60

    enum Mode: String, CaseIterable, Identifiable {
        case signIn
        case createAccount

        var id: String { rawValue }

        var title: String {
            switch self {
            case .signIn: return "Sign in"
            case .createAccount: return "Create account"
            }
        }
    }

    /// Trimmed, and `nil` unless it plausibly IS an address.
    ///
    /// Deliberately shallow — one `@`, something either side, a dot in the domain, no whitespace.
    /// A stricter grammar would reject valid addresses (RFC 5322 permits far more than anyone
    /// expects), and the real check is the one Firebase does anyway. This exists to stop a typed
    /// name or a half-finished address making a pointless network round trip.
    static func normalizedEmail(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return nil }
        let domain = parts[1]
        guard domain.contains("."), !domain.hasPrefix("."), !domain.hasSuffix(".") else { return nil }
        return trimmed
    }

    /// Trimmed, capped, `nil` when there is nothing left — the emoji rule, for the same reason:
    /// "" would be stored as a name the app would then try to greet you by.
    static func normalizedDisplayName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maximumDisplayNameLength))
    }

    static func canSubmit(mode: Mode, email: String, password: String) -> Bool {
        guard normalizedEmail(email) != nil else { return false }
        switch mode {
        case .signIn:
            return !password.isEmpty
        case .createAccount:
            return password.count >= minimumPasswordLength
        }
    }

    /// The password rule said out loud WHILE typing rather than after a failed round trip.
    /// `nil` before the first character, so an untouched form never opens already scolding.
    static func passwordHint(mode: Mode, password: String) -> String? {
        guard mode == .createAccount, !password.isEmpty,
              password.count < minimumPasswordLength else { return nil }
        return "At least \(minimumPasswordLength) characters."
    }

    static func canRequestReset(email: String) -> Bool {
        normalizedEmail(email) != nil
    }
}
