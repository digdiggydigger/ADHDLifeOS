//
//  ToolsRoutinesCatalogTests.swift
//  ADHD LifeOSTests
//
//  The Routines section of the Tools page, as a pure list (F-Routines-B-ToolsSection).
//
//  **The whole point of this type is that it does NOT decide anything.** A routine still has no
//  independent existence — it IS a place's actions for one direction — so every membership and
//  counting question is answered by `PlaceRoutinePlan`, and this file's job is to prove the
//  catalog asks rather than re-deciding. A second spelling of the ≥2 rule, or a second way to
//  count steps, is the two-truths defect this repo keeps producing (see
//  `CaptureInboxTriageCountsTests` for the last one).
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsRoutinesCatalogTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    // MARK: - Fixtures

    private func openApp(
        _ name: String, _ direction: PlaceActionDirection = .arrival
    ) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .openApp(scheme: name.lowercased(), displayName: name)
        )
    }

    private func journal(_ direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(id: UUID(), direction: direction, kind: .journalLine(body: "Leg day"))
    }

    private func unsupported(_ direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .unsupported(rawKind: "teleport", payload: ["speed": .string("fast")])
        )
    }

    private func place(
        _ name: String, emoji: String? = nil, actions: [PlaceAction] = []
    ) -> Place {
        Place(
            id: UUID(), name: name, coordinate: coordinate, radiusMetres: 200,
            emoji: emoji, actions: actions
        )
    }

    /// A place carrying exactly the threshold number of tap-steps, DERIVED from the constant —
    /// so if E ever retunes `RoutineDefaults.stepThreshold` these tests follow it instead of
    /// pinning a stale 2 that the rest of the arc no longer believes.
    private func qualifyingPlace(
        _ name: String, emoji: String? = nil, direction: PlaceActionDirection = .arrival
    ) -> Place {
        let steps = (0..<RoutineDefaults.stepThreshold).map { openApp("App\($0)", direction) }
        return place(name, emoji: emoji, actions: steps)
    }

    // MARK: - Membership is PlaceRoutinePlan's decision, never this type's

    func testAPlaceBelowTheThresholdIsNotARoutine() {
        let single = place("Home", actions: [openApp("Spotify")])

        XCTAssertEqual(
            ToolsRoutinesCatalog.rows(from: [single]), [],
            "A place with one tap-step was listed as a routine. Below the threshold the crossing"
                + " keeps today's direct per-action notification — listing it here promises a"
                + " routine screen that will never open."
        )
    }

    func testAPlaceAtTheThresholdIsARoutine() {
        let rows = ToolsRoutinesCatalog.rows(from: [qualifyingPlace("Home")])

        XCTAssertEqual(rows.count, 1, "A place at the threshold produced no routine row.")
    }

    /// The count on the row must be the count in the notification and on the Today card:
    /// TAP-steps. An auto step runs itself and is never "ready" for anything.
    func testAutoRunStepsAreNamedNowhereInTheCount() {
        let mixed = place("Home", actions: [journal(), openApp("Spotify"), openApp("Maps")])

        let rows = ToolsRoutinesCatalog.rows(from: [mixed])

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(
            rows.first?.subtitle, "Home · 2 steps",
            "The row counted the auto-run journal line as a step. The banner says \"2 steps"
                + " ready\" for this same place — two truths about one routine is the defect this"
                + " repo produces most."
        )
    }

    /// An auto step CANNOT carry a place over the line on its own.
    func testAutoRunStepsCannotMakeAPlaceQualify() {
        let autoHeavy = place("Home", actions: [journal(), journal(), openApp("Spotify")])

        XCTAssertEqual(
            ToolsRoutinesCatalog.rows(from: [autoHeavy]), [],
            "Two journal lines and one tap-step were treated as a routine. Only tap-steps count"
                + " toward the threshold — the crossing here still posts one direct notification."
        )
    }

    /// An action from a newer build is excluded by `PlaceRoutinePlan.make` (this build can
    /// neither run it nor honour its tap). Surprising but correct, and pinned so a later reading
    /// cannot "fix" it into a forever-pending step.
    func testUnsupportedActionsNeitherCountNorAppear() {
        let futureBuild = place("Home", actions: [openApp("Spotify"), unsupported()])

        XCTAssertEqual(
            ToolsRoutinesCatalog.rows(from: [futureBuild]), [],
            "An `.unsupported` action was counted toward the threshold. This build cannot run it,"
                + " so a routine built on it would show a step that can never complete."
        )
    }

    // MARK: - One place, two directions, two routines

    func testEachDirectionIsItsOwnRowWithArrivalFirst() {
        let both = place("Home", actions: [
            openApp("Spotify", .arrival), openApp("Maps", .arrival),
            openApp("Podcasts", .departure), openApp("Messages", .departure)
        ])

        let rows = ToolsRoutinesCatalog.rows(from: [both])

        XCTAssertEqual(rows.map(\.kind), [.arrival, .departure],
                       "A place's two directions must be two rows, arrival first — you meet the"
                           + " arrival routine first in the day and in the editor.")
        XCTAssertEqual(rows.map(\.title), ["When you arrive", "When you leave"])
    }

    func testOneDirectionQualifyingDoesNotDragTheOtherIn() {
        let lopsided = place("Home", actions: [
            openApp("Spotify", .arrival), openApp("Maps", .arrival),
            openApp("Podcasts", .departure)
        ])

        XCTAssertEqual(
            ToolsRoutinesCatalog.rows(from: [lopsided]).map(\.kind), [.arrival],
            "The departure direction has one tap-step and was listed anyway. Directions are"
                + " judged independently — that is the whole reason they are separate rows."
        )
    }

    // MARK: - Order, identity, glyph

    /// The same comparator the Places list uses, reused rather than copied: two screens listing
    /// the same places in different orders is a small lie that costs real time to re-scan.
    func testRowsFollowThePlacesListOrder() {
        let places = [qualifyingPlace("office"), qualifyingPlace("Attic"), qualifyingPlace("Home")]

        let names = ToolsRoutinesCatalog.rows(from: places).map(\.subtitle)

        XCTAssertEqual(
            names, ["Attic · 2 steps", "Home · 2 steps", "office · 2 steps"],
            "Routine rows are not in the Places list's alphabetical, case-insensitive order."
                + " `PlacesService.sorted` is the one comparator — note lowercase \"office\""
                + " sorts last only if the compare is case-INsensitive."
        )
    }

    func testIdentifiersAreUniquePerPlaceAndDirection() {
        let both = place("Home", actions: [
            openApp("Spotify", .arrival), openApp("Maps", .arrival),
            openApp("Podcasts", .departure), openApp("Messages", .departure)
        ])

        let identifiers = ToolsRoutinesCatalog.rows(from: [both]).map(\.accessibilityIdentifier)

        XCTAssertEqual(
            Set(identifiers).count, identifiers.count,
            "A place's two routines share an accessibility identifier, so a journey addressing"
                + " one gets an ambiguous match rather than a row."
        )
        for identifier in identifiers {
            XCTAssertTrue(identifier.hasPrefix("toolsRoutineRow-"), "Unnamespaced: \(identifier)")
        }
    }

    func testTheGlyphIsThePlacesOwnEmojiAndFallsBackLikeThePlacesList() {
        let named = ToolsRoutinesCatalog.rows(from: [qualifyingPlace("Home", emoji: "🏠")])
        let bare = ToolsRoutinesCatalog.rows(from: [qualifyingPlace("Attic")])

        XCTAssertEqual(named.first?.glyph, "🏠")
        XCTAssertEqual(
            bare.first?.glyph, "📍",
            "A place with no emoji lost its glyph. `PlacesListView` falls back to 📍 — a blank"
                + " tile here would be a different-looking row for the same place."
        )
    }

    // MARK: - The two empty states are two different problems

    func testNoPlacesAtAllIsItsOwnEmptyState() {
        XCTAssertEqual(
            ToolsRoutinesCatalog.content(from: []), .empty(.noPlaces),
            "An account with no places got the wrong empty state. Its next action is to make a"
                + " place; telling it to add a second step to something it does not have is"
                + " advice it cannot follow."
        )
    }

    func testPlacesThatDoNotQualifyGetTheOtherEmptyState() {
        let ordinary = [place("Home", actions: [openApp("Spotify")]), place("Attic")]

        XCTAssertEqual(
            ToolsRoutinesCatalog.content(from: ordinary), .empty(.noQualifyingPlaces),
            "A place list with nothing qualifying got the no-places copy, which would read as a"
                + " lie to anyone looking at their own places one tab away."
        )
    }

    func testContentCarriesTheRowsWhenThereAreAny() {
        let content = ToolsRoutinesCatalog.content(from: [qualifyingPlace("Home")])

        guard case .rows(let rows) = content else {
            return XCTFail("A qualifying place produced an empty state rather than rows.")
        }
        XCTAssertEqual(rows.count, 1)
    }

    /// The first-run state is the one nothing in this repo tests, because every journey seeds
    /// what it is about before launching. So the copy is asserted to EXIST here rather than
    /// discovered missing by the first person to install the app.
    func testEveryEmptyStateIsFinishedCopy() {
        for reason in [ToolsRoutinesCatalog.EmptyReason.noPlaces, .noQualifyingPlaces] {
            XCTAssertFalse(reason.headline.isEmpty, "\(reason) has no headline.")
            XCTAssertFalse(reason.body.isEmpty, "\(reason) has no body copy.")
            XCTAssertFalse(reason.actionTitle.isEmpty, "\(reason) offers no way out.")
        }
        XCTAssertNotEqual(
            ToolsRoutinesCatalog.EmptyReason.noPlaces.body,
            ToolsRoutinesCatalog.EmptyReason.noQualifyingPlaces.body,
            "Both empty states say the same thing, so one of them is wrong for the person"
                + " reading it. They are two different problems with two different next actions."
        )
    }

    func testTheSectionIntroducesItself() {
        XCTAssertEqual(ToolsRoutinesCatalog.sectionTitle, "Routines")
        XCTAssertFalse(
            ToolsRoutinesCatalog.sectionCaption.isEmpty,
            "The section has no caption. The 2-tap-step rule is invisible in the UI otherwise —"
                + " nothing else on this page explains why a place is or is not listed."
        )
    }

    // MARK: - Plural safety at a retuned threshold

    /// `qualifiesAsRoutine` guarantees ≥ `stepThreshold`, so "1 step" is unreachable today —
    /// but the count is rendered from a variable and the threshold is a knob E owns. This costs
    /// one line and removes "1 steps" from the set of things a future tuning can ship.
    func testStepCountPluralisesRatherThanConcatenating() {
        XCTAssertEqual(ToolsRoutinesCatalog.stepsPhrase(1), "1 step")
        XCTAssertEqual(ToolsRoutinesCatalog.stepsPhrase(2), "2 steps")
        XCTAssertEqual(ToolsRoutinesCatalog.stepsPhrase(7), "7 steps")
    }

    // MARK: - The permission footer (E's 2026-09-07 ruling on the carried register item)

    /// The switch OFF empties the region plan — no fence registers, so no crossing, no
    /// notification, and under deferred logging the tap IS how a routine starts. "Can't start"
    /// is literally true (verified in `LocationTriggerService.refreshRegistrations`), and the
    /// copy must stay exactly that strong and no stronger.
    func testTheNudgesOffFooterShowsExactlyWhenTheArrivalNudgesSwitchIsOff() {
        XCTAssertTrue(ToolsRoutinesCatalog.showsNudgesOffFooter(arrivalNudgesEnabled: false))
        XCTAssertFalse(ToolsRoutinesCatalog.showsNudgesOffFooter(arrivalNudgesEnabled: true))
    }

    func testTheNudgesOffFooterWords() {
        XCTAssertEqual(ToolsRoutinesCatalog.NudgesOffFooter.headline, "Arrival nudges are off")
        XCTAssertEqual(
            ToolsRoutinesCatalog.NudgesOffFooter.body,
            "Routines start from the notification a crossing sends, and Arrival nudges is the"
                + " master switch over all of them — while it's off, none of these can start."
        )
        XCTAssertEqual(
            ToolsRoutinesCatalog.NudgesOffFooter.actionTitle,
            "Turn arrival nudges back on"
        )
    }
}
