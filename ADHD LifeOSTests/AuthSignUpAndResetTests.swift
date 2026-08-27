//
//  AuthSignUpAndResetTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Creating an account and recovering one (E's 2026-08-28 design call: "full — signup + reset").
///
/// Until now the app could only SIGN IN, against an account that had to be created in the Firebase
/// console by hand — and there was no way back in from a forgotten password at all.
/// `FirebaseManager.signUp` already existed at the bottom of the stack; it was simply never exposed
/// through `AuthBackingStore` / `AuthClientAdapting` / `AuthService`, so nothing could reach it.
///
/// The form rules are pure and live in `AuthFormValidation` so the segmented Sign in | Create
/// account screen has one source of truth for what enables its button.
final class AuthSignUpAndResetTests: XCTestCase {

    // MARK: - The form rules

    func testEmail_isTrimmedAndMustLookLikeAnAddress() {
        XCTAssertEqual(AuthFormValidation.normalizedEmail("  e@example.com "), "e@example.com")
        XCTAssertNil(AuthFormValidation.normalizedEmail(""))
        XCTAssertNil(AuthFormValidation.normalizedEmail("   "))
        XCTAssertNil(AuthFormValidation.normalizedEmail("not-an-address"))
        XCTAssertNil(AuthFormValidation.normalizedEmail("@example.com"))
        XCTAssertNil(AuthFormValidation.normalizedEmail("e@"))
        XCTAssertNil(AuthFormValidation.normalizedEmail("e@example"), "a domain needs a dot")
        XCTAssertNil(AuthFormValidation.normalizedEmail("two@at@example.com"))
        XCTAssertNil(AuthFormValidation.normalizedEmail("spaced address@example.com"))
    }

    /// Sign-in accepts any non-empty password — the stored one predates whatever rule we impose
    /// today, and second-guessing it at the door would lock someone out of their own account.
    func testCanSubmit_signIn_needsAPlausibleEmailAndSomePassword() {
        XCTAssertTrue(AuthFormValidation.canSubmit(mode: .signIn, email: "e@example.com", password: "x"))
        XCTAssertFalse(AuthFormValidation.canSubmit(mode: .signIn, email: "e@example.com", password: ""))
        XCTAssertFalse(AuthFormValidation.canSubmit(mode: .signIn, email: "nope", password: "correct-horse"))
    }

    /// Creating one is the moment the rule can be enforced, so it is — at Firebase's own floor.
    func testCanSubmit_createAccount_enforcesThePasswordFloor() {
        XCTAssertFalse(
            AuthFormValidation.canSubmit(mode: .createAccount, email: "e@example.com", password: "short"),
            "five characters is under Firebase's own minimum and would fail server-side"
        )
        XCTAssertTrue(
            AuthFormValidation.canSubmit(mode: .createAccount, email: "e@example.com", password: "sixchr")
        )
    }

    func testPasswordFloor_matchesFirebases() {
        XCTAssertEqual(AuthFormValidation.minimumPasswordLength, 6)
    }

    /// Said out loud while typing rather than after a failed round trip.
    func testPasswordHint_onlyNagsWhileCreatingAndOnlyOnceTypingStarts() {
        XCTAssertNil(AuthFormValidation.passwordHint(mode: .createAccount, password: ""))
        XCTAssertNotNil(AuthFormValidation.passwordHint(mode: .createAccount, password: "abc"))
        XCTAssertNil(AuthFormValidation.passwordHint(mode: .createAccount, password: "sixchr"))
        XCTAssertNil(
            AuthFormValidation.passwordHint(mode: .signIn, password: "abc"),
            "signing in never lectures about a password that already exists"
        )
    }

    /// Optional on purpose: nothing in the app displays a name yet, and blocking account creation
    /// on one would be hostile in an app whose composer says every detail is optional.
    func testDisplayName_isTrimmedToNilAndCapped() {
        XCTAssertEqual(AuthFormValidation.normalizedDisplayName("  Ethan  "), "Ethan")
        XCTAssertNil(AuthFormValidation.normalizedDisplayName("   "))
        XCTAssertNil(AuthFormValidation.normalizedDisplayName(""))
        XCTAssertEqual(
            AuthFormValidation.normalizedDisplayName(String(repeating: "e", count: 200))?.count,
            AuthFormValidation.maximumDisplayNameLength,
            "truncated rather than rejected — silently discarding what E typed is worse"
        )
    }

    func testCanRequestReset_needsOnlyAPlausibleEmail() {
        XCTAssertTrue(AuthFormValidation.canRequestReset(email: " e@example.com "))
        XCTAssertFalse(AuthFormValidation.canRequestReset(email: ""))
        XCTAssertFalse(AuthFormValidation.canRequestReset(email: "nope"))
    }

    // MARK: - The service

    @MainActor
    func testSignUp_success_signsStraightIn() async {
        let client = FakeAuthClientAdapting()
        let user = AuthUser(id: UUID(), email: "e@example.com")
        client.signUpResult = .success(user)
        let sut = AuthService(client: client)

        await sut.signUp(email: "  e@example.com ", password: "sixchr", displayName: "  Ethan ")

        XCTAssertEqual(sut.state, .signedIn(user), "creating an account IS signing in — no second step")
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(client.lastSignUpEmail, "e@example.com", "trimmed before it reaches the network")
        XCTAssertEqual(client.lastSignUpDisplayName, "Ethan")
    }

