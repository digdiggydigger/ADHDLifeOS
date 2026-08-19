//
//  AuthModels.swift
//  ADHD LifeOS
//

import Foundation

struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String?
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

    var errorDescription: String? {
        switch self {
        case .invalidCredentials(let message),
             .otpRequestFailed(let message),
             .sessionExchangeFailed(let message),
             .signOutFailed(let message),
             .magicLinkUnavailable(let message),
             .sessionExpired(let message),
             .appleSignInFailed(let message):
            return message
        }
    }
}
