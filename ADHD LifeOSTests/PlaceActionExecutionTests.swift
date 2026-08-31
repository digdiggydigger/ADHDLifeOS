//
//  PlaceActionExecutionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure half of F-PlaceActions-3-Execution: how a crossing splits a place's actions, what
/// each notification says, how a tap routes, and the wire between a posted notification and
/// the tap that answers it.
final class PlaceActionExecutionTests: XCTestCase {

    private func action(
        _ kind: PlaceAction.Kind, direction: PlaceActionDirection = .arrival
    ) -> PlaceAction {
        PlaceAction(id: UUID(), direction: direction, kind: kind)
    }

    // MARK: - The split

    func testSplit_partitionsAutoRunFromExternal() {
        let journal = action(.journalLine(body: "Arrived"))
        let capture = action(.createCapture(text: "Check the mail"))
        let spotify = action(.openApp(scheme: "spotify", displayName: "Spotify"))
        let sprint = action(.startSprint(minutes: 25))

        let plan = PlaceActionPlan.split([journal, capture, spotify, sprint], for: .arrival)

        XCTAssertEqual(plan.autoRun, [journal, capture])
        XCTAssertEqual(plan.external, [spotify, sprint])
    }

    /// A departure action must not run on arrival — the direction split IS the firing rule's
    /// per-action half.
    func testSplit_filtersByDirection() {
        let leaving = action(
            .textContact(contactName: "Home", phoneNumber: "+44111", messageBody: "On my way"),
            direction: .departure
        )
        let arriving = action(.openApp(scheme: "spotify", displayName: "Spotify"))

        let plan = PlaceActionPlan.split([leaving, arriving], for: .departure)

        XCTAssertEqual(plan.external, [leaving])
        XCTAssertTrue(plan.autoRun.isEmpty)
    }

    /// An unsupported action holds its fence but cannot RUN here — and must never post a
    /// notification whose tap this build couldn't honour.
    func testSplit_dropsUnsupportedActionsFromBothHalves() {
        let future = action(.unsupported(rawKind: "play_soundscape", payload: [:]))

        let plan = PlaceActionPlan.split([future], for: .arrival)

        XCTAssertTrue(plan.autoRun.isEmpty)
        XCTAssertTrue(plan.external.isEmpty)
    }

    func testSplit_nilActionsMeanNothing() {
        let plan = PlaceActionPlan.split(nil, for: .arrival)
        XCTAssertTrue(plan.autoRun.isEmpty)
        XCTAssertTrue(plan.external.isEmpty)
    }

    // MARK: - Notification content

    func testExternalContent_titleIsTheRowLabelAndBodyNamesThePlace() {
        let spotify = action(.openApp(scheme: "spotify", displayName: "Spotify"))

        let content = PlaceActionNotificationContent.external(
            for: spotify, placeName: "Gym 💪", kind: .arrival
        )

        XCTAssertEqual(content.title, "Open Spotify")
        XCTAssertEqual(content.body, "You're at Gym 💪 — tap to open.")
    }

    /// The text action says out loud that Send stays with E — Apple's floor, stated rather
    /// than discovered.
    func testExternalContent_textActionIsHonestAboutSending() {
        let text = action(
            .textContact(contactName: "Ben", phoneNumber: "+44123", messageBody: "Here"),
            direction: .departure
        )

        let content = PlaceActionNotificationContent.external(
            for: text, placeName: "School", kind: .departure
        )

        XCTAssertEqual(content.title, "Text Ben")
        XCTAssertEqual(content.body, "Leaving School — tap to fill the message in — sending stays with you.")
    }

