//
//  AWSAuthClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `AuthClientAdapting` backed by plain `URLSession` POST requests directly against
/// the Cognito Identity Provider API (`InitiateAuth`/`GlobalSignOut`) — no AWS SDK for Swift
/// dependency, same "thin JSON-over-HTTP" pattern the Stage A Reminders block already used
/// against `poke-ios-bridge`. `USER_PASSWORD_AUTH`/`REFRESH_TOKEN_AUTH` on a no-secret public app
/// client need no IAM credentials or request signing, only the client ID.
struct AWSAuthClientAdapter: AuthClientAdapting {
    /// A cached ID token is refreshed once inside this many seconds of its `exp` claim, rather
    /// than waiting for it to actually expire.
    static let refreshBuffer: TimeInterval = 5 * 60

    private let session: URLSession
    private let baseURL: URL
    private let clientID: String
    private let store: SecureTokenStoring

    init(
        session: URLSession = .shared,
        baseURL: URL = CognitoConfig.identityProviderURL,
        clientID: String = CognitoConfig.appClientID,
        store: SecureTokenStoring = KeychainTokenStore()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.clientID = clientID
        self.store = store
    }

    func restoredUser() async -> AuthUser? {
        guard store.load() != nil else { return nil }
        guard let idToken = try? await validIDToken(), let claims = try? JWTClaims(token: idToken) else {
            return nil
        }
        return AuthUser(claims: claims)
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": clientID,
            "AuthParameters": ["USERNAME": email, "PASSWORD": password]
        ]

        let result = try await initiateAuth(body: body, mapError: AuthServiceError.invalidCredentials)
        store.save(result)
        let claims = try JWTClaims(token: result.idToken)
        return AuthUser(claims: claims)
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {
        throw AuthServiceError.magicLinkUnavailable(
            "Sign-in links aren't available yet — use email and password."
        )
    }

    func completeSession(from url: URL) async throws -> AuthUser {
        throw AuthServiceError.magicLinkUnavailable(
            "Sign-in links aren't available yet — use email and password."
        )
    }

    func signOut() async throws {
        defer { store.clear() }

        guard let tokens = store.load() else { return }
        let body: [String: Any] = ["AccessToken": tokens.accessToken]
        _ = try? await post(target: "GlobalSignOut", body: body)
    }

    func validIDToken() async throws -> String {
        guard let tokens = store.load() else {
            throw AuthServiceError.sessionExpired("You've been signed out — please sign in again.")
        }

        if tokens.idTokenExpiry.timeIntervalSinceNow > Self.refreshBuffer {
            return tokens.idToken
        }

        do {
            let refreshed = try await refresh(using: tokens)
            store.save(refreshed)
            return refreshed.idToken
        } catch {
            store.clear()
            throw error
        }
    }

    // MARK: - Cognito requests

    private func refresh(using tokens: StoredTokens) async throws -> StoredTokens {
        let body: [String: Any] = [
            "AuthFlow": "REFRESH_TOKEN_AUTH",
            "ClientId": clientID,
            "AuthParameters": ["REFRESH_TOKEN": tokens.refreshToken]
        ]

        return try await initiateAuth(
            body: body,
            mapError: AuthServiceError.sessionExpired,
            fallbackRefreshToken: tokens.refreshToken
        )
    }

    private func initiateAuth(
        body: [String: Any],
        mapError: @escaping (String) -> AuthServiceError,
        fallbackRefreshToken: String? = nil
    ) async throws -> StoredTokens {
        let data = try await post(target: "InitiateAuth", body: body, mapError: mapError)

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let authResult = json["AuthenticationResult"] as? [String: Any],
            let idToken = authResult["IdToken"] as? String,
            let accessToken = authResult["AccessToken"] as? String
        else {
            throw mapError("The sign-in response was malformed.")
        }

        let refreshToken = (authResult["RefreshToken"] as? String) ?? fallbackRefreshToken
        guard let refreshToken else {
            throw mapError("The sign-in response was malformed.")
        }

        guard let claims = try? JWTClaims(token: idToken) else {
            throw mapError("The sign-in response was malformed.")
        }

        return StoredTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken,
            idTokenExpiry: claims.exp
        )
    }

    private func post(
        target: String,
        body: [String: Any],
        mapError: ((String) -> AuthServiceError)? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "AWSCognitoIdentityProviderService.\(target)",
            forHTTPHeaderField: "X-Amz-Target"
        )
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw (mapError ?? AuthServiceError.invalidCredentials)("The request failed.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw (mapError ?? AuthServiceError.invalidCredentials)(Self.message(fromErrorBody: data))
        }

        return data
    }

    private static func message(fromErrorBody data: Data) -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return "Something went wrong. Please try again."
        }

        let type = (json["__type"] as? String) ?? ""
        let serverMessage = json["message"] as? String

        if type.contains("NotAuthorizedException") || type.contains("UserNotFoundException") {
            return "Incorrect email or password."
        }
        if type.contains("PasswordResetRequiredException") {
            return "A password reset is required for this account."
        }
        if type.contains("UserNotConfirmedException") {
            return "This account has not been confirmed yet."
        }
        return serverMessage ?? "Something went wrong. Please try again."
    }
}

private extension AuthUser {
    init(claims: JWTClaims) {
        self.init(id: claims.sub, email: claims.email)
    }
}
