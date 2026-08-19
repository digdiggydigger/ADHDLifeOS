//
//  AuthServiceAppleSignInTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Sign in with Apple path through `AuthService`: the view extracts the identity token and
/// raw nonce from `ASAuthorization` (thin, UI-layer), and everything from there down is this
/// testable seam — same state-machine rules as the password path.
@MainActor
final class AuthServiceAppleSignInTests: XCTestCase {
    private var client: FakeAuthClientAdapting!
    private var service: AuthService!

    override func setUp() {
        super.setUp()
        client = FakeAuthClientAdapting()
        service = AuthService(client: client)
    }

    func testSignInWithApple_success_setsSignedInStateAndPassesCredentialFields() async {
        let user = AuthUser(id: UUID(), email: "relay@privaterelay.appleid.com")
        client.signInWithAppleResult = .success(user)

        await service.signInWithApple(idToken: "jwt-token", rawNonce: "raw-nonce", displayName: "E Anthony")

        XCTAssertEqual(service.state, .signedIn(user))
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(client.signInWithAppleCallCount, 1)
        XCTAssertEqual(client.lastAppleIDToken, "jwt-token")
        XCTAssertEqual(client.lastAppleRawNonce, "raw-nonce")
        XCTAssertEqual(client.lastAppleDisplayName, "E Anthony")
    }

    func testSignInWithApple_failure_surfacesErrorAndLeavesStateUntouched() async {
        client.signInWithAppleResult = .failure(
            AuthServiceError.appleSignInFailed("Apple sign-in failed — please try again.")
        )

        await service.signInWithApple(idToken: "jwt-token", rawNonce: "raw-nonce", displayName: nil)

        XCTAssertEqual(service.errorMessage, "Apple sign-in failed — please try again.")
        XCTAssertEqual(service.state, .unknown)
    }

    func testSignInWithApple_clearsAPriorErrorOnSuccess() async {
        client.signInWithAppleResult = .failure(AuthServiceError.appleSignInFailed("first failure"))
        await service.signInWithApple(idToken: "t", rawNonce: "n", displayName: nil)
        XCTAssertNotNil(service.errorMessage)

        client.signInWithAppleResult = .success(AuthUser(id: UUID(), email: nil))
        await service.signInWithApple(idToken: "t", rawNonce: "n", displayName: nil)

        XCTAssertNil(service.errorMessage)
        if case .signedIn = service.state {} else {
            XCTFail("Expected signedIn state after the successful retry")
        }
    }
}
