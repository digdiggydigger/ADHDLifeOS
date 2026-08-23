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
}
