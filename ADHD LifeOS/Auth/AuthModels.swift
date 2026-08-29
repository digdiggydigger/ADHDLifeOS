//
//  AuthModels.swift
//  ADHD LifeOS
//

import Foundation

struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String?
    /// Already normalised: trimmed, and `nil` rather than empty. Normalising at the adapter
    /// boundary means every screen downstream can read `nil` as "no name" without each deciding
    /// for itself whether "   " counts.
    var displayName: String?
}

enum AuthState: Equatable, Sendable {
    case unknown
    case signedOut
    case signedIn(AuthUser)
    case linkSent(email: String)
}

enum AuthServiceError: LocalizedError, Equatable {
    case invalidCredentials(String)
    case otpRequestFailed(String)
    case sessionExchangeFailed(String)
    case signOutFailed(String)
    /// Cognito's admin-created, `AllowAdminCreateUserOnly` user pool has no OTP/magic-link
    /// sign-in path. `AWSAuthClientAdapter` throws this unconditionally from `requestOTP`/
    /// `completeSession(from:)` rather than silently no-op'ing (Stage C.1 stub-and-hide decision).
    case magicLinkUnavailable(String)
    /// Thrown by `validIDToken()` when there is no stored session or the refresh token itself
    /// has been rejected — callers must treat this as a forced sign-out.
    case sessionExpired(String)
    /// Sign in with Apple failed — either Apple returned an unusable credential or the
    /// Firebase token exchange was rejected (bad nonce, provider disabled in the console, …).
    case appleSignInFailed(String)
    /// Creating the account was rejected — email already in use, password below Firebase's own
    /// floor, or the network. Distinct from `invalidCredentials` so the screen can say which of
    /// the two things it was asked to do actually failed.
    case signUpFailed(String)
    /// The reset email could not be sent — or was never attempted, because what was typed is not
    /// an address.
    case passwordResetFailed(String)
    /// Renaming the account was rejected. Its own case rather than a reused one because this is
    /// the failure that must never be silent: everything in the app reads the name off the Auth
    /// user, so a swallowed commit leaves the UI showing the OLD name with no sign anything went
    /// wrong (`signUp` commits with `try?`, which is exactly how that happens).
    case displayNameUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let message),
             .otpRequestFailed(let message),
             .sessionExchangeFailed(let message),
             .signOutFailed(let message),
             .magicLinkUnavailable(let message),
             .sessionExpired(let message),
             .appleSignInFailed(let message),
             .signUpFailed(let message),
             .passwordResetFailed(let message),
             .displayNameUpdateFailed(let message):
            return message
        }
    }
}
