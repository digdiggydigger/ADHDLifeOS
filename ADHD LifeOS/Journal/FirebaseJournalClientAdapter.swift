//
//  FirebaseJournalClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `JournalClientAdapting` backed by Firestore through `JournalBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). `createLog`
/// stamps `entryDate` client-side as "now", matching the old server-side default and the
/// composer's lack of a date picker. Append-only stays structural: this adapter simply has no
/// update or delete path, same as the protocol.
struct FirebaseJournalClientAdapter: JournalClientAdapting {
    private let store: JournalBackingStore

    init(store: JournalBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        do {
            return try await store.fetchLifeAreas(includeArchived: true)
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLogs() async throws -> [Log] {
        do {
            return try await store.fetchLogs()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createLog(_ input: NormalizedCreateLogInput) async throws -> Log {
        let now = Date()
        let log = Log(
            id: UUID(),
            lifeAreaId: input.lifeAreaId,
            type: input.type,
            body: input.body,
            entryDate: now,
            createdAt: now,
            energyLevel: input.energyLevel,
            moodEmoji: input.moodEmoji
        )
        do {
            try await store.appendLog(log)
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
        return log
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
