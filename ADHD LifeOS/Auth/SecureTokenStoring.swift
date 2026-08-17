//
//  SecureTokenStoring.swift
//  ADHD LifeOS
//

import Foundation

/// The set of Cognito tokens `AWSAuthClientAdapter` persists between launches, plus the decoded
/// `exp` claim of the ID token so `validIDToken()` can check freshness without re-decoding the JWT.
struct StoredTokens: Equatable, Codable {
    let idToken: String
    let accessToken: String
    let refreshToken: String
    let idTokenExpiry: Date
}

/// Seam over token persistence so `AWSAuthClientAdapter` is unit-testable with a fake, mirroring
/// every other `*ClientAdapting` protocol's testability pattern in this codebase. The production
/// implementation stores tokens in the iOS Keychain (`kSecClassGenericPassword`) — the same
/// sensitivity class as a password, not `UserDefaults`.
protocol SecureTokenStoring: Sendable {
    func load() -> StoredTokens?
    func save(_ tokens: StoredTokens)
    func clear()
}

/// Production `SecureTokenStoring` backed by the iOS Keychain.
struct KeychainTokenStore: SecureTokenStoring {
    private let service: String
    private let account = "adhd-lifeos-cognito-tokens"

    init(service: String = "adhd-lifeos.cognito") {
        self.service = service
    }

    func load() -> StoredTokens? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }

    func save(_ tokens: StoredTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        clear()
        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
