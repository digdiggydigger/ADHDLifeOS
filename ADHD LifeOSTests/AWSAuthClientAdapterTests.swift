//
//  AWSAuthClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class AWSAuthClientAdapterTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeToken(sub: UUID = UUID(), email: String? = "e@example.com", exp: Date) throws -> String {
        var payload: [String: Any] = ["sub": sub.uuidString, "exp": Int(exp.timeIntervalSince1970)]
        if let email { payload["email"] = email }

        let headerData = try JSONSerialization.data(withJSONObject: ["alg": "none"])
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let signature = Data("sig".utf8)

        func base64URL(_ data: Data) -> String {
            data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        return "\(base64URL(headerData)).\(base64URL(payloadData)).\(base64URL(signature))"
    }

    private func makeAdapter(store: SecureTokenStoring) -> AWSAuthClientAdapter {
        AWSAuthClientAdapter(
            session: MockURLProtocol.makeSession(),
            baseURL: URL(string: "https://cognito-idp.us-east-1.amazonaws.com/")!,
            clientID: "test-client-id",
            store: store
        )
    }

    private func jsonResponse(_ statusCode: Int, _ body: [String: Any]) throws -> (HTTPURLResponse, Data) {
        let data = try JSONSerialization.data(withJSONObject: body)
        guard
            let response = HTTPURLResponse(
                url: URL(string: "https://cognito-idp.us-east-1.amazonaws.com/")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        else {
            throw URLError(.badServerResponse)
        }
        return (response, data)
    }

    func testSignIn_success_storesTokensAndReturnsUser() async throws {
        let sub = UUID()
        let idToken = try makeToken(sub: sub, email: "e@example.com", exp: Date().addingTimeInterval(3600))
        MockURLProtocol.requestHandler = { [self] _ in
            try jsonResponse(200, [
                "AuthenticationResult": [
                    "IdToken": idToken,
                    "AccessToken": "access-token",
                    "RefreshToken": "refresh-token",
                    "ExpiresIn": 3600
                ]
            ])
        }
        let store = FakeSecureTokenStoring()
        let sut = makeAdapter(store: store)

        let user = try await sut.signIn(email: "e@example.com", password: "correct-horse")

        XCTAssertEqual(user.id, sub)
        XCTAssertEqual(user.email, "e@example.com")
        XCTAssertEqual(store.stored?.idToken, idToken)
        XCTAssertEqual(store.stored?.accessToken, "access-token")
        XCTAssertEqual(store.stored?.refreshToken, "refresh-token")
        XCTAssertEqual(store.saveCallCount, 1)
    }

    func testSignIn_notAuthorizedException_surfacesMappedErrorMessage() async throws {
        MockURLProtocol.requestHandler = { [self] _ in
            try jsonResponse(400, [
                "__type": "NotAuthorizedException",
                "message": "Incorrect username or password."
            ])
        }
        let sut = makeAdapter(store: FakeSecureTokenStoring())

        do {
            _ = try await sut.signIn(email: "e@example.com", password: "wrong")
            XCTFail("Expected signIn to throw")
        } catch let AuthServiceError.invalidCredentials(message) {
            XCTAssertEqual(message, "Incorrect email or password.")
        } catch {
            XCTFail("Expected AuthServiceError.invalidCredentials, got \(error)")
        }
    }

    func testValidIDToken_freshCachedToken_returnsWithoutRefreshing() async throws {
        let idToken = try makeToken(exp: Date().addingTimeInterval(3600))
        let store = FakeSecureTokenStoring()
        store.stored = StoredTokens(
            idToken: idToken,
            accessToken: "access",
            refreshToken: "refresh",
            idTokenExpiry: Date().addingTimeInterval(3600)
        )
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Should not call the network for a fresh token")
            throw URLError(.unknown)
        }
        let sut = makeAdapter(store: store)

        let token = try await sut.validIDToken()

        XCTAssertEqual(token, idToken)
    }

    func testValidIDToken_withinRefreshBuffer_refreshesAndReturnsNewToken() async throws {
        let store = FakeSecureTokenStoring()
        store.stored = StoredTokens(
            idToken: "stale-token",
            accessToken: "access",
            refreshToken: "refresh-token",
            idTokenExpiry: Date().addingTimeInterval(60) // inside the 5-minute buffer
        )
        let newIDToken = try makeToken(exp: Date().addingTimeInterval(3600))
        MockURLProtocol.requestHandler = { [self] request in
            guard
                let bodyData = MockURLProtocol.body(of: request),
                let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            else {
                XCTFail("Expected a JSON request body")
                throw URLError(.badURL)
            }
            XCTAssertEqual(body["AuthFlow"] as? String, "REFRESH_TOKEN_AUTH")
            return try jsonResponse(200, [
                "AuthenticationResult": [
                    "IdToken": newIDToken,
                    "AccessToken": "new-access-token"
                ]
            ])
        }
        let sut = makeAdapter(store: store)

        let token = try await sut.validIDToken()

        XCTAssertEqual(token, newIDToken)
        XCTAssertEqual(store.stored?.refreshToken, "refresh-token", "no new refresh token returned, keep the old one")
        XCTAssertEqual(store.saveCallCount, 1)
    }

    func testValidIDToken_refreshFails_throwsAndClearsStore() async throws {
        let store = FakeSecureTokenStoring()
        store.stored = StoredTokens(
            idToken: "stale-token",
            accessToken: "access",
            refreshToken: "revoked-refresh-token",
            idTokenExpiry: Date().addingTimeInterval(-10)
        )
        MockURLProtocol.requestHandler = { [self] _ in
            try jsonResponse(400, ["__type": "NotAuthorizedException", "message": "Refresh Token has been revoked"])
        }
        let sut = makeAdapter(store: store)

        do {
            _ = try await sut.validIDToken()
            XCTFail("Expected validIDToken to throw")
        } catch {
            // expected
        }

        XCTAssertNil(store.load(), "store should be cleared after a failed refresh")
    }

    func testRestoredUser_noStoredSession_returnsNil() async {
        let sut = makeAdapter(store: FakeSecureTokenStoring())

        let user = await sut.restoredUser()

        XCTAssertNil(user)
    }

    func testRestoredUser_validStoredSession_returnsUser() async throws {
        let sub = UUID()
        let idToken = try makeToken(sub: sub, email: "e@example.com", exp: Date().addingTimeInterval(3600))
        let store = FakeSecureTokenStoring()
        store.stored = StoredTokens(
            idToken: idToken,
            accessToken: "access",
            refreshToken: "refresh",
            idTokenExpiry: Date().addingTimeInterval(3600)
        )
        let sut = makeAdapter(store: store)

        let user = await sut.restoredUser()

        XCTAssertEqual(user?.id, sub)
    }

    func testSignOut_clearsStoreRegardlessOfNetworkResult() async throws {
        let store = FakeSecureTokenStoring()
        store.stored = StoredTokens(
            idToken: "id",
            accessToken: "access",
            refreshToken: "refresh",
            idTokenExpiry: Date().addingTimeInterval(3600)
        )
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let sut = makeAdapter(store: store)

        try await sut.signOut()

        XCTAssertNil(store.load())
        XCTAssertEqual(store.clearCallCount, 1)
    }

    func testRequestOTP_throwsMagicLinkUnavailable() async {
        let sut = makeAdapter(store: FakeSecureTokenStoring())

        do {
            try await sut.requestOTP(email: "e@example.com", redirectTo: nil)
            XCTFail("Expected requestOTP to throw")
        } catch AuthServiceError.magicLinkUnavailable {
            // expected
        } catch {
            XCTFail("Expected magicLinkUnavailable, got \(error)")
        }
    }

    func testCompleteSession_throwsMagicLinkUnavailable() async {
        let sut = makeAdapter(store: FakeSecureTokenStoring())

        do {
            _ = try await sut.completeSession(from: URL(string: "adhdlifeos://auth-callback")!)
            XCTFail("Expected completeSession to throw")
        } catch AuthServiceError.magicLinkUnavailable {
            // expected
        } catch {
            XCTFail("Expected magicLinkUnavailable, got \(error)")
        }
    }
}
