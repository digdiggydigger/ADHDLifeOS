//
//  FirebaseLifeAreaDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `LifeAreaDetailClientAdapting` backed by Firestore through `LifeAreaDetailBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Both
/// fetches are scoped server-side (`life_area_id` equality query), per the protocol's contract.
/// Logs come back newest-first; the equality query itself is unordered (a Firestore
/// where+order-on-another-field needs a composite index), so ordering happens here.
struct FirebaseLifeAreaDetailClientAdapter: LifeAreaDetailClientAdapting {
    private let store: LifeAreaDetailBackingStore

    init(store: LifeAreaDetailBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        do {
            return try await store.fetchTasks(lifeAreaId: lifeAreaId)
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        do {
            return try await store.fetchLogs(lifeAreaId: lifeAreaId)
                .sorted { $0.entryDate > $1.entryDate }
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
