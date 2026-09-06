//
//  AuthServiceSessionEndTests.swift
//  ADHD LifeOSTests
//
//  The other half of the run-store leak fix (F-RoutineRecord-1): a session ending clears the
//  app-local caches that carry one user's places. Two ways a session ends, both hooked —
//  and the hook fires BEFORE the client signs out, while the account is still known.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class AuthServiceSessionEndTests: XCTestCase {

    func testSignOut_clearsLocalSessionStateBeforeTheClientSignsOut() async {
        let fake = FakeAuthClientAdapting()
        var order: [String] = []
        fake.onSignOut = { order.append("client") }
        let sut = AuthService(client: fake, onSessionEnding: { order.append("hook") })

        await sut.signOut()

        XCTAssertEqual(order, ["hook", "client"])
    }

    func testCompleteAccountDeletion_clearsLocalSessionState() {
        let fake = FakeAuthClientAdapting()
        var hookCount = 0
        let sut = AuthService(client: fake, onSessionEnding: { hookCount += 1 })

        sut.completeAccountDeletion()

        XCTAssertEqual(hookCount, 1)
    }

    func testSignIn_doesNotFireTheHook() async {
        let fake = FakeAuthClientAdapting()
        var hookCount = 0
        let sut = AuthService(client: fake, onSessionEnding: { hookCount += 1 })

        await sut.signIn(email: "e@example.com", password: "password-1")

        XCTAssertEqual(hookCount, 0)
    }
}
