//
//  TaskLocationStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// That closing a task actually carries its location stamp into the write (block 3 remainder).
///
/// Unlike captures, the stamp is taken in the two production ADAPTERS rather than in each caller,
/// deliberately: FOUR surfaces close a task (list swipe, task detail, Home Momentum, life-area
/// detail) and two of them are views calling `TaskDetailClientAdapting` directly with no service
/// in between — one seam stamps them all. These tests prove the adapters take the stamp, gate it
/// on the status, and never let it block the write.
@MainActor
final class TaskLocationStampTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private static func detail(status: TaskStatus) -> TaskDetail {
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Task", notes: nil,
            status: status, priority: .p2, dueDate: nil, createdAt: Date()
        )
    }

    // MARK: - The list adapter (tap-circle / swipe-right close)

    func testTasksAdapter_close_carriesTheStampIntoTheWrite() async throws {
        let store = FakeTasksBackingStore()
        let placeId = UUID()
        let adapter = FirebaseTasksClientAdapter(
            store: store,
            locationStamp: { LocationStamp(coordinate: self.coordinate, placeId: placeId) }
        )

        try await adapter.setStatus(taskId: UUID(), status: .done)

        XCTAssertEqual(store.statusWrites.first?.locationStamp?.placeId, placeId)
        XCTAssertEqual(store.statusWrites.first?.locationStamp?.coordinate, coordinate)
    }

    /// Tagging off, permission absent, no fix — all arrive as `nil`, and the close must land
    /// exactly as it would have. A location lookup must never be why a task fails to close.
    func testTasksAdapter_close_withNoStampStillWrites() async throws {
        let store = FakeTasksBackingStore()
        let adapter = FirebaseTasksClientAdapter(store: store, locationStamp: { nil })

        try await adapter.setStatus(taskId: UUID(), status: .done)

        XCTAssertEqual(store.statusWrites.count, 1)
        XCTAssertEqual(store.statusWrites.first?.status, .done)
        XCTAssertNil(store.statusWrites.first?.locationStamp)
    }

    // MARK: - The detail adapter (detail close, Home Momentum, life-area detail)

    func testDetailAdapter_close_carriesTheStampIntoTheWrite() async throws {
        let store = FakeTaskDetailBackingStore()
        store.storedTask = Self.detail(status: .done)
        let placeId = UUID()
        let adapter = FirebaseTaskDetailClientAdapter(
            store: store,
            locationStamp: { LocationStamp(coordinate: self.coordinate, placeId: placeId) }
        )

        _ = try await adapter.updateStatus(id: UUID(), status: .done)

        XCTAssertEqual(store.statusWrites.first?.locationStamp?.placeId, placeId)
        XCTAssertEqual(store.statusWrites.first?.locationStamp?.coordinate, coordinate)
    }

    /// Home Momentum's undo reopens a task: no stamp is written AND no fix is requested —
    /// reopening happens wherever you are NOW, which is not where the task was closed.
    func testDetailAdapter_reopen_neitherStampsNorRequestsAFix() async throws {
        let store = FakeTaskDetailBackingStore()
        store.storedTask = Self.detail(status: .open)
        var stampRequests = 0
        let adapter = FirebaseTaskDetailClientAdapter(store: store, locationStamp: {
            stampRequests += 1
            return LocationStamp(coordinate: self.coordinate, placeId: nil)
        })

        _ = try await adapter.updateStatus(id: UUID(), status: .open)

        XCTAssertEqual(store.statusWrites.first?.status, .open)
        XCTAssertNil(store.statusWrites.first?.locationStamp)
        XCTAssertEqual(stampRequests, 0, "reopening must not request a fix")
    }

    // MARK: - The models carry it back off Firestore

    /// Tasks are fully snake_cased, so `place_id` — asserted both ways because a wrong key writes
    /// a field nothing reads, and raises nothing. `TaskDetail` is the task model that full-encodes
    /// (at create), so its spelling is the one that reaches the wire.
    func testTaskDetail_encodesTheLocationFieldsWithTheExpectedSpelling() throws {
        let placeId = UUID()
        let detail = TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Task", notes: nil,
            status: .done, priority: .p2, dueDate: nil, createdAt: Date(),
            placeId: placeId, latitude: 51.5152, longitude: -0.1418
        )

        let data = try JSONEncoder().encode(detail)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["place_id"] as? String, placeId.uuidString)
        XCTAssertEqual(json["latitude"] as? Double, 51.5152)
        XCTAssertEqual(json["longitude"] as? Double, -0.1418)
        XCTAssertNil(json["placeId"], "the camelCase spelling belongs to captures, not tasks")
    }

    /// The list model reads the trio back off the document under the same keys.
    func testTaskItem_decodesTheLocationFields() throws {
        let document = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000005","title":"Task","status":"done",\
        "priority":"p2","place_id":"6B1E4C1E-0000-0000-0000-000000000006",\
        "latitude":51.5152,"longitude":-0.1418}
        """.utf8)

        let item = try JSONDecoder().decode(TaskItem.self, from: document)

        XCTAssertEqual(item.placeId?.uuidString, "6B1E4C1E-0000-0000-0000-000000000006")
        XCTAssertEqual(item.latitude, 51.5152)
        XCTAssertEqual(item.longitude, -0.1418)
    }

    /// Every task closed before this shipped has none of these fields; both task models must
    /// decode them as absent rather than failing the document.
    func testTaskModels_decodeADocumentWithNoLocationFields() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000005","title":"Task","status":"done",\
        "priority":"p2","created_at":0}
        """.utf8)

        let item = try JSONDecoder().decode(TaskItem.self, from: legacy)
        let detail = try JSONDecoder().decode(TaskDetail.self, from: legacy)

        XCTAssertNil(item.placeId)
        XCTAssertNil(item.latitude)
        XCTAssertNil(item.longitude)
        XCTAssertNil(detail.placeId)
        XCTAssertNil(detail.latitude)
        XCTAssertNil(detail.longitude)
    }
}
