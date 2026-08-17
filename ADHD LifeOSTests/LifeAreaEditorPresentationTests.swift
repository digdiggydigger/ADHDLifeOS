//
//  LifeAreaEditorPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LifeAreaEditorPresentationTests: XCTestCase {

    private func area(_ name: String, sort: Int, archived: Bool) -> EditableLifeArea {
        EditableLifeArea(id: UUID(), name: name, colour: "🏠", sortOrder: sort, archived: archived)
    }

    // MARK: partition

    func test_partition_splitsActiveFromArchived_bothSortedBySortOrder() {
        let areas = [
            area("C-active", sort: 3, archived: false),
            area("Z-archived", sort: 5, archived: true),
            area("A-active", sort: 1, archived: false),
            area("M-archived", sort: 2, archived: true)
        ]

        let (active, archived) = LifeAreaEditorPresentation.partition(areas)

        XCTAssertEqual(active.map(\.name), ["A-active", "C-active"], "active sorted by sortOrder")
        XCTAssertEqual(archived.map(\.name), ["M-archived", "Z-archived"], "archived sorted by sortOrder")
    }

    func test_partition_noArchived_archivedIsEmpty() {
        let areas = [area("A", sort: 1, archived: false), area("B", sort: 2, archived: false)]
        let (active, archived) = LifeAreaEditorPresentation.partition(areas)
        XCTAssertEqual(active.count, 2)
        XCTAssertTrue(archived.isEmpty)
    }

    func test_partition_allArchived_activeIsEmpty() {
        let areas = [area("A", sort: 1, archived: true)]
        let (active, archived) = LifeAreaEditorPresentation.partition(areas)
        XCTAssertTrue(active.isEmpty)
        XCTAssertEqual(archived.count, 1)
    }

    // MARK: row identifier

    func test_rowIdentifier_isLowercased() {
        let id = UUID()
        XCTAssertEqual(
            LifeAreaEditorPresentation.rowIdentifier(for: id),
            "lifeAreaRow_\(id.uuidString.lowercased())"
        )
    }

    // MARK: create-conflict messages (the two branches differ)

    func test_createConflict_archived_message_mentionsUnarchive() {
        let message = LifeAreaEditorPresentation.createConflictArchivedMessage(name: "Health")
        XCTAssertTrue(message.contains("Health"))
        XCTAssertTrue(message.localizedCaseInsensitiveContains("unarchive"))
    }

    func test_createConflict_live_message_doesNotMentionUnarchive() {
        let message = LifeAreaEditorPresentation.createConflictLiveMessage(name: "Health")
        XCTAssertTrue(message.contains("Health"))
        XCTAssertFalse(message.localizedCaseInsensitiveContains("unarchive"))
    }

    // MARK: rename-conflict message (Cancel-only, never offers unarchive)

    func test_renameConflict_archivedHolder_saysArchived_neverOffersUnarchive() {
        let message = LifeAreaEditorPresentation.renameConflictMessage(name: "Health", archived: true)
        XCTAssertTrue(message.localizedCaseInsensitiveContains("archived"))
        XCTAssertFalse(
            message.localizedCaseInsensitiveContains("unarchive"),
            "rename can't be resolved by unarchiving, so the copy must never suggest it"
        )
    }

    func test_renameConflict_liveHolder_plainMessage() {
        let message = LifeAreaEditorPresentation.renameConflictMessage(name: "Health", archived: false)
        XCTAssertTrue(message.contains("Health"))
        XCTAssertFalse(message.localizedCaseInsensitiveContains("unarchive"))
    }
}
