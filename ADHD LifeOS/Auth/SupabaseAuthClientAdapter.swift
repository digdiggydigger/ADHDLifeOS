//
//  SupabaseAuthClientAdapter.swift
//  ADHD LifeOS
//

import Auth
import Foundation

/// Production `AuthClientAdapting` backed by `supabase-swift`'s `AuthClient`.
struct SupabaseAuthClientAdapter: AuthClientAdapting {
    private let client: AuthClient

    init(client: AuthClient) {
        self.client = client
    }

    func restoredUser() async -> AuthUser? {
        guard let session = try? await client.session else { return nil }
        return AuthUser(session: session)
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        do {
            let session = try await client.signIn(email: email, password: password)
            return AuthUser(session: session)
        } catch {
            throw AuthServiceError.invalidCredentials(Self.message(for: error))
        }
    }

    func requestOTP(email: String, redirectTo: URL?) async throws {
        do {
            try await client.signInWithOTP(email: email, redirectTo: redirectTo)
        } catch {
            throw AuthServiceError.otpRequestFailed(Self.message(for: error))
        }
    }

    func completeSession(from url: URL) async throws -> AuthUser {
        do {
            let session = try await client.session(from: url)
            return AuthUser(session: session)
        } catch {
            throw AuthServiceError.sessionExchangeFailed(Self.message(for: error))
        }
    }

    func signOut() async throws {
        do {
            try await client.signOut()
        } catch {
            throw AuthServiceError.signOutFailed(Self.message(for: error))
        }
    }

    func validIDToken() async throws -> String {
        do {
            let session = try await client.session
            return session.accessToken
        } catch {
            throw AuthServiceError.sessionExpired(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

private extension AuthUser {
    init(session: Session) {
        self.init(id: session.user.id, email: session.user.email)
    }
}
