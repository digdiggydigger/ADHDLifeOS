//
//  AuthServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class AuthServiceTests: XCTestCase {

    func testRestoreSession_withExistingSession_setsSignedIn() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.restoredUserResult = user
        let sut = AuthService(client: fake)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedIn(user))
    }

    func testRestoreSession_withNoSession_setsSignedOut() async {
        let fake = FakeAuthClientAdapting()
        fake.restoredUserResult = nil
        let sut = AuthService(client: fake)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedOut)
    }

    func testSignIn_success_updatesStateToSignedIn() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.signInResult = .success(user)
        let sut = AuthService(client: fake)

        await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNil(sut.errorMessage)
    }

    func testSignIn_failure_surfacesErrorAndStaysSignedOut() async {
        let fake = FakeAuthClientAdapting()
        fake.signInResult = .failure(AuthServiceError.invalidCredentials("Invalid login credentials"))
        let sut = AuthService(client: fake)
        await sut.restoreSession() // resolves default nil session -> .signedOut

        await sut.signIn(email: "e@example.com", password: "wrong-password")

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertEqual(sut.errorMessage, "Invalid login credentials")
    }

    func testSignIn_trimsLeadingAndTrailingWhitespaceFromEmailAndPassword() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.signInResult = .success(user)
        let sut = AuthService(client: fake)

        await sut.signIn(email: " e@example.com \n", password: " correct-horse \n")

        XCTAssertEqual(fake.lastSignInEmail, "e@example.com")
        XCTAssertEqual(fake.lastSignInPassword, "correct-horse")
        XCTAssertEqual(sut.state, .signedIn(user))
    }

    func testRequestMagicLink_success_updatesStateToLinkSent() async {
        let fake = FakeAuthClientAdapting()
        fake.requestOTPResult = .success(())
        let sut = AuthService(client: fake)

        await sut.requestMagicLink(email: "e@example.com")

        XCTAssertEqual(sut.state, .linkSent(email: "e@example.com"))
        XCTAssertEqual(fake.requestOTPCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testRequestMagicLink_failure_surfacesError() async {
        let fake = FakeAuthClientAdapting()
        fake.requestOTPResult = .failure(AuthServiceError.otpRequestFailed("Unable to send magic link"))
        let sut = AuthService(client: fake)

        await sut.requestMagicLink(email: "e@example.com")

        XCTAssertEqual(sut.errorMessage, "Unable to send magic link")
        if case .linkSent = sut.state {
            XCTFail("state should not become linkSent on failure")
        }
    }

    func testCompleteSession_success_updatesStateToSignedIn() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.completeSessionResult = .success(user)
        let sut = AuthService(client: fake)
        let callbackURL = URL(string: "adhdlifeos://auth-callback#access_token=abc")!

        await sut.completeSession(from: callbackURL)

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertEqual(fake.completeSessionCallCount, 1)
    }

    func testCompleteSession_failure_surfacesError() async {
        let fake = FakeAuthClientAdapting()
        fake.completeSessionResult = .failure(AuthServiceError.sessionExchangeFailed("Invalid callback URL"))
        let sut = AuthService(client: fake)
        let callbackURL = URL(string: "adhdlifeos://auth-callback")!

        await sut.completeSession(from: callbackURL)

        XCTAssertEqual(sut.errorMessage, "Invalid callback URL")
    }

    func testSignOut_success_clearsStateToSignedOut() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.restoredUserResult = user
        let sut = AuthService(client: fake)
        await sut.restoreSession()
        XCTAssertEqual(sut.state, .signedIn(user))

        await sut.signOut()

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertEqual(fake.signOutCallCount, 1)
    }

    func testSignOut_failure_surfacesErrorAndKeepsSignedIn() async {
        let fake = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        fake.restoredUserResult = user
        fake.signOutResult = .failure(AuthServiceError.signOutFailed("Network error"))
        let sut = AuthService(client: fake)
        await sut.restoreSession()

        await sut.signOut()

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertEqual(sut.errorMessage, "Network error")
    }

    // MARK: - Supabase bridge (FIX: No Supabase session after Cognito-only sign-in, 2026-07-22)

    func testSignIn_success_alsoSignsIntoSupabaseBridge_withSameTrimmedCredentials() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        let bridge = FakeAuthClientAdapting()
        bridge.signInResult = .success(AuthUser(id: UUID(), email: "e@example.com"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.signIn(email: " e@example.com \n", password: " correct-horse \n")

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(bridge.signInCallCount, 1)
        XCTAssertEqual(bridge.lastSignInEmail, "e@example.com")
        XCTAssertEqual(bridge.lastSignInPassword, "correct-horse")
    }

    func testSignIn_supabaseBridgeFailure_stillSucceedsAsSignedInViaCognito() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        let bridge = FakeAuthClientAdapting()
        bridge.signInResult = .failure(AuthServiceError.invalidCredentials("Supabase password mismatch"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(bridge.signInCallCount, 1)
    }

    func testSignIn_cognitoFailure_neverAttemptsSupabaseBridgeSignIn() async {
        let cognito = FakeAuthClientAdapting()
        cognito.signInResult = .failure(AuthServiceError.invalidCredentials("Incorrect email or password"))
        let bridge = FakeAuthClientAdapting()
        let sut = AuthService(client: cognito, supabaseBridge: bridge)
        await sut.restoreSession()

        await sut.signIn(email: "e@example.com", password: "wrong-password")

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertEqual(bridge.signInCallCount, 0)
    }

    func testSignOut_success_alsoSignsOutOfSupabaseBridge() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.restoredUserResult = user
        let bridge = FakeAuthClientAdapting()
        let sut = AuthService(client: cognito, supabaseBridge: bridge)
        await sut.restoreSession()

        await sut.signOut()

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertEqual(cognito.signOutCallCount, 1)
        XCTAssertEqual(bridge.signOutCallCount, 1)
    }

    func testSignOut_supabaseBridgeFailure_stillCompletesCognitoSignOut() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.restoredUserResult = user
        let bridge = FakeAuthClientAdapting()
        bridge.signOutResult = .failure(AuthServiceError.signOutFailed("Network error"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)
        await sut.restoreSession()

        await sut.signOut()

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(bridge.signOutCallCount, 1)
    }

    // MARK: - Supabase bridge warning (hardening the silent `try?` failure, 2026-07-22)

    func testSignIn_supabaseBridgeFailure_setsSupabaseBridgeWarning() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        let bridge = FakeAuthClientAdapting()
        bridge.signInResult = .failure(AuthServiceError.invalidCredentials("Supabase password mismatch"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNil(sut.errorMessage)
        XCTAssertNotNil(sut.supabaseBridgeWarning)
    }

    func testSignIn_supabaseBridgeSuccess_leavesSupabaseBridgeWarningNil() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        let bridge = FakeAuthClientAdapting()
        bridge.signInResult = .success(AuthUser(id: UUID(), email: "e@example.com"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertNil(sut.supabaseBridgeWarning)
    }

    func testSignIn_noSupabaseBridgeConfigured_leavesSupabaseBridgeWarningNil() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        let sut = AuthService(client: cognito)

        await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertNil(sut.supabaseBridgeWarning)
    }

    func testSignOut_clearsAnyExistingSupabaseBridgeWarning() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.signInResult = .success(user)
        cognito.restoredUserResult = user
        let bridge = FakeAuthClientAdapting()
        bridge.signInResult = .failure(AuthServiceError.invalidCredentials("Supabase password mismatch"))
        let sut = AuthService(client: cognito, supabaseBridge: bridge)
        await sut.signIn(email: "e@example.com", password: "correct-horse")
        XCTAssertNotNil(sut.supabaseBridgeWarning)

        await sut.signOut()

        XCTAssertNil(sut.supabaseBridgeWarning)
    }

    // MARK: - Supabase bridge restore (FIX: bridge never re-established on relaunch, 2026-07-23)

    func testRestoreSession_signedIn_bridgeHasSession_restoresBridgeAndLeavesWarningNil() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.restoredUserResult = user
        let bridge = FakeAuthClientAdapting()
        bridge.restoredUserResult = AuthUser(id: UUID(), email: "e@example.com")
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertEqual(bridge.restoredUserCallCount, 1)
        XCTAssertNil(sut.supabaseBridgeWarning)
    }

    func testRestoreSession_signedIn_bridgeHasNoSession_setsSupabaseBridgeWarning() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.restoredUserResult = user
        let bridge = FakeAuthClientAdapting()
        bridge.restoredUserResult = nil
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNotNil(sut.supabaseBridgeWarning)
    }

    func testRestoreSession_signedOut_neverAttemptsSupabaseBridgeRestore() async {
        let cognito = FakeAuthClientAdapting()
        cognito.restoredUserResult = nil
        let bridge = FakeAuthClientAdapting()
        bridge.restoredUserResult = AuthUser(id: UUID(), email: "e@example.com")
        let sut = AuthService(client: cognito, supabaseBridge: bridge)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedOut)
        XCTAssertEqual(bridge.restoredUserCallCount, 0)
        XCTAssertNil(sut.supabaseBridgeWarning)
    }

    func testRestoreSession_noSupabaseBridgeConfigured_leavesWarningNil() async {
        let cognito = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        cognito.restoredUserResult = user
        let sut = AuthService(client: cognito)

        await sut.restoreSession()

        XCTAssertEqual(sut.state, .signedIn(user))
        XCTAssertNil(sut.supabaseBridgeWarning)
    }
}