    @MainActor
    func testSignUp_blankName_sendsNoName() async {
        let client = FakeAuthClientAdapting()
        client.signUpResult = .success(AuthUser(id: UUID(), email: "e@example.com"))
        let sut = AuthService(client: client)

        await sut.signUp(email: "e@example.com", password: "sixchr", displayName: "   ")

        XCTAssertNil(client.lastSignUpDisplayName, "a blank field must write no name, not an empty one")
    }

    @MainActor
    func testSignUp_failure_reportsAndStaysSignedOut() async {
        let client = FakeAuthClientAdapting()
        client.signUpResult = .failure(AuthServiceError.signUpFailed("That email is already in use."))
        let sut = AuthService(client: client)

        await sut.signUp(email: "e@example.com", password: "sixchr", displayName: nil)

        XCTAssertEqual(sut.errorMessage, "That email is already in use.")
        XCTAssertEqual(sut.state, .unknown, "a failed sign-up must not claim a session")
    }

    /// The confirmation is deliberately the same whether or not the account exists — saying "no
    /// such account" would turn the screen into an email-enumeration oracle.
    @MainActor
    func testSendPasswordReset_success_confirmsWithoutRevealingWhetherTheAccountExists() async {
        let client = FakeAuthClientAdapting()
        client.sendPasswordResetResult = .success(())
        let sut = AuthService(client: client)

        await sut.sendPasswordReset(email: "  e@example.com ")

        XCTAssertEqual(sut.passwordResetSentTo, "e@example.com")
        XCTAssertEqual(client.lastPasswordResetEmail, "e@example.com")
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func testSendPasswordReset_implausibleEmail_neverReachesTheNetwork() async {
        let client = FakeAuthClientAdapting()
        let sut = AuthService(client: client)

        await sut.sendPasswordReset(email: "nope")

        XCTAssertEqual(client.sendPasswordResetCallCount, 0)
        XCTAssertNil(sut.passwordResetSentTo)
        XCTAssertNotNil(sut.errorMessage, "the screen has to say why nothing happened")
    }

    @MainActor
    func testSendPasswordReset_failure_reportsAndConfirmsNothing() async {
        let client = FakeAuthClientAdapting()
        client.sendPasswordResetResult = .failure(
            AuthServiceError.passwordResetFailed("Couldn't send the reset email.")
        )
        let sut = AuthService(client: client)

        await sut.sendPasswordReset(email: "e@example.com")

        XCTAssertEqual(sut.errorMessage, "Couldn't send the reset email.")
        XCTAssertNil(sut.passwordResetSentTo)
    }

    /// Switching the segmented control must clear whatever the other mode left on screen —
    /// a stale "reset link sent" hanging over the Create form is a lie about what just happened.
    @MainActor
    func testClearingTransientMessages_wipesBothErrorAndConfirmation() async {
        let client = FakeAuthClientAdapting()
        client.sendPasswordResetResult = .success(())
        let sut = AuthService(client: client)
        await sut.sendPasswordReset(email: "e@example.com")

        sut.clearTransientMessages()

        XCTAssertNil(sut.passwordResetSentTo)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - The adapter

    func testAdapter_signUp_passesTheNameThroughAndProjectsTheUser() async throws {
        let store = FakeAuthBackingStore()
        store.signUpResult = FirebaseAuthUser(uid: "uid-new", email: "e@example.com")
        let adapter = FirebaseAuthClientAdapter(store: store)

        let user = try await adapter.signUp(
            email: "e@example.com", password: "sixchr", displayName: "Ethan"
        )

        XCTAssertEqual(user.email, "e@example.com")
        XCTAssertEqual(store.signUpCredentials.first?.email, "e@example.com")
        XCTAssertEqual(store.signUpCredentials.first?.displayName, "Ethan")
    }

    func testAdapter_signUp_failureBecomesASignUpError() async {
        let store = FakeAuthBackingStore()
        store.signUpError = NSError(
            domain: "FIRAuthErrorDomain", code: 17_007,
            userInfo: [NSLocalizedDescriptionKey: "The email address is already in use."]
        )
        let adapter = FirebaseAuthClientAdapter(store: store)

        do {
            _ = try await adapter.signUp(email: "e@example.com", password: "sixchr", displayName: nil)
            XCTFail("Expected the sign-up to throw")
        } catch {
            XCTAssertEqual(
                error as? AuthServiceError,
                .signUpFailed("The email address is already in use.")
            )
        }
    }

    func testAdapter_sendPasswordReset_reachesTheStore() async throws {
        let store = FakeAuthBackingStore()
        let adapter = FirebaseAuthClientAdapter(store: store)

        try await adapter.sendPasswordReset(email: "e@example.com")

        XCTAssertEqual(store.passwordResetEmails, ["e@example.com"])
    }

    func testAdapter_sendPasswordReset_failureBecomesAResetError() async {
        let store = FakeAuthBackingStore()
        store.passwordResetError = NSError(
            domain: "FIRAuthErrorDomain", code: 17_020,
            userInfo: [NSLocalizedDescriptionKey: "Network error."]
        )
        let adapter = FirebaseAuthClientAdapter(store: store)

        do {
            try await adapter.sendPasswordReset(email: "e@example.com")
            XCTFail("Expected the reset to throw")
        } catch {
            XCTAssertEqual(error as? AuthServiceError, .passwordResetFailed("Network error."))
        }
    }
}
