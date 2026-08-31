//
//  ShortcutIntentRunnerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The work behind the "Capture a note" / "Log a journal line" App Intents
/// (F-PlaceActions-4-Shortcuts). The intents themselves are thin glue the system instantiates;
/// everything decidable lives here, fake-driven: validation refuses before any work is spent,
/// the stamp rides the input, and both success and failure answer Shortcuts in words that are
/// pinned — an automation is exactly where a silent failure would go unnoticed for weeks.
final class ShortcutIntentRunnerTests: XCTestCase {

    private final class WriterLog {
        private(set) var journalInputs: [NormalizedCreateLogInput] = []
        private(set) var captureInputs: [NormalizedCreateCaptureInput] = []
        private(set) var stampRequests = 0
        var writesSucceed = true
        var stamp: LocationStamp?

        func journal(_ input: NormalizedCreateLogInput) -> Bool {
            journalInputs.append(input)
            return writesSucceed
        }

        func capture(_ input: NormalizedCreateCaptureInput) -> Bool {
            captureInputs.append(input)
            return writesSucceed
        }

        func requestStamp() -> LocationStamp? {
            stampRequests += 1
            return stamp
        }
    }

    private func makeRunner(_ log: WriterLog) -> ShortcutIntentRunner {
        ShortcutIntentRunner(
            journalWriter: { log.journal($0) },
            captureWriter: { log.capture($0) },
            locationStamp: { log.requestStamp() }
        )
    }

    private let homeStamp = LocationStamp(
        coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
        placeId: UUID()
    )

    // MARK: - Capture a note

    func testCaptureNote_writesTrimmedStampedNote_andConfirms() async {
        let log = WriterLog()
        log.stamp = homeStamp

        let outcome = await makeRunner(log).captureNote("  Buy milk  ")

        XCTAssertEqual(outcome, .saved(confirmation: "Captured \u{201C}Buy milk\u{201D} to your inbox."))
        XCTAssertEqual(log.captureInputs.count, 1)
        XCTAssertEqual(log.captureInputs.first?.content, "Buy milk")
        XCTAssertEqual(log.captureInputs.first?.kind, .note)
        XCTAssertEqual(log.captureInputs.first?.locationStamp, homeStamp)
    }

    /// The refusal comes BEFORE any work — no write, and no location fix burned on an empty note.
    func testCaptureNote_emptyIsRefusedBeforeAnyWork() async {
        let log = WriterLog()

        let outcome = await makeRunner(log).captureNote("   ")

        XCTAssertEqual(outcome, .rejected(reason: "The note was empty, so nothing was captured."))
        XCTAssertTrue(log.captureInputs.isEmpty)
        XCTAssertEqual(log.stampRequests, 0)
    }

    func testCaptureNote_failedWriteAnswersHonestly() async {
        let log = WriterLog()
        log.writesSucceed = false

        let outcome = await makeRunner(log).captureNote("Buy milk")

        XCTAssertEqual(
            outcome,
            .rejected(reason: "That didn't save — check you're signed in and online.")
        )
    }

    // MARK: - Log a journal line

    func testJournalLine_writesTrimmedStampedLog_andConfirms() async {
        let log = WriterLog()
        log.stamp = homeStamp

        let outcome = await makeRunner(log).journalLine("  Arrived at the gym  ")

        XCTAssertEqual(outcome, .saved(confirmation: "Journaled \u{201C}Arrived at the gym\u{201D}."))
        XCTAssertEqual(log.journalInputs.count, 1)
        XCTAssertEqual(log.journalInputs.first?.body, "Arrived at the gym")
        XCTAssertEqual(log.journalInputs.first?.type, .log)
        XCTAssertNil(log.journalInputs.first?.lifeAreaId)
        XCTAssertEqual(log.journalInputs.first?.locationStamp, homeStamp)
    }

    func testJournalLine_emptyIsRefusedBeforeAnyWork() async {
        let log = WriterLog()

        let outcome = await makeRunner(log).journalLine("")

        XCTAssertEqual(outcome, .rejected(reason: "The line was empty, so nothing was journaled."))
        XCTAssertTrue(log.journalInputs.isEmpty)
        XCTAssertEqual(log.stampRequests, 0)
    }

    func testJournalLine_failedWriteAnswersHonestly() async {
        let log = WriterLog()
        log.writesSucceed = false

        let outcome = await makeRunner(log).journalLine("Arrived")

        XCTAssertEqual(
            outcome,
            .rejected(reason: "That didn't save — check you're signed in and online.")
        )
    }

    /// A record without a stamp is still a record — the capture path's "location is a bonus"
    /// rule holds from Shortcuts too.
    func testMissingStampNeverBlocksTheWrite() async {
        let log = WriterLog()

        let outcome = await makeRunner(log).journalLine("Arrived")

        XCTAssertEqual(outcome, .saved(confirmation: "Journaled \u{201C}Arrived\u{201D}."))
        XCTAssertNil(log.journalInputs.first?.locationStamp ?? nil)
    }
}
