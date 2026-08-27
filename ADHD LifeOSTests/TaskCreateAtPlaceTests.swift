//
//  TaskCreateAtPlaceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The at-place field on the CREATE sheet (E's 2026-08-28 follow-up to block 4a, which shipped the
/// picker on task detail only). Same field, same meaning — `at_place_id` is INTENT, where the task
/// can be done, and it is what arrival triggers read — so a task can now carry its place from the
/// moment it exists rather than needing a second trip through detail.
///
/// The wire assertions matter more here than usual: task creation writes through `Codable` rather
/// than a hand-written field dictionary, so the spelling is `TaskDetail`'s `CodingKeys` and nothing
/// would raise if the adapter simply dropped the field on the floor.
@MainActor
final class TaskCreateAtPlaceTests: XCTestCase {

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

    private static func place(name: String = "The Office", emoji: String? = "💼") -> Place {
        Place(
            id: UUID(), name: name,
            coordinate: PlaceCoordinate(latitude: 51.5203, longitude: -0.0986),
            radiusMetres: 200, emoji: emoji
        )
    }

    // MARK: - Validation carries the field

    func testNormalize_carriesTheChosenPlace() throws {
        let placeId = UUID()

        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Return the parcel", notes: nil, lifeAreaId: nil, dueDate: nil, atPlaceId: placeId
        )

        let input = try XCTUnwrap(try? result.get())
        XCTAssertEqual(input.atPlaceId, placeId)
    }

    func testNormalize_noPlaceChosen_isNil() throws {
        let result = TaskCreateValidation.normalizeCreateTaskInput(
            title: "Return the parcel", notes: nil, lifeAreaId: nil, dueDate: nil
        )

        let input = try XCTUnwrap(try? result.get())
        XCTAssertNil(input.atPlaceId, "no place chosen must write no place, not a placeholder")
    }

    // MARK: - The adapter writes it, and the projection agrees

    func testAdapter_writesTheAtPlaceAndReturnsItOnTheProjection() async throws {
        let store = FakeTaskCreateBackingStore()
        let adapter = FirebaseTaskCreateClientAdapter(store: store)
        let placeId = UUID()

        let item = try await adapter.createTask(
            NormalizedCreateTaskInput(
                title: "Return the parcel", notes: nil, lifeAreaId: nil, dueDate: nil,
                priority: .p4, atPlaceId: placeId
            )
        )

        XCTAssertEqual(store.createdTasks.first?.atPlaceId, placeId)
        XCTAssertEqual(
            item.atPlaceId, placeId,
            "the list renders the projection before any refetch, so it must carry the place too"
        )
    }

    func testAdapter_atPlaceIsAbsentWhenNoneWasChosen() async throws {
        let store = FakeTaskCreateBackingStore()
        let adapter = FirebaseTaskCreateClientAdapter(store: store)

        let item = try await adapter.createTask(
            NormalizedCreateTaskInput(
                title: "Return the parcel", notes: nil, lifeAreaId: nil, dueDate: nil, priority: .p4
            )
        )

        XCTAssertNil(store.createdTasks.first?.atPlaceId)
        XCTAssertNil(item.atPlaceId)
    }

    /// Tasks are snake_cased on the wire; `atPlaceId` is captures' convention and would write a
    /// field nothing reads.
    func testAdapter_writtenTaskEncodesTheSnakeCaseSpelling() async throws {
        let store = FakeTaskCreateBackingStore()
        let adapter = FirebaseTaskCreateClientAdapter(store: store)
        let placeId = UUID()

        _ = try await adapter.createTask(
            NormalizedCreateTaskInput(
                title: "Return the parcel", notes: nil, lifeAreaId: nil, dueDate: nil,
                priority: .p4, atPlaceId: placeId
            )
        )

        let written = try XCTUnwrap(store.createdTasks.first)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(written)) as? [String: Any]
        )
        XCTAssertEqual(json["at_place_id"] as? String, placeId.uuidString)
        XCTAssertNil(json["atPlaceId"], "the camelCase spelling belongs to captures, not tasks")
        XCTAssertNil(json["place_id"], "creating a task never stamps where it was CLOSED")
    }

    // MARK: - The composer's own wiring

    func testService_createTask_passesTheChosenPlaceThrough() async {
        let client = FakeTaskCreateClientAdapting()
        let places = FakePlacesClient()
        let chosen = Self.place()
        places.places = [chosen]
        let sut = TaskCreateService(client: client, placesClient: places)
        sut.title = "Return the parcel"
        sut.atPlaceId = chosen.id

        let created = await sut.createTask()

        XCTAssertTrue(created)
        XCTAssertEqual(client.lastCreateTaskInput?.atPlaceId, chosen.id)
    }

    func testService_loadPlaces_fillsThePicker() async {
        let places = FakePlacesClient()
        places.places = [Self.place(name: "Tesco", emoji: "🛒"), Self.place()]
        let sut = TaskCreateService(client: FakeTaskCreateClientAdapting(), placesClient: places)

        await sut.loadPlaces()

        XCTAssertEqual(sut.places.count, 2)
    }

    /// The same non-blocking posture as task detail's places stream: garnish, never load-bearing.
    /// A places outage must not stop someone adding a task.
    func testService_loadPlaces_failureLeavesTheComposerUsable() async {
        let places = FakePlacesClient()
        places.fetchError = TasksServiceError.fetchFailed("Network error")
        let client = FakeTaskCreateClientAdapting()
        let sut = TaskCreateService(client: client, placesClient: places)
        sut.title = "Return the parcel"

        await sut.loadPlaces()
        let created = await sut.createTask()

        XCTAssertTrue(sut.places.isEmpty)
        XCTAssertNil(sut.errorMessage, "a places failure is not the composer's error to report")
        XCTAssertTrue(created)
    }
}