    func testRanLines_coverExactlyTheAutoRunKinds() {
        XCTAssertEqual(
            PlaceActionNotificationContent.ranLine(for: action(.journalLine(body: "Arrived"))),
            "Journaled \u{201C}Arrived\u{201D}"
        )
        XCTAssertEqual(
            PlaceActionNotificationContent.ranLine(for: action(.createCapture(text: "Milk"))),
            "Captured \u{201C}Milk\u{201D} to your inbox"
        )
        XCTAssertNil(
            PlaceActionNotificationContent.ranLine(
                for: action(.openApp(scheme: "spotify", displayName: "Spotify"))
            )
        )
    }

    // MARK: - The tap wire

    func testUserInfo_roundTripsTheAction() throws {
        let original = action(
            .textContact(contactName: "Ben", phoneNumber: "+44123", messageBody: "Here!")
        )

        let userInfo = try XCTUnwrap(PlaceActionNotificationContent.userInfo(for: original))
        let decoded = PlaceActionNotificationContent.action(fromUserInfo: userInfo)

        XCTAssertEqual(decoded, original)
    }

    func testIdentifier_carriesThePrefixAndTheActionId() {
        let spotify = action(.openApp(scheme: "spotify", displayName: "Spotify"))
        let identifier = PlaceActionNotificationContent.identifier(for: spotify)
        XCTAssertTrue(identifier.hasPrefix("placeAction-"))
        XCTAssertTrue(identifier.contains(spotify.id.uuidString))
    }

    // MARK: - Tap routes

    func testRoute_openAppBuildsTheSchemeURL() {
        let route = PlaceActionTapRoute.route(
            for: action(.openApp(scheme: "spotify", displayName: "Spotify"))
        )
        XCTAssertEqual(route, .open(URL(string: "spotify://")!))
    }

    func testRoute_textBuildsAnSMSComposeWithTheBodyEncoded() {
        let route = PlaceActionTapRoute.route(for: action(
            .textContact(contactName: "Ben", phoneNumber: "+44 7700 900123", messageBody: "On my way")
        ))
        XCTAssertEqual(route, .open(URL(string: "sms:+447700900123&body=On%20my%20way")!))
    }

    func testRoute_sprintAndScreenAreInAppDoors() {
        XCTAssertEqual(
            PlaceActionTapRoute.route(for: action(.startSprint(minutes: 25))),
            .startSprint(minutes: 25)
        )
        XCTAssertEqual(
            PlaceActionTapRoute.route(for: action(.openScreen(screen: "journal"))),
            .goToScreen(.journal)
        )
    }

    /// Auto-run kinds never post a tap notification, and an unsupported action cannot be
    /// honoured — no route for any of them.
    func testRoute_isNilForAutoRunAndUnsupportedKinds() {
        XCTAssertNil(PlaceActionTapRoute.route(for: action(.journalLine(body: "x"))))
        XCTAssertNil(PlaceActionTapRoute.route(for: action(.createCapture(text: "x"))))
        XCTAssertNil(PlaceActionTapRoute.route(
            for: action(.unsupported(rawKind: "future", payload: [:]))
        ))
    }

    /// The tapped sprint door: explicit minutes win; `nil` resolves to E's default AT TAP TIME.
    func testSprintPlan_resolvesMinutesAgainstTheDefault() {
        let explicit = PlaceActionSprint.plan(minutes: 25, defaultMinutes: 15)
        XCTAssertEqual(explicit.durationSeconds, 25 * 60)
        XCTAssertNil(explicit.taskId, "a place sprint is task-less — the place is the context")

        let fallback = PlaceActionSprint.plan(minutes: nil, defaultMinutes: 15)
        XCTAssertEqual(fallback.durationSeconds, 15 * 60)
    }

    /// Every screen token lands on a tab — total over both enums, so a new case cannot ship
    /// without deciding its mapping.
    func testScreenToTabMap_isTotal() {
        XCTAssertEqual(PlaceActionScreen.today.appTab, .today)
        XCTAssertEqual(PlaceActionScreen.tasks.appTab, .tasks)
        XCTAssertEqual(PlaceActionScreen.areas.appTab, .areas)
        XCTAssertEqual(PlaceActionScreen.journal.appTab, .journal)
        XCTAssertEqual(PlaceActionScreen.captures.appTab, .captures)
    }
}

