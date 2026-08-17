//
//  ReminderDecodingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

private extension String {
    var utf8Data: Data { Data(utf8) }
}

final class ReminderDecodingTests: XCTestCase {

    // Verbatim payload captured live against the AWS endpoint 2026-07-22 (see the AWS Reminders
    // View feature block in the CC handoff doc). The envelope's own `count` says 4, but only this
    // one item was captured in the block — decoding must still succeed on it as-is.
    private let capturedPayload = """
    {"count": 4, "tasks": [
      {"notification": true, "datetime": "2026-05-24T11:00:00",
       "task_id": "dc554953-7dcc-4cd4-8dce-7583f014bf4b",
       "notes": "Testing low priority routing",
       "created": "2026-05-25T07:46:21.502958",
       "priority": "low", "source": "poke", "type": "reminder",
       "title": "LOW PRIORITY TEST"}
    ]}
    """.utf8Data

    func testDecodesCapturedPayload() throws {
        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: capturedPayload)

        XCTAssertEqual(envelope.count, 4)
        XCTAssertEqual(envelope.tasks.count, 1)
        let reminder = try XCTUnwrap(envelope.tasks.first)
        XCTAssertEqual(reminder.id, "dc554953-7dcc-4cd4-8dce-7583f014bf4b")
        XCTAssertEqual(reminder.title, "LOW PRIORITY TEST")
        XCTAssertEqual(reminder.notes, "Testing low priority routing")
        XCTAssertEqual(reminder.priority, .low)
        XCTAssertEqual(reminder.source, "poke")
        XCTAssertEqual(reminder.type, .reminder)
        XCTAssertEqual(reminder.notification, true)
        XCTAssertNotNil(reminder.createdAt)
        XCTAssertNotNil(reminder.datetime)
    }

    func testEmptyTasksArray_decodesToEmptyList() throws {
        let json = "{\"count\": 0, \"tasks\": []}".utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)

        XCTAssertEqual(envelope.count, 0)
        XCTAssertTrue(envelope.tasks.isEmpty)
    }

    func testItemWithOnlyGuaranteedFields_decodesSuccessfully() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "timer"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)
        let reminder = try XCTUnwrap(envelope.tasks.first)

        XCTAssertEqual(reminder.id, "abc-123")
        XCTAssertEqual(reminder.type, .timer)
        XCTAssertNil(reminder.title)
        XCTAssertNil(reminder.datetime)
        XCTAssertNotNil(reminder.createdAt)
    }

    func testItemWithUnknownExtraKeys_decodesIgnoringExtras() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "alarm",
           "time": "09:00", "duration_minutes": 5, "datetime_start": "2026-05-24T11:00:00",
           "some_future_field": {"nested": true}}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)

        XCTAssertEqual(envelope.tasks.count, 1)
        XCTAssertEqual(envelope.tasks.first?.type, .alarm)
    }

    func testItemWithMalformedDatetime_stillDecodesWithDateUnavailable() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "reminder",
           "datetime": "not-a-real-date", "title": "Bad date"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)
        let reminder = try XCTUnwrap(envelope.tasks.first)

        XCTAssertEqual(reminder.title, "Bad date")
        XCTAssertNil(reminder.datetime)
    }

    func testUnknownType_decodesToUnknownCase() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "totally-new-kind"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)

        XCTAssertEqual(envelope.tasks.first?.type, .unknown)
    }

    func testUnknownPriority_decodesToUnknownCase() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "reminder",
           "priority": "urgent"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)

        XCTAssertEqual(envelope.tasks.first?.priority, .unknown)
    }

    func testCreatedDate_parsesAsUTCWithoutShift() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "reminder"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)
        let createdAt = try XCTUnwrap(envelope.tasks.first?.createdAt)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: createdAt)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 25)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 46)
        XCTAssertEqual(components.second, 21)
    }

    func testDatetime_isNaiveWallClockNotShiftedByTimezone() throws {
        let json = """
        {"count": 1, "tasks": [
          {"task_id": "abc-123", "created": "2026-05-25T07:46:21.502958", "type": "reminder",
           "datetime": "2026-05-24T11:00:00"}
        ]}
        """.utf8Data

        let envelope = try JSONDecoder().decode(RemindersResponseEnvelope.self, from: json)
        let datetime = try XCTUnwrap(envelope.tasks.first?.datetime)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: datetime)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day, 24)
        XCTAssertEqual(components.hour, 11, "datetime must render the exact wall-clock hour with no timezone shift")
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(ReminderDateParsing.displayString(for: datetime).contains("11:00"))
    }
}
