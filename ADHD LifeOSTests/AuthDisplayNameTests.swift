//
//  AuthDisplayNameTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Setting a name AFTER sign-up (F-AccountName).
///
/// Settings' Name row was correct code E could never see fire: the name was written once, at
/// sign-up, and nothing could set it afterwards. Verified live rather than assumed (Firebase MCP,
/// 2026-08-28): E's Auth record predates `F-DisplayName` by nine days and carries no `displayName`
/// at all, so the feature was unreachable on the only account that matters.
@MainActor
final class AuthDisplayNameTests: XCTestCase {

    private func service(signedInAs user: AuthUser) -> (AuthService, FakeAuthClientAdapting) {
        let client = FakeAuthClientAdapting()
        client.restoredUserResult = user
        let service = AuthService(client: client)
        return (service, client)
    }

    private let uid = UUID()
    private var user: AuthUser { AuthUser(id: uid, email: "e@example.com", displayName: nil) }
    private func named(_ name: String) -> AuthUser {
        AuthUser(id: uid, email: "e@example.com", displayName: name)
    }

    /// The name reaches the client normalized, and the signed-in user updates so the row can
    /// appear without a round trip through sign-out.
    func testSettingANameOnAnAccountThatNeverHadOne() async {
        let (service, client) = service(signedInAs: user)
        await service.restoreSession()
        client.updateDisplayNameResult = .success(
            named("Ethan")
        )

        let saved = await service.updateDisplayName("  Ethan  ")

        XCTAssertTrue(saved)
        XCTAssertEqual(client.lastUpdatedDisplayName, "Ethan", "the raw value must be trimmed")
        XCTAssertEqual(service.signedInUser?.displayName, "Ethan")
        XCTAssertNil(service.errorMessage)
    }

    /// **`nil`, not `""`.** An empty string would be stored as a name the app then tries to greet
    /// you by — the whole reason `normalizedDisplayName` returns an optional. Clearing must reach
    /// the client as an explicit absence so the row disappears rather than rendering blank.
    func testClearingSendsNilRatherThanAnEmptyString() async {
        let existing = named("Ethan")
        let (service, client) = service(signedInAs: existing)
        await service.restoreSession()
        client.updateDisplayNameResult = .success(user)

        let saved = await service.updateDisplayName("   ")

        XCTAssertTrue(saved)
        XCTAssertTrue(client.updateDisplayNameCalled)
        XCTAssertNil(client.lastUpdatedDisplayName, "whitespace must clear the name, not store it")
        XCTAssertNil(service.signedInUser?.displayName, "the row must disappear, not render blank")
    }

    /// **The failure is REPORTED, not swallowed.** `signUp` commits the name to the Auth user with
    /// `try?`, which is why a name can sit in Firestore that the app can never show. This path
    /// must not repeat that: everything the app reads comes from the Auth user, so a failed commit
    /// has to be visible.
    func testAFailedWriteSurfacesAndLeavesTheNameAlone() async {
        let existing = named("Ethan")
        let (service, client) = service(signedInAs: existing)
        await service.restoreSession()
        client.updateDisplayNameResult = .failure(
            AuthServiceError.displayNameUpdateFailed("Network unavailable")
        )

        let saved = await service.updateDisplayName("Ethan A")

        XCTAssertFalse(saved)
        XCTAssertNotNil(service.errorMessage, "a failed name change must be reported")
        XCTAssertEqual(
            service.signedInUser?.displayName, "Ethan",
            "a failed write must not move the local name — that would be a lie about the server"
        )
    }

    /// The cap is `AuthFormValidation`'s, applied here too rather than re-derived — one rule.
    func testTheNameIsCappedByTheOneValidationRule() async {
        let (service, client) = service(signedInAs: user)
        await service.restoreSession()
        let long = String(repeating: "a", count: AuthFormValidation.maximumDisplayNameLength + 25)
        let capped = String(long.prefix(AuthFormValidation.maximumDisplayNameLength))
        client.updateDisplayNameResult = .success(
            named(capped)
        )

        _ = await service.updateDisplayName(long)

        XCTAssertEqual(
            client.lastUpdatedDisplayName?.count, AuthFormValidation.maximumDisplayNameLength
        )
    }

    /// Signed out there is nothing to rename, and the client must not be called at all.
    func testASignedOutSessionDoesNotCallTheClient() async {
        let client = FakeAuthClientAdapting()
        let service = AuthService(client: client)

        let saved = await service.updateDisplayName("Ethan")

        XCTAssertFalse(saved)
        XCTAssertFalse(client.updateDisplayNameCalled)
    }
}
