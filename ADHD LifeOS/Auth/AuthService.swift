//
//  AuthService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState = .unknown
    @Published private(set) var errorMessage: String?
    /// Set when `supabaseBridge?.signIn`/`signOut` fails, kept separate from `errorMessage` so it
    /// never blocks or overwrites the Cognito sign-in/out result. A silent `try?` failure here
    /// used to be invisible — it surfaced only later, as confusing decode/session errors on
    /// whichever Supabase-backed screen (Tasks, Journal, Capture, etc.) happened to load next.
    /// Non-`nil` means those screens are currently unable to load real data.
    @Published private(set) var supabaseBridgeWarning: String?

    private let client: AuthClientAdapting
    /// The authenticated (Cognito) client, exposed read-only so screens presented with only an
    /// `AuthService` (e.g. `SettingsView`) can build their own AWS adapters without re-threading the
    /// client through the whole view tree. Same instance that scopes every AWS request to the user.
    var authClient: AuthClientAdapting { client }
    private let redirectURL: URL?
    /// STOPGAP (2026-07-22, FIX: "No Supabase session after Cognito-only sign-in") — bridges
    /// this service's Cognito-only sign-in/out into a real, persisted Supabase session, so the
    /// still-Supabase-backed adapters (Tasks, TaskCreate, TaskDetail, Capture, Journal, Nudges,
    /// LifeAreaDetail) keep working. Cognito (`client`) remains the sole source of truth for
    /// `state`; a bridge failure never blocks reaching Home, it only surfaces later on whichever
    /// Supabase-backed screen still depends on the missing session. Delete this bridge (and the
    /// parameter) once every one of those screens has its own Stage C AWS cutover.
    private let supabaseBridge: AuthClientAdapting?

    init(client: AuthClientAdapting, redirectURL: URL? = nil, supabaseBridge: AuthClientAdapting? = nil) {
        self.client = client
        self.redirectURL = redirectURL
        self.supabaseBridge = supabaseBridge
    }

    func restoreSession() async {
        if let user = await client.restoredUser() {
            state = .signedIn(user)
            // Mirrors the signIn() bridge attempt: a relaunch that restores the Cognito session
            // directly (skipping signIn()) would otherwise never re-establish the Supabase side,
            // leaving Tasks/Journal/Capture/etc. broken with no warning until they load.
            if let supabaseBridge {
                if await supabaseBridge.restoredUser() != nil {
                    supabaseBridgeWarning = nil
                } else {
                    supabaseBridgeWarning = "Some features may not load right now — try signing out and back in."
                }
            }
        } else {
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let user = try await client.signIn(email: trimmedEmail, password: trimmedPassword)
            state = .signedIn(user)
            // Best-effort: a Supabase-side failure (e.g. mismatched password) must not undo the
            // Cognito sign-in that already gated the UI into `state = .signedIn`.
            do {
                _ = try await supabaseBridge?.signIn(email: trimmedEmail, password: trimmedPassword)
                supabaseBridgeWarning = nil
            } catch {
                supabaseBridgeWarning = "Some features may not load right now — try signing out and back in."
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Sign in with Apple, after the view has extracted the identity token and raw nonce from
    /// `ASAuthorization`. No Supabase-bridge attempt: the bridge predates the Firebase cutover
    /// and is `nil` in production wiring; an Apple identity has no bridge password anyway.
    func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async {
        errorMessage = nil
        do {
            let user = try await client.signInWithApple(
                idToken: idToken, rawNonce: rawNonce, displayName: displayName
            )
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func requestMagicLink(email: String) async {
        errorMessage = nil
        do {
            try await client.requestOTP(email: email, redirectTo: redirectURL)
            state = .linkSent(email: email)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func completeSession(from url: URL) async {
        errorMessage = nil
        do {
            let user = try await client.completeSession(from: url)
            state = .signedIn(user)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signOut() async {
        errorMessage = nil
        do {
            try await client.signOut()
            // Best-effort: mirror the sign-out on the Supabase bridge so no orphaned session is
            // left refreshing in the Keychain; a failure here doesn't block the Cognito sign-out.
            _ = try? await supabaseBridge?.signOut()
            supabaseBridgeWarning = nil
            state = .signedOut
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
