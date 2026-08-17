//
//  TagEditorServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TagEditorServiceTests: XCTestCase {

    private func tag(_ name: String, usage: Int = 0, id: UUID = UUID()) -> EditableTag {
        EditableTag(id: id, name: name, usageCount: usage)
    }

    // MARK: load

    func test_load_sortsCaseInsensitivelyByName() async {
        let fake = FakeTagEditorClientAdapting()
        fake.fetchResults = [.success([tag("Banana"), tag("apple"), tag("Cherry")])]
        let service = TagEditorService(client: fake)

        await service.load()

        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.tags.map(\.name), ["apple", "Banana", "Cherry"])
    }

    func test_load_failure_setsFailedStateWithMessage() async {
        let fake = FakeTagEditorClientAdapting()
        fake.fetchResults = [.failure(TagEditorServiceError.failed("boom"))]
        let service = TagEditorService(client: fake)

        await service.load()

        XCTAssertEqual(service.state, .failed("boom"))
    }

    // MARK: rename

    func test_rename_valid_renames_reloads_andReturnsTrue() async {
        let fake = FakeTagEditorClientAdapting()
        let target = tag("work")
        fake.fetchResults = [.success([target]), .success([tag("errands")])]
        fake.renameResult = .success(.renamed)
        let service = TagEditorService(client: fake)
        await service.load()

        let shouldPop = await service.rename(tag: target, to: "errands")

        XCTAssertTrue(shouldPop)
        XCTAssertEqual(fake.renameCallCount, 1)
        XCTAssertEqual(fake.lastRenameName, "errands")
        XCTAssertEqual(fake.fetchCallCount, 2, "rename success must reload the list")
        XCTAssertNil(service.pendingMergeConflict)
    }

    func test_rename_conflict_setsPendingMerge_writesNothing_returnsFalse() async {
        let fake = FakeTagEditorClientAdapting()
        let target = tag("work")
        fake.fetchResults = [.success([target])]
        let conflict = TagRenameConflict(id: UUID(), name: "errands", usageCount: 7)
        fake.renameResult = .success(.needsMerge(conflict))
        let service = TagEditorService(client: fake)
        await service.load()

        let shouldPop = await service.rename(tag: target, to: "errands")

        XCTAssertFalse(shouldPop)
        XCTAssertEqual(service.pendingMergeConflict, conflict)
        XCTAssertEqual(fake.mergeCallCount, 0, "a 409 must not merge on its own")
        XCTAssertEqual(fake.fetchCallCount, 1, "a 409 writes nothing and must not reload")
    }

    func test_rename_unchangedName_doesNotCallAdapter() async {
        let fake = FakeTagEditorClientAdapting()
        let target = tag("work")
        fake.fetchResults = [.success([target])]
        let service = TagEditorService(client: fake)
        await service.load()

        let shouldPop = await service.rename(tag: target, to: "  work  ")

        XCTAssertFalse(shouldPop)
        XCTAssertEqual(fake.renameCallCount, 0)
    }

    // MARK: merge / cancel

    func test_confirmMerge_merges_reloads_clearsConflict() async {
        let fake = FakeTagEditorClientAdapting()
        let loser = tag("work")
        fake.fetchResults = [.success([loser]), .success([tag("errands", usage: 8)])]
        let service = TagEditorService(client: fake)
        await service.load()
        service.pendingMergeConflict = TagRenameConflict(id: UUID(), name: "errands", usageCount: 7)

        let shouldPop = await service.confirmMerge(tag: loser, into: "errands")

        XCTAssertTrue(shouldPop)
        XCTAssertEqual(fake.mergeCallCount, 1)
        XCTAssertEqual(fake.lastMergeName, "errands")
        XCTAssertEqual(fake.fetchCallCount, 2, "merge must reload — the survivor's count changed")
        XCTAssertNil(service.pendingMergeConflict)
    }

    func test_cancelMerge_writesNothing() async {
        let fake = FakeTagEditorClientAdapting()
        let service = TagEditorService(client: fake)
        service.pendingMergeConflict = TagRenameConflict(id: UUID(), name: "errands", usageCount: 3)

        service.cancelMerge()

        XCTAssertNil(service.pendingMergeConflict)
        XCTAssertEqual(fake.mergeCallCount, 0)
    }

    // MARK: delete

    func test_delete_deletes_reloads_andListShrinks() async {
        let fake = FakeTagEditorClientAdapting()
        let victim = tag("work")
        fake.fetchResults = [.success([victim, tag("errands")]), .success([tag("errands")])]
        let service = TagEditorService(client: fake)
        await service.load()
        XCTAssertEqual(service.tags.count, 2)

        let shouldPop = await service.delete(tag: victim)

        XCTAssertTrue(shouldPop)
        XCTAssertEqual(fake.deleteCallCount, 1)
        XCTAssertEqual(fake.lastDeleteId, victim.id)
        XCTAssertEqual(service.tags.map(\.name), ["errands"], "delete must reload the shrunk list")
    }

    // MARK: create

    func test_create_created_reloads_noInfoMessage() async {
        let fake = FakeTagEditorClientAdapting()
        fake.fetchResults = [.success([]), .success([tag("errands")])]
        fake.createResult = .success(.created(tag("errands")))
        let service = TagEditorService(client: fake)
        await service.load()

        let shouldDismiss = await service.create(name: "errands")

        XCTAssertTrue(shouldDismiss)
        XCTAssertEqual(fake.createCallCount, 1)
        XCTAssertEqual(fake.lastCreateName, "errands")
        XCTAssertNil(service.infoMessage)
        XCTAssertEqual(service.tags.map(\.name), ["errands"])
    }

    func test_create_alreadyExisted_surfacesInfo_noDuplicate() async {
        let fake = FakeTagEditorClientAdapting()
        let existing = tag("errands", usage: 4)
        fake.fetchResults = [.success([existing]), .success([existing])]
        fake.createResult = .success(.alreadyExisted(existing))
        let service = TagEditorService(client: fake)
        await service.load()

        let shouldDismiss = await service.create(name: "errands")

        XCTAssertTrue(shouldDismiss)
        XCTAssertEqual(service.infoMessage, "\"errands\" already exists.")
        XCTAssertEqual(service.tags.count, 1, "dedup must not add a phantom duplicate row")
    }

    func test_create_emptyName_doesNotCallAdapter() async {
        let fake = FakeTagEditorClientAdapting()
        let service = TagEditorService(client: fake)

        let shouldDismiss = await service.create(name: "   ")

        XCTAssertFalse(shouldDismiss)
        XCTAssertEqual(fake.createCallCount, 0)
    }

    // MARK: serialisation (the 8e19a08 race class)

    func test_secondMutationWhileInFlightIsRejected() async {
        let fake = FakeTagEditorClientAdapting()
        let victim = tag("aaa")
        fake.fetchResults = [.success([victim, tag("bbb")]), .success([tag("bbb")])]
        let service = TagEditorService(client: fake)
        await service.load()

        // Hold the first delete in flight until we release it.
        let gate = TestGate()
        fake.beforeDelete = { await gate.wait() }

        let first = Task { await service.delete(tag: victim) }
        // Let `first` reach its in-flight suspension so isMutating is set.
        await Task.yield()
        XCTAssertTrue(service.isMutating)

        // A second delete while the first is in flight must be rejected without calling the client.
        let secondResult = await service.delete(tag: victim)
        XCTAssertFalse(secondResult)
        XCTAssertEqual(fake.deleteCallCount, 1, "the second mutation must not reach the client")

        gate.open()
        _ = await first.value
        XCTAssertFalse(service.isMutating)
    }
}

/// Minimal one-shot async gate for the serialisation test.
private actor TestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    nonisolated func open() {
        Task { await self.release() }
    }

    private func release() {
        isOpen = true
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
}
