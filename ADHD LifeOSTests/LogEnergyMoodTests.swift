//
//  LogEnergyMoodTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The journal's energy level and mood emoji — the web's `JournalEntry.energyLevel` /
/// `moodEmoji` (`src/types.ts`), ported onto the Swift `Log`.
///
/// The whole risk of this block is the SCHEMA: E's Firestore already holds journal entries written
/// before these fields existed, and `Log` is decoded straight off the document. Both fields are
/// therefore optional — a legacy entry decodes cleanly and reads as "not recorded", which is the
/// truth. Defaulting them to `.medium` / "⚡" would have every historical entry assert a mood the
/// user never chose.
final class LogEnergyMoodTests: XCTestCase {
    private let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func log(
        type: LogType = .journal,
        energyLevel: EnergyLevel? = .medium,
        moodEmoji: String? = "⚡"
    ) -> Log {
        Log(
            id: id, lifeAreaId: nil, type: type, body: "Felt sharp today",
            entryDate: date, createdAt: date, energyLevel: energyLevel, moodEmoji: moodEmoji
        )
    }

    // MARK: - EnergyLevel

    func testEnergyLevel_rawValuesMatchTheWebsStringUnion() {
        // `'low' | 'medium' | 'high'` in src/types.ts — these strings go into Firestore, so they
        // are a wire contract, not a display detail.
        XCTAssertEqual(EnergyLevel.low.rawValue, "low")
        XCTAssertEqual(EnergyLevel.medium.rawValue, "medium")
        XCTAssertEqual(EnergyLevel.high.rawValue, "high")
        XCTAssertEqual(EnergyLevel.allCases.map(\.rawValue), ["low", "medium", "high"])
    }

    func testEnergyLevel_eachCaseCarriesItsOwnGlyphAndTitle() {
        // Status is never carried by colour alone (§4), so every level has words AND a glyph.
        XCTAssertEqual(Set(EnergyLevel.allCases.map(\.glyph)).count, 3)
        XCTAssertEqual(Set(EnergyLevel.allCases.map(\.title)).count, 3)
        XCTAssertFalse(EnergyLevel.allCases.contains { $0.title.isEmpty })
    }

    func testEnergyLevel_chipLabelMirrorsTheWebsReadout() {
        // The web journal list renders `{entry.energyLevel} energy`.
        XCTAssertEqual(EnergyLevel.low.chipLabel, "low energy")
        XCTAssertEqual(EnergyLevel.high.chipLabel, "high energy")
    }

    // MARK: - Mood options

    func testMoodOptions_areTheWebsEightInOrder() {
        XCTAssertEqual(
            JournalMood.options,
            ["⚡", "🔥", "🧘", "🔋", "😴", "🧠", "🌊", "🎯"],
            "ported verbatim from JournalView.tsx's moodOptions"
        )
    }

    func testMoodOptions_defaultIsTheWebsInitialSelection() {
        XCTAssertEqual(JournalMood.defaultEmoji, "⚡")
        XCTAssertTrue(JournalMood.options.contains(JournalMood.defaultEmoji))
    }

    // MARK: - Codable

    func testCodableRoundTrip_preservesEnergyAndMood() throws {
        let original = log(energyLevel: .high, moodEmoji: "🔥")

        let decoded = try JSONDecoder().decode(Log.self, from: try JSONEncoder().encode(original))

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.energyLevel, .high)
        XCTAssertEqual(decoded.moodEmoji, "🔥")
    }

    func testEncoding_usesTheProjectsSnakeCaseWireKeys() throws {
        let data = try JSONEncoder().encode(log(energyLevel: .low, moodEmoji: "😴"))
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("energy_level"), json)
        XCTAssertTrue(json.contains("mood_emoji"), json)
    }

    /// The one that matters: every journal entry E has already written is missing both keys.
    func testDecoding_aLegacyEntryWithoutTheFields_readsAsNotRecorded() throws {
        let legacy = """
        {
          "id": "\(id.uuidString)",
          "type": "journal",
          "body": "Written before energy and mood existed",
          "entry_date": \(date.timeIntervalSinceReferenceDate),
          "created_at": \(date.timeIntervalSinceReferenceDate)
        }
        """

        let decoded = try JSONDecoder().decode(Log.self, from: Data(legacy.utf8))

        XCTAssertNil(decoded.energyLevel, "absent must never be reported as 'medium'")
        XCTAssertNil(decoded.moodEmoji)
        XCTAssertEqual(decoded.body, "Written before energy and mood existed")
    }

    /// An unrecognised level must not take the whole journal list down with it.
    func testDecoding_anUnknownEnergyLevel_degradesToNotRecorded() throws {
        let future = """
        {
          "id": "\(id.uuidString)",
          "type": "journal",
          "body": "From a later build",
          "entry_date": \(date.timeIntervalSinceReferenceDate),
          "created_at": \(date.timeIntervalSinceReferenceDate),
          "energy_level": "transcendent"
        }
        """

        let decoded = try JSONDecoder().decode(Log.self, from: Data(future.utf8))

        XCTAssertNil(decoded.energyLevel)
    }

    // MARK: - Validation

    func testNormalize_carriesEnergyAndMoodForAJournalEntry() throws {
        let result = LogValidation.normalizeCreateLogInput(
            body: "  Felt sharp  ", type: .journal, lifeAreaId: nil,
            energyLevel: .high, moodEmoji: "🔥"
        )

        let input = try XCTUnwrap(try? result.get())
        XCTAssertEqual(input.body, "Felt sharp")
        XCTAssertEqual(input.energyLevel, .high)
        XCTAssertEqual(input.moodEmoji, "🔥")
    }

    /// The web keeps these on `JournalEntry` only — a quick `LogEntry` has no energy or mood. Swift
    /// unifies the two behind `LogType`, so the rule has to be enforced here instead of by the type.
    func testNormalize_stripsEnergyAndMoodFromAQuickLog() throws {
        let result = LogValidation.normalizeCreateLogInput(
            body: "Ring the dentist", type: .log, lifeAreaId: nil,
            energyLevel: .high, moodEmoji: "🔥"
        )

        let input = try XCTUnwrap(try? result.get())
        XCTAssertNil(input.energyLevel, "a quick log is not a mood reading")
        XCTAssertNil(input.moodEmoji)
    }

    func testNormalize_stillRejectsAnEmptyBody() {
        let result = LogValidation.normalizeCreateLogInput(
            body: "   ", type: .journal, lifeAreaId: nil, energyLevel: .high, moodEmoji: "🔥"
        )

        XCTAssertEqual(result, .failure(.emptyBody))
    }

    func testNormalize_treatsABlankMoodAsUnset() {
        let result = LogValidation.normalizeCreateLogInput(
            body: "Something", type: .journal, lifeAreaId: nil, energyLevel: .medium, moodEmoji: "  "
        )

        XCTAssertNil(try? result.get().moodEmoji)
    }

    func testNormalize_withoutEnergyOrMood_leavesThemUnset() throws {
        let result = LogValidation.normalizeCreateLogInput(
            body: "Something", type: .journal, lifeAreaId: nil
        )

        let input = try XCTUnwrap(try? result.get())
        XCTAssertNil(input.energyLevel)
        XCTAssertNil(input.moodEmoji)
    }
}
