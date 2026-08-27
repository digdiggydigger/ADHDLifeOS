//
//  FirebaseJournalClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `JournalClientAdapting` backed by Firestore through `JournalBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). `createLog`
/// stamps `entryDate` client-side as "now", matching the old server-side default and the
/// composer's lack of a date picker. No-rewriting stays structural: this adapter simply has no
/// update path, same as the protocol. `deleteLog` exists for capture triage's undo.
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

    func fetchFocusSessions() async throws -> [CompletedFocusSession] {
        do {
            return try await store.fetchFocusSessions()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchCaptures() async throws -> [Capture] {
        do {
            return try await store.fetchCaptures()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchLocationEvents() async throws -> [LocationEvent] {
        do {
            return try await store.fetchLocationEvents()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchPlaces() async throws -> [Place] {
        do {
            return try await store.fetchPlaces()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func fetchAllTags() async throws -> [Tag] {
        do {
            return try await store.fetchTags()
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    func createTag(name: String) async throws -> Tag {
        do {
            return try await store.createTagDeduplicating(name: name)
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
            moodEmoji: input.moodEmoji,
            // Tags ride the create — logs cannot be updated, so nil (key absent) beats an empty
            // array nothing could ever remove.
            tagIds: input.tagIds.isEmpty ? nil : input.tagIds,
            placeId: input.locationStamp?.placeId,
            latitude: input.locationStamp?.coordinate.latitude,
            longitude: input.locationStamp?.coordinate.longitude
        )
        do {
            try await store.appendLog(log)
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
        return log
    }

    func deleteLog(id: UUID) async throws {
        do {
            try await store.deleteLog(id: id)
        } catch {
            throw JournalServiceError.fetchFailed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
