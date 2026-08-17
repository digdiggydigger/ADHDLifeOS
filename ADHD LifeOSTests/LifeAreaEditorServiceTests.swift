//
//  LifeAreaEditorServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class LifeAreaEditorServiceTests: XCTestCase {

    private func area(
        _ name: String, colour: String = "🏠", sort: Int = 1, archived: Bool = false, id: UUID = UUID()
    ) -> EditableLifeArea {
        EditableLifeArea(id: id, name: name, colour: colour, sortOrder: sort, archived: archived)
    }

    // MARK: load / partition

    func test_load_success_setsAreasAndLoaded() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        fake.fetchResults = [.success([area("Work", sort: 1), area("Old", sort: 2, archived: true)])]
        let service = LifeAreaEditorService(client: fake)

        await service.load()

        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.activeAreas.map(\.name), ["Work"])
        XCTAssertEqual(service.archivedAreas.map(\.name), ["Old"])
    }

    func test_load_failure_setsFailedStateWithMessage() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        fake.fetchResults = [.failure(LifeAreaEditorServiceError.failed("boom"))]
        let service = LifeAreaEditorService(client: fake)

        await service.load()

        XCTAssertEqual(service.state, .failed("boom"))
    }

    // MARK: saveEdits

    func test_saveEdits_renameOnly_sendsNameNotColour_reloads_returnsTrue() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work", colour: "💼")
        fake.fetchResults = [.success([target]), .success([area("Career", colour: "💼")])]
        fake.updateResult = .success(.updated)
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let pop = await service.saveEdits(to: target, name: "Career", colour: "💼")

        XCTAssertTrue(pop)
        XCTAssertEqual(fake.updateCallCount, 1)
        XCTAssertEqual(fake.lastUpdateName, .some("Career"))
        XCTAssertEqual(fake.lastUpdateColour, .some(nil), "colour unchanged -> nil, not re-sent")
        XCTAssertEqual(fake.fetchCallCount, 2, "a successful save reloads")
    }

    func test_saveEdits_colourOnly_sendsColourNotName() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work", colour: "💼")
        fake.fetchResults = [.success([target]), .success([area("Work", colour: "🧰")])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        _ = await service.saveEdits(to: target, name: "Work", colour: "🧰")

        XCTAssertEqual(fake.lastUpdateName, .some(nil), "name unchanged -> nil")
        XCTAssertEqual(fake.lastUpdateColour, .some("🧰"))
    }

    func test_saveEdits_nothingChanged_popsWithoutCallingClient() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work", colour: "💼")
        fake.fetchResults = [.success([target])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let pop = await service.saveEdits(to: target, name: "Work", colour: "💼")

        XCTAssertTrue(pop)
        XCTAssertEqual(fake.updateCallCount, 0, "a no-op must not fire a PATCH")
    }

    func test_saveEdits_emptyName_returnsFalse_writesNothing() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work")
        fake.fetchResults = [.success([target])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let pop = await service.saveEdits(to: target, name: "   ", colour: "🏠")

        XCTAssertFalse(pop)
        XCTAssertEqual(fake.updateCallCount, 0)
    }

    func test_saveEdits_conflict_setsPendingRenameConflict_returnsFalse() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work")
        let conflict = LifeAreaNameConflict(id: UUID(), name: "Health", archived: true)
        fake.fetchResults = [.success([target])]
        fake.updateResult = .success(.nameConflict(conflict))
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let pop = await service.saveEdits(to: target, name: "Health", colour: "🏠")

        XCTAssertFalse(pop)
        XCTAssertEqual(service.pendingRenameConflict, conflict)
        XCTAssertEqual(fake.fetchCallCount, 1, "a conflict writes nothing and does not reload")
    }

    // MARK: create

    func test_create_success_reloads_returnsTrue() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        fake.fetchResults = [.success([]), .success([area("Garden")])]
        fake.createResult = .success(.created(area("Garden")))
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let dismiss = await service.create(name: "Garden", colour: "🌱")

        XCTAssertTrue(dismiss)
        XCTAssertEqual(fake.lastCreateName, "Garden")
        XCTAssertEqual(fake.lastCreateColour, "🌱")
        XCTAssertEqual(fake.fetchCallCount, 2)
    }

    func test_create_conflict_setsPendingCreateConflict_returnsFalse() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let conflict = LifeAreaNameConflict(id: UUID(), name: "Work", archived: false)
        fake.createResult = .success(.nameConflict(conflict))
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let dismiss = await service.create(name: "Work", colour: "💼")

        XCTAssertFalse(dismiss)
        XCTAssertEqual(service.pendingCreateConflict, conflict)
    }

    func test_create_emptyName_returnsFalse_noCall() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let dismiss = await service.create(name: "   ", colour: "🏠")

        XCTAssertFalse(dismiss)
        XCTAssertEqual(fake.createCallCount, 0)
    }

    // MARK: setArchived / unarchiveConflicting

    func test_setArchived_archives_reloads_setsInfo_returnsTrue() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work")
        fake.fetchResults = [.success([target]), .success([area("Work", archived: true)])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let pop = await service.setArchived(target, archived: true)

        XCTAssertTrue(pop)
        XCTAssertEqual(fake.lastSetArchivedId, target.id)
        XCTAssertEqual(fake.lastSetArchivedValue, true)
        XCTAssertNotNil(service.infoMessage)
        XCTAssertEqual(fake.fetchCallCount, 2)
    }

    func test_unarchiveConflicting_unarchivesConflict_clearsConflict_returnsTrue() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let conflict = LifeAreaNameConflict(id: UUID(), name: "Health", archived: true)
        fake.fetchResults = [.success([]), .success([area("Health", id: conflict.id)])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()
        service.pendingCreateConflict = conflict

        let dismiss = await service.unarchiveConflicting(conflict)

        XCTAssertTrue(dismiss)
        XCTAssertEqual(fake.lastSetArchivedId, conflict.id)
        XCTAssertEqual(fake.lastSetArchivedValue, false, "unarchive = archived:false")
        XCTAssertNil(service.pendingCreateConflict, "conflict cleared after unarchive")
    }

    // MARK: serialisation (the 8e19a08 race class)

    func test_secondMutationWhileInFlightIsRejected() async {
        let fake = FakeLifeAreaEditorClientAdapting()
        let target = area("Work")
        fake.fetchResults = [.success([target]), .success([area("Work", archived: true)])]
        let service = LifeAreaEditorService(client: fake)
        await service.load()

        let gate = LifeAreaTestGate()
        fake.beforeSetArchived = { await gate.wait() }

        let first = Task { await service.setArchived(target, archived: true) }
        await Task.yield()
        XCTAssertTrue(service.isMutating)

        let secondResult = await service.setArchived(target, archived: false)
        XCTAssertFalse(secondResult)
        XCTAssertEqual(fake.setArchivedCallCount, 1, "the second mutation must not reach the client")

        gate.open()
        _ = await first.value
        XCTAssertFalse(service.isMutating)
    }
}

/// Minimal one-shot async gate for the serialisation test.
private actor LifeAreaTestGate {
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
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}
