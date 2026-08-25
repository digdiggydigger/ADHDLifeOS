//
//  FakeLifeAreaEditorClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// In-memory `LifeAreaEditorClientAdapting` for unit tests. Each method's result is scriptable —
/// including a `409` (`.nameConflict`) create/update with `archived` both true and false, a `201`,
/// and a failure — the cases the block requires the fake to cover. `fetchResults` is a queue so a
/// mutation's reload can observe a different list than the initial load.
final class FakeLifeAreaEditorClientAdapting: LifeAreaEditorClientAdapting, @unchecked Sendable {
    /// Successive `fetchLifeAreas()` results, consumed front-to-back; the last one repeats once drained.
    var fetchResults: [Result<[EditableLifeArea], Error>] = [.success([])]
    var updateResult: Result<LifeAreaUpdateOutcome, Error> = .success(.updated)
    var setArchivedResult: Result<Void, Error> = .success(())
    var createResult: Result<LifeAreaCreateOutcome, Error> = .success(
        .created(EditableLifeArea(id: UUID(), name: "new", colour: "🏠", sortOrder: 1, archived: false))
    )

    private(set) var fetchCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var setArchivedCallCount = 0
    private(set) var createCallCount = 0
    private(set) var lastUpdateId: UUID?
    private(set) var lastUpdateName: String??
    private(set) var lastUpdateColour: String??
    private(set) var lastUpdatePalette: LifeAreaPaletteEdit?
    private(set) var lastSetArchivedId: UUID?
    private(set) var lastSetArchivedValue: Bool?
    private(set) var lastCreateName: String?
    private(set) var lastCreateColour: String?

    /// Optional suspension point run at the start of `setArchived`, so a test can hold a mutation in
    /// flight and prove a second one is rejected (serialisation).
    var beforeSetArchived: (@Sendable () async -> Void)?

    func fetchLifeAreas() async throws -> [EditableLifeArea] {
        defer { fetchCallCount += 1 }
        let index = min(fetchCallCount, fetchResults.count - 1)
        return try fetchResults[index].get()
    }

    func update(
        id: UUID, name: String?, colour: String?, palette: LifeAreaPaletteEdit
    ) async throws -> LifeAreaUpdateOutcome {
        updateCallCount += 1
        lastUpdateId = id
        lastUpdateName = name
        lastUpdateColour = colour
        lastUpdatePalette = palette
        return try updateResult.get()
    }

    func setArchived(id: UUID, archived: Bool) async throws {
        setArchivedCallCount += 1
        lastSetArchivedId = id
        lastSetArchivedValue = archived
        if let beforeSetArchived {
            await beforeSetArchived()
        }
        try setArchivedResult.get()
    }

    func create(name: String, colour: String) async throws -> LifeAreaCreateOutcome {
        createCallCount += 1
        lastCreateName = name
        lastCreateColour = colour
        return try createResult.get()
    }
}