/// The router: prefix discrimination, URL hand-off, and the pending-door replay that survives a
/// cold launch (the `FocusNotificationRouter` pattern).
@MainActor
final class PlaceActionNotificationRouterTests: XCTestCase {

    private func userInfo(for action: PlaceAction) -> [AnyHashable: Any] {
        (PlaceActionNotificationContent.userInfo(for: action) ?? [:]) as [AnyHashable: Any]
    }

    func testHandle_ignoresForeignIdentifiers() {
        let router = PlaceActionNotificationRouter()
        let handled = router.handle(
            notificationIdentifier: "focusSprintEnd", userInfo: [:], openURL: { _, _ in
                XCTFail("a foreign identifier must not open anything")
            }
        )
        XCTAssertFalse(handled)
    }

    func testHandle_opensAnExternalURLRoute() {
        let router = PlaceActionNotificationRouter()
        let spotify = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
        var opened: URL?

        let handled = router.handle(
            notificationIdentifier: PlaceActionNotificationContent.identifier(for: spotify),
            userInfo: userInfo(for: spotify),
            openURL: { url, _ in opened = url }
        )

        XCTAssertTrue(handled)
        XCTAssertEqual(opened, URL(string: "spotify://"))
    }

    /// The open comes with the words to surface if it FAILS — an uninstalled app must say so,
    /// never silence (the block's honesty criterion).
    func testHandle_handsOverAnHonestFailureBody() {
        let router = PlaceActionNotificationRouter()
        let spotify = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
        var failureBody: String?

        _ = router.handle(
            notificationIdentifier: PlaceActionNotificationContent.identifier(for: spotify),
            userInfo: userInfo(for: spotify),
            openURL: { _, body in failureBody = body }
        )

        XCTAssertEqual(
            failureBody,
            "\u{201C}Open Spotify\u{201D} didn't work — the app may not be installed."
        )
    }

    func testHandle_deliversAnInAppDoorToTheConnectedHandler() {
        let router = PlaceActionNotificationRouter()
        var doors: [PlaceActionDoor] = []
        router.connect { doors.append($0) }
        let sprint = PlaceAction(id: UUID(), direction: .arrival, kind: .startSprint(minutes: 25))

        _ = router.handle(
            notificationIdentifier: PlaceActionNotificationContent.identifier(for: sprint),
            userInfo: userInfo(for: sprint),
            openURL: { _, _ in XCTFail("an in-app door is not a URL") }
        )

        XCTAssertEqual(doors, [.sprint(minutes: 25)])
    }

    /// A tap on a cold launch beats the UI to the punch — the door waits and replays on
    /// connect, exactly once.
    func testHandle_beforeConnect_holdsTheDoorAndReplaysIt() {
        let router = PlaceActionNotificationRouter()
        let screen = PlaceAction(
            id: UUID(), direction: .arrival, kind: .openScreen(screen: "journal")
        )
        _ = router.handle(
            notificationIdentifier: PlaceActionNotificationContent.identifier(for: screen),
            userInfo: userInfo(for: screen),
            openURL: { _, _ in }
        )

        var doors: [PlaceActionDoor] = []
        router.connect { doors.append($0) }

        XCTAssertEqual(doors, [.screen(.journal)])
    }

    /// Ours-but-broken (userInfo missing or undecodable) is still HANDLED — falling through to
    /// the focus router with a placeAction identifier would be worse than doing nothing.
    func testHandle_brokenUserInfoIsStillClaimed() {
        let router = PlaceActionNotificationRouter()
        let handled = router.handle(
            notificationIdentifier: "placeAction-XYZ", userInfo: [:], openURL: { _, _ in
                XCTFail("nothing to open")
            }
        )
        XCTAssertTrue(handled)
    }
}
