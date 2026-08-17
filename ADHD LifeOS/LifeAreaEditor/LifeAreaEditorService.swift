//
//  LifeAreaEditorService.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// Owns the Life Area editor's list state and every mutation. Mutations are **serialised** — a
/// second write cannot begin while one is in flight (`isMutating`) — closing the superseded-response
/// race class fixed in `8e19a08`; the views also disable Save while `isMutating`. After any
/// successful mutation the list is **reloaded** from the server (a create adds a row, an archive
/// changes which section a row is in), rather than mutated locally.
@MainActor
final class LifeAreaEditorService: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var lifeAreas: [EditableLifeArea] = []
    @Published private(set) var isMutating = false
    /// Non-`nil` drives the create sheet's name-clash `.alert`; set only when a create returns `409`.
    @Published var pendingCreateConflict: LifeAreaNameConflict?
    /// Non-`nil` drives the detail screen's rename-clash `.alert`; set only when a rename returns `409`.
    @Published var pendingRenameConflict: LifeAreaNameConflict?
    /// A human-readable failure surfaced to the user; never a raw decoding error.
    @Published var errorMessage: String?
    /// A brief, non-error notice (e.g. "Archived" / "Unarchived" confirmation).
    @Published var infoMessage: String?

    private let client: LifeAreaEditorClientAdapting

    init(client: LifeAreaEditorClientAdapting) {
        self.client = client
    }

    /// The two list sections, derived from the single source of truth via the pure partition.
    var activeAreas: [EditableLifeArea] { LifeAreaEditorPresentation.partition(lifeAreas).active }
    var archivedAreas: [EditableLifeArea] { LifeAreaEditorPresentation.partition(lifeAreas).archived }

    func load() async {
        state = .loading
        do {
            lifeAreas = try await client.fetchLifeAreas()
            state = .loaded
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Save staged name/emoji edits from the detail screen. Sends only the fields that changed.
    /// Returns `true` when the detail screen should pop. A `409` sets `pendingRenameConflict` (drives
    /// the Cancel-only alert) and returns `false`, leaving the typed name intact.
    @discardableResult
    func saveEdits(to area: EditableLifeArea, name proposedName: String, colour proposedColour: String) async -> Bool {
        errorMessage = nil
        let trimmedName = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }   // Save is disabled here; write nothing.

        let nameToSend = trimmedName == area.name ? nil : trimmedName
        let colourToSend = proposedColour == area.colour ? nil : proposedColour
        guard nameToSend != nil || colourToSend != nil else { return true }  // nothing changed → pop.

        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        do {
            switch try await client.update(id: area.id, name: nameToSend, colour: colourToSend) {
            case .updated:
                await reload()
                return true
            case .nameConflict(let conflict):
                pendingRenameConflict = conflict
                return false
            }
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    func cancelRenameConflict() {
        pendingRenameConflict = nil
    }

    /// Archive or unarchive `area` immediately (E's locked "applies immediately" decision), then
    /// reload. Returns `true` so the detail screen can pop back to the list, where the row is now in
    /// its new section.
    @discardableResult
    func setArchived(_ area: EditableLifeArea, archived: Bool) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        errorMessage = nil
        do {
            try await client.setArchived(id: area.id, archived: archived)
            infoMessage = archived ? "Archived “\(area.name)”." : "Unarchived “\(area.name)”."
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// Create an area from the add sheet. A name clash is a real `409` here (no dedup): it sets
    /// `pendingCreateConflict` (drives the alert) and returns `false`. Returns `true` to dismiss.
    @discardableResult
    func create(name rawName: String, colour: String) async -> Bool {
        errorMessage = nil
        guard let name = LifeAreaEditorValidation.normalizeNewName(rawName) else { return false }
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        do {
            switch try await client.create(name: name, colour: colour) {
            case .created:
                await reload()
                return true
            case .nameConflict(let conflict):
                pendingCreateConflict = conflict
                return false
            }
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    /// The create sheet's "Unarchive it instead?" action: unarchive the conflicting area and create
    /// nothing. Returns `true` to dismiss the sheet.
    @discardableResult
    func unarchiveConflicting(_ conflict: LifeAreaNameConflict) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }
        errorMessage = nil
        do {
            try await client.setArchived(id: conflict.id, archived: false)
            pendingCreateConflict = nil
            infoMessage = "Unarchived “\(conflict.name)”."
            await reload()
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    func cancelCreateConflict() {
        pendingCreateConflict = nil
    }

    private func reload() async {
        do {
            lifeAreas = try await client.fetchLifeAreas()
        } catch {
            // The mutation itself succeeded; a reload failure is a soft error — surface it but keep
            // the screen usable rather than flipping the whole list into a failed state.
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
