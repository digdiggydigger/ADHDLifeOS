//
//  FakeTagEditorClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// In-memory `TagEditorClientAdapting` for unit tests. Records call counts and lets each method's
/// result be scripted, including a `409` (`.needsMerge`) rename and a `204` delete — the two cases
/// the block calls out as must-be-testable. `fetchResults` can be a queue so a mutation's reload
/// observes a different list than the initial load.
final class FakeTagEditorClientAdapting: TagEditorClientAdapting, @unchecked Sendable {
    /// Successive `fetchTags()` results, consumed front-to-back; the last one repeats once drained.
    var fetchResults: [Result<[EditableTag], Error>] = [.success([])]
    var renameResult: Result<TagRenameOutcome, Error> = .success(.renamed)
    var mergeResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    var createResult: Result<TagCreateOutcome, Error> = .success(
        .created(EditableTag(id: UUID(), name: "new", usageCount: 0))
    )

    private(set) var fetchCallCount = 0
    private(set) var renameCallCount = 0
    private(set) var mergeCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var createCallCount = 0
    private(set) var lastRenameName: String?
    private(set) var lastRenameId: UUID?
    private(set) var lastMergeName: String?
    private(set) var lastDeleteId: UUID?
    private(set) var lastCreateName: String?

    /// Optional suspension point run at the start of `deleteTag`, so a test can hold a mutation
    /// in flight and prove a second one is rejected (serialisation).
    var beforeDelete: (@Sendable () async -> Void)?

    func fetchTags() async throws -> [EditableTag] {
        defer { fetchCallCount += 1 }
        let index = min(fetchCallCount, fetchResults.count - 1)
        return try fetchResults[index].get()
    }

    func renameTag(id: UUID, to name: String) async throws -> TagRenameOutcome {
        renameCallCount += 1
        lastRenameId = id
        lastRenameName = name
        return try renameResult.get()
    }

    func mergeTag(id: UUID, into name: String) async throws {
        mergeCallCount += 1
        lastMergeName = name
        try mergeResult.get()
    }

    func deleteTag(id: UUID) async throws {
        deleteCallCount += 1
        lastDeleteId = id
        if let beforeDelete {
            await beforeDelete()
        }
        try deleteResult.get()
    }

    func createTag(name: String) async throws -> TagCreateOutcome {
        createCallCount += 1
        lastCreateName = name
        return try createResult.get()
    }
}
