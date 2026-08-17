//
//  InsertPayloadUserIdTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Regression coverage for the cross-cutting RLS fix: every INSERT payload must carry an
/// explicit `user_id`, since `WITH CHECK (auth.uid() = user_id)` validates the column but never
/// populates it — no column default, no `BEFORE INSERT` trigger (`ARCHITECTURE.md` §4). Each
/// test round-trips the payload through the same `JSONEncoder`/`JSONDecoder` machinery
/// `PostgrestClient` uses, and asserts the decoded `user_id` matches the session's user id.
private struct DecodedUserId: Decodable {
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

final class InsertPayloadUserIdTests: XCTestCase {
    private func assertUserId(
        _ userId: UUID,
        encodedIn payload: some Encodable,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(DecodedUserId.self, from: data)
        XCTAssertEqual(decoded.userId, userId, file: file, line: line)
    }

    func testLogInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = LogInsertPayload(body: "Went for a walk", type: .log, lifeAreaId: nil, userId: userId)

        try assertUserId(userId, encodedIn: payload)
    }

    func testCaptureInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = CaptureInsertPayload(content: "Buy milk", kind: .note, processed: false, userId: userId)

        try assertUserId(userId, encodedIn: payload)
    }

    func testCaptureTaskInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = CaptureTaskInsertPayload(
            title: "Buy milk",
            lifeAreaId: nil,
            dueDate: nil,
            priority: .p4,
            status: .open,
            source: "capture",
            userId: userId
        )

        try assertUserId(userId, encodedIn: payload)
    }

    func testNudgeInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = NudgeInsertPayload(label: "Drink water", schedule: "0 9 * * *", active: true, userId: userId)

        try assertUserId(userId, encodedIn: payload)
    }

    func testTaskInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = TaskInsertPayload(
            title: "Buy milk",
            notes: nil,
            lifeAreaId: nil,
            dueDate: nil,
            priority: .p4,
            status: .open,
            source: "manual",
            userId: userId
        )

        try assertUserId(userId, encodedIn: payload)
    }

    func testTagInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = TagInsertPayload(name: "urgent", userId: userId)

        try assertUserId(userId, encodedIn: payload)
    }

    /// Sixth insert call site, missed by the FIX block's original five-site list: Task Detail's
    /// inline "add tag" flow inserts into `public.tags` independently of Task Create's own
    /// `TagInsertPayload`, via `SupabaseTaskDetailClientAdapter.createTag`.
    func testTaskDetailTagInsertPayload_encodesUserId() throws {
        let userId = UUID()
        let payload = TaskDetailTagInsertPayload(name: "urgent", userId: userId)

        try assertUserId(userId, encodedIn: payload)
    }
}
