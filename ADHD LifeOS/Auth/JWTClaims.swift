//
//  JWTClaims.swift
//  ADHD LifeOS
//

import Foundation

/// The subset of a Cognito ID token's claims this app needs. Decodes the JWT's payload segment
/// only (base64url + JSON) — no signature verification client-side, since API Gateway's JWT
/// authorizer is what actually verifies the signature server-side on every real API call; the
/// token only ever travels Cognito → this device → the API over TLS, so client-side verification
/// would be redundant defense with no attacker it defends against (see Stage C.1's design note).
struct JWTClaims: Equatable {
    let sub: UUID
    let email: String?
    let exp: Date

    enum DecodingError: Error, Equatable {
        case malformedToken
        case missingRequiredClaim
    }

    init(token: String) throws {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { throw DecodingError.malformedToken }

        guard let payloadData = Self.base64URLDecode(String(segments[1])) else {
            throw DecodingError.malformedToken
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        else {
            throw DecodingError.malformedToken
        }

        guard
            let subString = json["sub"] as? String,
            let sub = UUID(uuidString: subString),
            let expNumber = json["exp"] as? NSNumber
        else {
            throw DecodingError.missingRequiredClaim
        }

        self.sub = sub
        self.email = json["email"] as? String
        self.exp = Date(timeIntervalSince1970: expNumber.doubleValue)
    }

    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }
}
