//
//  AppleSignInNonceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Sign in with Apple replay-protection nonce, per Firebase's documented flow: a random
/// session nonce whose SHA-256 hex digest is sent to Apple, while the raw value goes to
/// Firebase for verification. The digest must be canonical SHA-256 (locked with NIST test
/// vectors) and the raw nonce must stay within the URL-safe charset Apple round-trips intact.
final class AppleSignInNonceTests: XCTestCase {
    // MARK: - SHA-256 hex digest (NIST vectors)

    func testSHA256Hex_matchesKnownVectors() {
        XCTAssertEqual(
            AppleSignInNonce.sha256Hex("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
        XCTAssertEqual(
            AppleSignInNonce.sha256Hex(""),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }

    func testSHA256Hex_isLowercaseAnd64Chars() {
        let digest = AppleSignInNonce.sha256Hex("any input at all")
        XCTAssertEqual(digest.count, 64)
        XCTAssertEqual(digest, digest.lowercased())
    }

    // MARK: - Random session nonce

    func testRandomNonce_defaultsTo32Characters() {
        XCTAssertEqual(AppleSignInNonce.randomNonce().count, 32)
    }

    func testRandomNonce_honoursRequestedLength() {
        XCTAssertEqual(AppleSignInNonce.randomNonce(length: 16).count, 16)
        XCTAssertEqual(AppleSignInNonce.randomNonce(length: 64).count, 64)
    }

    func testRandomNonce_usesOnlyTheDocumentedCharset() {
        let allowed = Set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = AppleSignInNonce.randomNonce(length: 256)
        XCTAssertTrue(nonce.allSatisfy { allowed.contains($0) })
    }

    func testRandomNonce_isNotRepeated() {
        // Probabilistic, but a collision over 64^32 keyspace means the generator is broken.
        XCTAssertNotEqual(AppleSignInNonce.randomNonce(), AppleSignInNonce.randomNonce())
    }
}
