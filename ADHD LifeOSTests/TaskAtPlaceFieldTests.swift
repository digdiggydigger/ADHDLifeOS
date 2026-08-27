//
//  TaskAtPlaceFieldTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The at-place field (block 4a): a task can be marked doable AT a place — the forward link every
/// arrival trigger surfaces. Deliberately distinct from block 3's closed-here stamp: this is
/// intent, that is history, and editing one never touches the other.
@MainActor
final class TaskAtPlaceFieldTests: XCTestCase {

    private final class FakePlacesClient: PlacesClientAdapting {
        var places: [Place] = []
        var fetchError: Error?

        func fetchPlaces() async throws -> [Place] {
            if let fetchError { throw fetchError }
            return places
        }

        func savePlace(_ place: Place) async throws {}
        func deletePlace(id: UUID) async throws {}
    }

    private static func original(atPlaceId: UUID? = nil) -> TaskDetail {
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Return the parcel", notes: nil,
            status: .open, priority: .p2, dueDate: nil, createdAt: Date(),
            atPlaceId: atPlaceId
        )
    }

    private static func edited(from original: TaskDetail, atPlaceId: UUID?) -> TaskEditedFields {
        TaskEditedFields(
            title: original.title, notes: original.notes ?? "", lifeAreaId: original.lifeAreaId,
            priority: original.priority, dueDate: original.dueDate, atPlaceId: atPlaceId
        )
    }

    // MARK: - The staged diff

    func testNormalizeUpdate_settingAPlacePopulatesThePayload() throws {
        let original = Self.original()
        let placeId = UUID()

        let payload = try TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: Self.edited(from: original, atPlaceId: placeId)
        ).get()

        XCTAssertEqual(payload.atPlaceId, .some(.some(placeId)))
    }

    /// Staging the value the task already holds is not an edit — no manufactured write, and Save
    /// stays disabled on an untouched screen.
    func testNormalizeUpdate_unchangedPlaceWritesNothing() throws {
        let placeId = UUID()
        let original = Self.original(atPlaceId: placeId)

        let payload = try TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: Self.edited(from: original, atPlaceId: placeId)
        ).get()

        XCTAssertNil(payload.atPlaceId)
    }

    func testNormalizeUpdate_clearingBecomesAnExplicitNil() throws {
        let original = Self.original(atPlaceId: UUID())

        let payload = try TaskUpdateValidation.normalizeUpdateTaskInput(
            original: original, edited: Self.edited(from: original, atPlaceId: nil)
        ).get()

        XCTAssertEqual(payload.atPlaceId, .some(.none))
    }

    // MARK: - The wire (tasks are snake_cased)

    func testTaskUpdate_atPlaceIdIsSnakeCased() {
        let placeId = UUID()
        var payload = TaskUpdatePayload()
        payload.atPlaceId = .some(placeId)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields["at_place_id"] as? String, placeId.uuidString)
        XCTAssertNil(fields["atPlaceId"], "the camelCase spelling belongs to captures, not tasks")
    }

    func testTaskUpdate_clearingAtPlaceBecomesADelete() {
        var payload = TaskUpdatePayload()
        payload.atPlaceId = .some(nil)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields.keys.sorted(), ["at_place_id"])
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["at_place_id"]))
    }

    func testTaskUpdate_untouchedAtPlaceIsNotWritten() {
        var payload = TaskUpdatePayload()
        payload.title = "Renamed"

        XCTAssertNil(FirestoreFieldPayloads.taskUpdate(payload)["at_place_id"])
    }

    // MARK: - The models

    func testTaskDetail_encodesAtPlaceIdWithTheExpectedSpelling() throws {
        let placeId = UUID()
        let detail = TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Task", notes: nil,
            status: .open, priority: .p2, dueDate: nil, createdAt: Date(),
            atPlaceId: placeId
        )

        let data = try JSONEncoder().encode(detail)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["at_place_id"] as? String, placeId.uuidString)
        XCTAssertNil(json["atPlaceId"])
    }

    /// `at_place_id` (intent — where this can be done) and `place_id` (history — where it was
    /// closed) are different fields and must never collapse into one another.
    func testTaskModels_decodeIntentAndHistoryAsSeparateFields() throws {
        let document = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000008","title":"Task","status":"done",\
        "priority":"p2","created_at":0,\
        "at_place_id":"6B1E4C1E-0000-0000-0000-000000000006",\
        "place_id":"7B1E4C1E-0000-0000-0000-000000000007"}
        """.utf8)

        let item = try JSONDecoder().decode(TaskItem.self, from: document)
        let detail = try JSONDecoder().decode(TaskDetail.self, from: document)

        XCTAssertEqual(item.atPlaceId?.uuidString, "6B1E4C1E-0000-0000-0000-000000000006")
        XCTAssertEqual(item.placeId?.uuidString, "7B1E4C1E-0000-0000-0000-000000000007")
        XCTAssertEqual(detail.atPlaceId?.uuidString, "6B1E4C1E-0000-0000-0000-000000000006")
        XCTAssertEqual(detail.placeId?.uuidString, "7B1E4C1E-0000-0000-0000-000000000007")
    }

    func testTaskModels_decodeADocumentWithNoAtPlaceField() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000005","title":"Task","status":"open",\
        "priority":"p2","created_at":0}
        """.utf8)

        XCTAssertNil(try JSONDecoder().decode(TaskItem.self, from: legacy).atPlaceId)
        XCTAssertNil(try JSONDecoder().decode(TaskDetail.self, from: legacy).atPlaceId)
    }

    // MARK: - The detail service feeds the picker

    func testDetailService_loadFetchesPlacesForThePicker() async {
        let client = FakeTaskDetailClientAdapting()
        let places = FakePlacesClient()
        places.places = [Place(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒"
        )]
        let sut = TaskDetailService(taskId: UUID(), client: client, placesClient: places)

        await sut.load()

        XCTAssertEqual(sut.places.map(\.name), ["Tesco"])
    }

    /// Places are garnish on this screen — the same non-blocking posture as the journal's side
    /// streams. A failed fetch must never take the task itself down.
    func testDetailService_placesFailureLeavesTheTaskLoaded() async {
        let client = FakeTaskDetailClientAdapting()
        let places = FakePlacesClient()
        places.fetchError = URLError(.notConnectedToInternet)
        let sut = TaskDetailService(taskId: UUID(), client: client, placesClient: places)

        await sut.load()

        if case .loaded = sut.state {} else {
            XCTFail("a places failure must not fail the task load")
        }
        XCTAssertTrue(sut.places.isEmpty)
    }
}
