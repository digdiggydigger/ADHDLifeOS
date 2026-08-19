//
//  AppleSignInNonce.swift
//  ADHD LifeOS
//

import CryptoKit
import Foundation

/// Replay-protection nonce for Sign in with Apple, per Firebase's documented flow: a fresh
/// random nonce is generated per authorization request, its SHA-256 digest rides in the Apple
/// request (and comes back inside the signed identity token), and the RAW nonce goes to
/// Firebase — which hashes it and checks the two match, proving the token was minted for this
/// exact session and not replayed. Pure and host-free, so both halves are unit-testable.
enum AppleSignInNonce {
    /// The URL-safe charset from Firebase's reference implementation.
    private static let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

    /// Cryptographically-random session nonce. `SystemRandomNumberGenerator` is backed by the
    /// OS CSPRNG on Apple platforms; rejection sampling (only bytes < charset.count are used)
    /// keeps the draw unbiased.
    static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0, "Nonce length must be positive")
        var generator = SystemRandomNumberGenerator()
        var nonce = ""
        while nonce.count < length {
            let byte = UInt8.random(in: .min ... .max, using: &generator)
            if Int(byte) < charset.count {
                nonce.append(charset[Int(byte)])
            }
        }
        return nonce
    }

    /// Lowercase hex SHA-256 — the form Apple expects in `ASAuthorizationAppleIDRequest.nonce`.
    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
