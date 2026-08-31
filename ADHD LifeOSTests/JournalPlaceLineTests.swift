//
//  JournalPlaceLineTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The journal entry row's place line — "Journal · 🫀 Health · at The Office 💼" (E's approved
/// design canvas, artboard C, chosen 2026-08-28 from four candidate surfaces).
///
/// Block 3 has stamped `place_id` on journal entries, closed tasks and sprints since `a16817e`,
/// but only captures ever SHOWED it. E picked the journal row and declined the other three:
/// a place line on every row is noise in something that exists to be scanned. Do not add the
/// others back without asking.
///
/// The rules are `CapturePlaceLabel`'s, verbatim — named places only, resolved through the
/// place's CURRENT record — with the journal's own emoji-trailing spelling
/// (`JournalTimeline.locationEventLine` already reads "Arrived at The Office 💼").
final class JournalPlaceLineTests: XCTestCase {

    private let officeId = UUID()

    private func office(name: String = "The Office", emoji: String? = "💼") -> Place {
        Place(
            id: officeId, name: name,
            coordinate: PlaceCoordinate(latitude: 51.5203, longitude: -0.0986),
            radiusMetres: 200, emoji: emoji
        )
    }

    private func entry(
        type: LogType = .journal, placeId: UUID? = nil, latitude: Double? = nil
    ) -> Log {
        Log(
            id: UUID(), lifeAreaId: nil, type: type, body: "Slept badly, still shipped",
            entryDate: Date(timeIntervalSince1970: 1_756_296_000),
            createdAt: Date(timeIntervalSince1970: 1_756_296_000),
            placeId: placeId, latitude: latitude
        )
    }

    func testPlaceLine_namedPlace_readsAsTheCanvasWroteIt() {
        let line = JournalTimeline.placeLine(for: entry(placeId: officeId), places: [office()])

        XCTAssertEqual(line, "at The Office 💼")
    }

    func testPlaceLine_placeWithoutAnEmoji_isJustTheName() {
        let line = JournalTimeline.placeLine(
            for: entry(placeId: officeId), places: [office(emoji: nil)]
        )

        XCTAssertEqual(line, "at The Office")
    }

    /// An entry written outside every named place still stores its coordinate, and still says
    /// nothing: a bare latitude means nothing at a glance, and most entries are written away from
    /// a saved place.
    func testPlaceLine_coordinateWithoutANamedPlace_saysNothing() {
        XCTAssertNil(
            JournalTimeline.placeLine(for: entry(latitude: 51.5), places: [office()])
        )
    }

    func testPlaceLine_unstampedEntry_saysNothing() {
        XCTAssertNil(JournalTimeline.placeLine(for: entry(), places: [office()]))
    }

    /// The place was deleted since. It must read as no label, never as a raw UUID.
    func testPlaceLine_danglingPlace_saysNothing() {
        XCTAssertNil(JournalTimeline.placeLine(for: entry(placeId: officeId), places: []))
    }

    /// Resolved through the place's CURRENT record — which is the whole reason the id is stored
    /// rather than the name.
    func testPlaceLine_followsARenamedPlace() {
        let line = JournalTimeline.placeLine(
            for: entry(placeId: officeId), places: [office(name: "The Studio", emoji: "🎛️")]
        )

        XCTAssertEqual(line, "at The Studio 🎛️")
    }

    /// Block 3 stamps BOTH `.log` and `.journal` (energy/mood's journal-only rule is web parity,
    /// which location has none of), so a quick log shows its place too.
    func testPlaceLine_quickLogCarriesItToo() {
        let line = JournalTimeline.placeLine(
            for: entry(type: .log, placeId: officeId), places: [office()]
        )

        XCTAssertEqual(line, "at The Office 💼")
    }

    /// The composer's live preview (E, 2026-08-31) resolves a bare `placeId` through the SAME
    /// spelling as the saved row it becomes — one rule, not a hand-rolled twin. The log-taking
    /// overload above delegates here, so these two can never drift apart.
    func testPlaceLine_byPlaceId_matchesTheRowSpelling() {
        XCTAssertEqual(
            JournalTimeline.placeLine(placeId: officeId, places: [office()]),
            "at The Office 💼"
        )
        XCTAssertNil(JournalTimeline.placeLine(placeId: nil, places: [office()]))
        XCTAssertNil(JournalTimeline.placeLine(placeId: officeId, places: []))
    }
}
