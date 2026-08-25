//
//  FirebaseLifeAreaEditorClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// First adapter under test since the Firebase cutover. The `Firebase*ClientAdapter` structs are
/// thin, which is exactly why they went untested — and thin is not the same as trivial: this one
/// reproduces the old backend's `409` name-conflict semantics client-side, assigns sort order, and
/// hand-builds the field dictionary it writes.
///
/// The field-key assertions are the point. A wrong Firestore key raises nothing: the write succeeds
/// against a field nothing reads, and the rename appears to have silently failed. Nothing else in
/// the suite could catch that.
final class FirebaseLifeAreaEditorClientAdapterTests: XCTestCase {
    private var store: FakeLifeAreaEditorBackingStore!
    private var adapter: FirebaseLifeAreaEditorClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeLifeAreaEditorBackingStore()
        adapter = FirebaseLifeAreaEditorClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Fetch

    func testFetchLifeAreas_requestsArchivedAreasToo() async throws {
        _ = try await adapter.fetchLifeAreas()

        XCTAssertEqual(store.includeArchivedArguments, [true], "the editor lists archived areas to unarchive them")
    }

    func testFetchLifeAreas_mapsEveryFieldOntoEditableLifeArea() async throws {
        let id = UUID()
        store.areas = [LifeArea(id: id, name: "Health", colour: "🏃", sortOrder: 3, archived: true)]

        let areas = try await adapter.fetchLifeAreas()

        XCTAssertEqual(areas, [EditableLifeArea(id: id, name: "Health", colour: "🏃", sortOrder: 3, archived: true)])
    }

