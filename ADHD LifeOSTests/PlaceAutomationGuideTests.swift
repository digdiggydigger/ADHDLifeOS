//
//  PlaceAutomationGuideTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The "Make this automatic" walkthrough (F-PlaceActions-4-Shortcuts). Apple allows no
/// programmatic creation of automations, so the guide IS the feature — which makes its words
/// the behaviour, pinned here exactly: the honesty preamble (every step is E's), the
/// per-direction Shortcuts steps, and the per-kind action step. Kinds Shortcuts cannot
/// automate get no guide at all rather than a guide that overpromises.
final class PlaceAutomationGuideTests: XCTestCase {

    private func action(_ kind: PlaceAction.Kind, direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(id: UUID(), direction: direction, kind: kind)
    }

    // MARK: - The full guide, pinned once end to end

    func testOpenAppArrival_pinsTheWholeGuide() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(.openApp(scheme: "spotify", displayName: "Spotify")),
            placeName: "Home"
        ))

        XCTAssertEqual(guide.title, "Make \u{201C}Open Spotify\u{201D} automatic")
        XCTAssertEqual(
            guide.intro,
            "Apple doesn't let any app build an automation for you, so every step here is "
            + "yours to tap. There are only a few — and once it's set up, this runs with no "
            + "taps at all."
        )
        XCTAssertEqual(guide.steps, [
            "In Shortcuts, open the Automation tab and tap +.",
            "Choose \u{201C}Arrive\u{201D}, and set the location to Home.",
            "Pick \u{201C}Run Immediately\u{201D}, so it doesn't ask you first each time.",
            "Add the \u{201C}Open App\u{201D} action and choose Spotify."
        ])
        XCTAssertEqual(
            guide.afterword,
            "Once the automation is running, you can delete this action here — otherwise "
            + "you'll keep getting its one-tap notification as well."
        )
    }

    // MARK: - Direction and place

    func testDeparture_saysLeave() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(
                .textContact(contactName: "Alice", phoneNumber: "+447700900123", messageBody: "On my way"),
                direction: .departure
            ),
            placeName: "Work"
        ))

        XCTAssertEqual(
            guide.steps[1],
            "Choose \u{201C}Leave\u{201D}, and set the location to Work."
        )
    }

    /// A guide opened mid-edit, before the place has a name, still reads as a sentence.
    func testBlankPlaceNameFallsBackToThisPlace() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(.openApp(scheme: "spotify", displayName: "Spotify")),
            placeName: "   "
        ))

        XCTAssertEqual(
            guide.steps[1],
            "Choose \u{201C}Arrive\u{201D}, and set the location to this place."
        )
    }

    // MARK: - The per-kind action step

    func testTextContact_stepNamesRecipientAndMessage() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(
                .textContact(contactName: "Alice", phoneNumber: "+447700900123", messageBody: "On my way")
            ),
            placeName: "Home"
        ))

        XCTAssertEqual(
            guide.steps[3],
            "Add the \u{201C}Send Message\u{201D} action, send it to Alice, and type the "
            + "message: \u{201C}On my way\u{201D}."
        )
    }

    func testOpenURL_stepCarriesTheAddress() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(.openURL(urlString: "https://example.com/page")),
            placeName: "Home"
        ))

        XCTAssertEqual(
            guide.steps[3],
            "Add the \u{201C}Open URLs\u{201D} action and enter https://example.com/page."
        )
    }

    func testStartSprint_withMinutes_namesOurIntentAndTheAppOpening() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(.startSprint(minutes: 25)),
            placeName: "Home"
        ))

        XCTAssertEqual(
            guide.steps[3],
            "Add ADHD LifeOS's \u{201C}Start a sprint\u{201D} action and set Minutes to 25 — "
            + "it opens the app to run the timer."
        )
    }

    func testStartSprint_withoutMinutes_saysDefaultLength() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(
            for: action(.startSprint(minutes: nil)),
            placeName: "Home"
        ))

        XCTAssertEqual(
            guide.steps[3],
            "Add ADHD LifeOS's \u{201C}Start a sprint\u{201D} action and leave Minutes empty "
            + "to use your default length — it opens the app to run the timer."
        )
    }

    // MARK: - The honest ceiling: what gets no guide

    /// Journal lines and captures already run zero-touch on OUR fences; a screen has no
    /// Shortcuts action that could reach it; an unsupported action is a promise this build
    /// cannot read, let alone teach.
    func testKindsShortcutsCannotAutomateGetNoGuide() {
        XCTAssertNil(PlaceAutomationGuide.make(
            for: action(.journalLine(body: "Arrived")), placeName: "Home"
        ))
        XCTAssertNil(PlaceAutomationGuide.make(
            for: action(.createCapture(text: "A thought")), placeName: "Home"
        ))
        XCTAssertNil(PlaceAutomationGuide.make(
            for: action(.openScreen(screen: "journal")), placeName: "Home"
        ))
        XCTAssertNil(PlaceAutomationGuide.make(
            for: action(.unsupported(rawKind: "play_playlist", payload: [:])), placeName: "Home"
        ))
    }

    // MARK: - The door into Apple's app

    func testShortcutsAppURL() {
        XCTAssertEqual(PlaceAutomationGuide.shortcutsAppURLString, "shortcuts://")
    }
}
