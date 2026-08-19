//
//  FirebaseLifeAreaDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `LifeAreaDetailClientAdapting` backed by Firestore via `FirebaseManager`. Both
/// fetches are scoped server-side (`life_area_id` equality query), per the protocol's contract.
/// Logs come back newest-first; the equality query itself is unordered (a Firestore
/// where+order-on-another-field needs a composite index), so ordering happens here.
struct FirebaseLifeAreaDetailClientAdapter: LifeAreaDetailClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] {
        do {
            return try await manager.fetchTasks(lifeAreaId: lifeAreaId)
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] {
        do {
            return try await manager.fetchLogs(lifeAreaId: lifeAreaId)
                .sorted { $0.entryDate > $1.entryDate }
        } catch {
            throw LifeAreaDetailServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