    func testFetchLifeAreas_wrapsFailureAsServiceError() async {
        store.fetchError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchLifeAreas()) { error in
            XCTAssertEqual(
                error as? LifeAreaEditorServiceError,
                .failed(FirebaseManagerError.notSignedIn.errorDescription ?? "")
            )
        }
    }

    // MARK: - Update: the field dictionary

    // MARK: - Palette override (E's 2026-08-25 note)

    func testUpdate_setPaletteWritesTheWireKey() async throws {
        let id = UUID()

        _ = try await adapter.update(id: id, name: nil, colour: nil, palette: .set("growth"))

        XCTAssertEqual(store.updates.count, 1)
        XCTAssertEqual(store.updates.first?.fields["palette"] as? String, "growth")
    }

    /// Back to Automatic ERASES the field — absence, never "", is what the resolver reads as
    /// automatic, so an old build's resolver never sees a value it must special-case.
    func testUpdate_automaticWritesTheEraseSentinel() async throws {
        _ = try await adapter.update(id: UUID(), name: nil, colour: nil, palette: .automatic)

        let value = store.updates.first?.fields["palette"]
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(value), "expected FieldValue.delete()")
    }

    func testUpdate_unchangedPaletteStaysOutOfTheFieldSet() async throws {
        _ = try await adapter.update(id: UUID(), name: "Renamed", colour: nil, palette: .unchanged)

        XCTAssertNil(store.updates.first?.fields["palette"])
    }

    func testFetch_carriesTheStoredPaletteKeyThrough() async throws {
        store.areas = [
            LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0, palette: "hobby")
        ]

        let fetched = try await adapter.fetchLifeAreas()

        XCTAssertEqual(fetched.first?.paletteKey, "hobby")
    }

    func testUpdate_withNameOnly_writesOnlyTheNameKey() async throws {
        let id = UUID()
        store.areas = [LifeArea(id: id, name: "Health", colour: "🏃", sortOrder: 0)]

        let outcome = try await adapter.update(id: id, name: "Wellbeing", colour: nil, palette: .unchanged)

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(store.updates.count, 1)
        XCTAssertEqual(store.updates.first?.id, id)
        XCTAssertEqual(store.updates.first?.fields.keys.sorted(), ["name"])
        XCTAssertEqual(store.updates.first?.fields["name"] as? String, "Wellbeing")
    }

    func testUpdate_withColourOnly_writesOnlyTheColourKey() async throws {
        let id = UUID()

        _ = try await adapter.update(id: id, name: nil, colour: "🧘", palette: .unchanged)

        XCTAssertEqual(store.updates.first?.fields.keys.sorted(), ["colour"])
        XCTAssertEqual(store.updates.first?.fields["colour"] as? String, "🧘")
    }

    func testUpdate_withBoth_writesBothKeys() async throws {
        let id = UUID()

        _ = try await adapter.update(id: id, name: "Wellbeing", colour: "🧘", palette: .unchanged)

        XCTAssertEqual(store.updates.first?.fields.keys.sorted(), ["colour", "name"])
    }

    /// The editor sends only what changed, so "nothing changed" reaches the adapter as a pair of
    /// `nil`s. It must stay a no-op write rather than clearing anything.
    func testUpdate_withNoChanges_writesAnEmptyFieldSet() async throws {
        let outcome = try await adapter.update(id: UUID(), name: nil, colour: nil, palette: .unchanged)

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(store.updates.first?.fields.isEmpty, true)
    }

    // MARK: - Update: name conflicts

    func testUpdate_renameOntoAnotherAreasName_conflictsAndWritesNothing() async throws {
        let target = UUID()
        let clash = UUID()
        store.areas = [
            LifeArea(id: target, name: "Health", colour: "🏃", sortOrder: 0),
            LifeArea(id: clash, name: "Admin", colour: "🗂", sortOrder: 1, archived: true)
        ]

        let outcome = try await adapter.update(id: target, name: "Admin", colour: nil, palette: .unchanged)

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: clash, name: "Admin", archived: true)))
        XCTAssertTrue(store.updates.isEmpty, "a conflict must not write")
    }

    /// Case-insensitive, matching the old backend's collation.
    func testUpdate_renameDifferingOnlyByCase_conflicts() async throws {
        let target = UUID()
        let clash = UUID()
        store.areas = [
            LifeArea(id: target, name: "Health", colour: "🏃", sortOrder: 0),
            LifeArea(id: clash, name: "Admin", colour: "🗂", sortOrder: 1)
        ]

        let outcome = try await adapter.update(id: target, name: "aDmIn", colour: nil, palette: .unchanged)

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: clash, name: "Admin", archived: false)))
    }

    /// An area must not conflict with itself, or recolouring while leaving the name alone would be
    /// impossible.
    func testUpdate_renameToItsOwnName_isNotAConflict() async throws {
        let id = UUID()
        store.areas = [LifeArea(id: id, name: "Health", colour: "🏃", sortOrder: 0)]

        let outcome = try await adapter.update(id: id, name: "Health", colour: "🧘", palette: .unchanged)

        XCTAssertEqual(outcome, .updated)
        XCTAssertEqual(store.updates.count, 1)
    }

    func testUpdate_wrapsWriteFailureAsServiceError() async {
        store.updateError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(
            try await adapter.update(id: UUID(), name: "Wellbeing", colour: nil, palette: .unchanged)
        ) { error in
            XCTAssertEqual(
                error as? LifeAreaEditorServiceError,
                .failed(FirebaseManagerError.notSignedIn.errorDescription ?? "")
            )
        }
    }

    // MARK: - Archive

    func testSetArchived_writesOnlyTheArchivedKey() async throws {
        let id = UUID()

        try await adapter.setArchived(id: id, archived: true)

        XCTAssertEqual(store.updates.first?.id, id)
        XCTAssertEqual(store.updates.first?.fields.keys.sorted(), ["archived"])
        XCTAssertEqual(store.updates.first?.fields["archived"] as? Bool, true)
    }

    func testSetArchived_unarchivingWritesFalseRatherThanClearingTheField() async throws {
        try await adapter.setArchived(id: UUID(), archived: false)

        XCTAssertEqual(store.updates.first?.fields["archived"] as? Bool, false)
    }

    func testSetArchived_wrapsFailureAsServiceError() async {
        store.updateError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.setArchived(id: UUID(), archived: true)) { error in
            XCTAssertEqual(
                error as? LifeAreaEditorServiceError,
                .failed(FirebaseManagerError.notSignedIn.errorDescription ?? "")
            )
        }
    }

    // MARK: - Create

    func testCreate_onAnEmptyCollection_startsSortOrderAtZero() async throws {
        let outcome = try await adapter.create(name: "Health", colour: "🏃")

        guard case .created(let area) = outcome else {
            return XCTFail("expected .created, got \(outcome)")
        }
        XCTAssertEqual(area.name, "Health")
        XCTAssertEqual(area.colour, "🏃")
        XCTAssertEqual(area.sortOrder, 0)
        XCTAssertFalse(area.archived)
        XCTAssertEqual(store.savedAreas.count, 1)
        XCTAssertEqual(store.savedAreas.first?.id, area.id, "the returned area must be the one persisted")
        XCTAssertEqual(store.savedAreas.first?.sortOrder, 0)
    }

    /// Appends to the end of the list — and `max`, not `count`, so a gap left by a deleted area
    /// never puts a new one on top of an existing sort order.
    func testCreate_appendsAfterTheHighestSortOrder() async throws {
        store.areas = [
            LifeArea(id: UUID(), name: "Health", colour: "🏃", sortOrder: 0),
            LifeArea(id: UUID(), name: "Admin", colour: "🗂", sortOrder: 7)
        ]

        _ = try await adapter.create(name: "Money", colour: "💰")

        XCTAssertEqual(store.savedAreas.first?.sortOrder, 8)
    }

    /// Archived areas count towards the conflict check, and the flag is carried back so the editor
    /// can offer "Unarchive it instead?" rather than a dead-end Cancel.
    func testCreate_collidingWithAnArchivedArea_conflictsAndReportsItArchived() async throws {
        let clash = UUID()
        store.areas = [LifeArea(id: clash, name: "Admin", colour: "🗂", sortOrder: 0, archived: true)]

        let outcome = try await adapter.create(name: "admin", colour: "📁")

        XCTAssertEqual(outcome, .nameConflict(LifeAreaNameConflict(id: clash, name: "Admin", archived: true)))
        XCTAssertTrue(store.savedAreas.isEmpty, "a conflict must not write")
    }

    func testCreate_wrapsWriteFailureAsServiceError() async {
        store.saveError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.create(name: "Health", colour: "🏃")) { error in
            XCTAssertEqual(
                error as? LifeAreaEditorServiceError,
                .failed(FirebaseManagerError.notSignedIn.errorDescription ?? "")
            )
        }
    }
}

/// `XCTAssertThrowsError` predates `async`, so it cannot be handed an `await`ing expression.
func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ handler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("expected an error to be thrown", file: file, line: line)
    } catch {
        handler(error)
    }
}
