//
//  JWTClaimsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class JWTClaimsTests: XCTestCase {

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func makeToken(sub: String, email: String?, exp: Int) throws -> String {
        let header = ["alg": "RS256", "typ": "JWT"]
        var payload: [String: Any] = ["sub": sub, "exp": exp]
        if let email {
            payload["email"] = email
        }
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let signature = Data("signature".utf8)

        return "\(base64URL(headerData)).\(base64URL(payloadData)).\(base64URL(signature))"
    }

    func testDecoding_validToken_decodesSubEmailExp() throws {
        let sub = UUID()
        let token = try makeToken(sub: sub.uuidString, email: "e@example.com", exp: 2_000_000_000)

        let claims = try JWTClaims(token: token)

        XCTAssertEqual(claims.sub, sub)
        XCTAssertEqual(claims.email, "e@example.com")
        XCTAssertEqual(claims.exp, Date(timeIntervalSince1970: 2_000_000_000))
    }

    func testDecoding_missingEmail_decodesNilEmail() throws {
        let sub = UUID()
        let token = try makeToken(sub: sub.uuidString, email: nil, exp: 2_000_000_000)

        let claims = try JWTClaims(token: token)

        XCTAssertNil(claims.email)
    }

    func testDecoding_malformedToken_notThreeSegments_throws() {
        XCTAssertThrowsError(try JWTClaims(token: "not.a.valid.jwt.token")) { error in
            XCTAssertEqual(error as? JWTClaims.DecodingError, .malformedToken)
        }
    }

    func testDecoding_truncatedBase64Payload_throws() {
        XCTAssertThrowsError(try JWTClaims(token: "aaa.!!!notbase64!!!.bbb")) { error in
            XCTAssertEqual(error as? JWTClaims.DecodingError, .malformedToken)
        }
    }

    func testDecoding_missingSubClaim_throws() throws {
        let payloadData = try JSONSerialization.data(withJSONObject: ["exp": 2_000_000_000])
        let signature = Data("sig".utf8)
        let token = "header.\(base64URL(payloadData)).\(base64URL(signature))"

        XCTAssertThrowsError(try JWTClaims(token: token)) { error in
            XCTAssertEqual(error as? JWTClaims.DecodingError, .missingRequiredClaim)
        }
    }
}
