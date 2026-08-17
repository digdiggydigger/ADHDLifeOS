//
//  FakeSecureTokenStoring.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeSecureTokenStoring: SecureTokenStoring, @unchecked Sendable {
    var stored: StoredTokens?
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    func load() -> StoredTokens? { stored }

    func save(_ tokens: StoredTokens) {
        saveCallCount += 1
        stored = tokens
    }

    func clear() {
        clearCallCount += 1
        stored = nil
    }
}
