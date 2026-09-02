//
//  PlaceOpenLinkExecutionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// What the rest of the machine does with an `open_link` action (F-AppDirectory-2-Links):
/// the split, the tap route, the row label, the notification copy, and the automation guide.
final class PlaceOpenLinkExecutionTests: XCTestCase {

    private func linkAction(direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .openLink(
                displayName: "Spotify — A playlist",
                link: "https://open.spotify.com/playlist/abc123",
                scheme: "spotify"
            )
        )
    }

    /// Opening another app (or the web) needs a foreground tap — iOS forbids it from a
    /// background wake — so `open_link` belongs with the externals, one notification each.
    func testSplit_openLinkIsExternal() {
        let action = linkAction()
        let (autoRun, external) = PlaceActionPlan.split([action], for: .arrival)
        XCTAssertTrue(autoRun.isEmpty)
        XCTAssertEqual(external, [action])
    }

    func testRoute_openLinkOpensItsLink() {
        let route = PlaceActionTapRoute.route(for: linkAction())
        XCTAssertEqual(
            route, .open(URL(string: "https://open.spotify.com/playlist/abc123")!)
        )
    }

    /// A link whose string cannot become a URL has no route — same contract as `open_url`.
    func testRoute_unparseableLinkHasNoRoute() {
        let broken = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openLink(displayName: "Broken", link: "", scheme: nil)
        )
        XCTAssertNil(PlaceActionTapRoute.route(for: broken))
    }

    func testRowLabel_openLinkNamesItsDestination() {
        XCTAssertEqual(
            PlaceActionRowLabel.title(for: linkAction()),
            "Open Spotify — A playlist"
        )
    }

    /// The `default:` in the copy switch is the one branch no compiler holds — only this test.
    func testNotificationCopy_openLinkSaysTapToOpen() {
        let content = PlaceActionNotificationContent.external(
            for: linkAction(), placeName: "Gym", kind: .arrival
        )
        XCTAssertEqual(content.title, "Open Spotify — A playlist")
        XCTAssertEqual(content.body, "You're at Gym — tap to open.")
    }

    func testRanLine_openLinkNeverAutoRuns() {
        XCTAssertNil(PlaceActionNotificationContent.ranLine(for: linkAction()))
    }

    /// Shortcuts CAN automate a link open — same "Open URLs" action the open_url guide uses.
    func testAutomationGuide_openLinkGetsAnOpenURLsStep() throws {
        let guide = try XCTUnwrap(PlaceAutomationGuide.make(for: linkAction(), placeName: "Gym"))
        XCTAssertEqual(guide.title, "Make \u{201C}Open Spotify — A playlist\u{201D} automatic")
        XCTAssertTrue(
            guide.steps.contains(
                "Add the \u{201C}Open URLs\u{201D} action and enter "
                + "https://open.spotify.com/playlist/abc123."
            ),
            "steps were: \(guide.steps)"
        )
    }
}
