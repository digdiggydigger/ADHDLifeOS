//
//  FirebaseLifeAreaEditorClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `LifeAreaEditorClientAdapting` backed by Firestore through
/// `LifeAreaEditorBackingStore` (`FirebaseManager` in the app, a recording fake in tests). The old
/// backend's `409` name-conflict semantics are reproduced client-side: a create/rename first
/// checks the (case-insensitively) colliding area and returns the same typed `.nameConflict`
/// outcomes, so the editor's "Unarchive it instead?" and merge-alert flows are unchanged. The
/// check-then-write pair isn't transactional — acceptable for a single-user collection where the
/// only concurrent writer is this same app.
struct FirebaseLifeAreaEditorClientAdapter: LifeAreaEditorClientAdapting {
    private let store: LifeAreaEditorBackingStore

    init(store: LifeAreaEditorBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchLifeAreas() async throws -> [EditableLifeArea] {
        do {
            return try await store.fetchLifeAreas(includeArchived: true).map(Self.editable)
        } catch {
            throw LifeAreaEditorServiceError.failed(Self.message(for: error))
        }
    }

    func update(id: UUID, name: String?, colour: String?) async throws -> LifeAreaUpdateOutcome {
        do {
            if let name, let conflict = try await conflictingArea(named: name, excludingId: id) {
                return .nameConflict(conflict)
            }
            var fields: [String: Any] = [:]
            if let name {
                fields["name"] = name
            }
            if let colour {
                fields["colour"] = colour
            }
            try await store.updateLifeArea(id: id, fields: fields)
            return .updated
        } catch {
            throw LifeAreaEditorServiceError.failed(Self.message(for: error))
        }
    }

    func setArchived(id: UUID, archived: Bool) async throws {
        do {
            try await store.updateLifeArea(id: id, fields: ["archived": archived])
        } catch {
            throw LifeAreaEditorServiceError.failed(Self.message(for: error))
        }
    }

    func create(name: String, colour: String) async throws -> LifeAreaCreateOutcome {
        do {
            let existing = try await store.fetchLifeAreas(includeArchived: true)
            if let clash = existing.first(where: { Self.sameName($0.name, name) }) {
                return .nameConflict(
                    LifeAreaNameConflict(id: clash.id, name: clash.name, archived: clash.archived)
                )
            }
            let area = LifeArea(
                id: UUID(),
                name: name,
                colour: colour,
                sortOrder: (existing.map(\.sortOrder).max() ?? -1) + 1
            )
            try await store.saveLifeArea(area)
            return .created(Self.editable(area))
        } catch {
            throw LifeAreaEditorServiceError.failed(Self.message(for: error))
        }
    }

    private func conflictingArea(named name: String, excludingId id: UUID) async throws -> LifeAreaNameConflict? {
        let clash = try await store.fetchLifeAreas(includeArchived: true)
            .first { $0.id != id && Self.sameName($0.name, name) }
        return clash.map { LifeAreaNameConflict(id: $0.id, name: $0.name, archived: $0.archived) }
    }

    private static func editable(_ area: LifeArea) -> EditableLifeArea {
        EditableLifeArea(
            id: area.id,
            name: area.name,
            colour: area.colour,
            sortOrder: area.sortOrder,
            archived: area.archived
        )
    }

    private static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.caseInsensitive]) == .orderedSame
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
