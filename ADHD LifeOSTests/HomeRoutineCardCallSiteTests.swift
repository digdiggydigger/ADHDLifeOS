//
//  HomeRoutineCardCallSiteTests.swift
//  ADHD LifeOSTests
//
//  REACHABILITY, not correctness (the plan's explicit block-4 requirement, and this repo's
//  most repeated defect): every string in `HomeRoutineCardModel` can be perfect and tested
//  while nothing on Today renders it. A unit test over a pure type cannot see that, so this
//  reads the SOURCE — the layer the claim lives in.
//

import XCTest

final class HomeRoutineCardCallSiteTests: XCTestCase {

    func testTodayRendersTheRoutineCard() throws {
        let home = try Self.appSource("Home/HomeView.swift")

        XCTAssertTrue(
            home.contains("arrivalAndRoutineCards"),
            "Today must render the routine card. The card is the ONLY way back into a routine"
                + " whose notification was swiped away — unrendered, the run is unreachable."
        )
    }

    func testTheCardIsRefreshedOnEveryPathThatRefreshesTheArrivalCard() throws {
        let sections = try Self.appSource("Home/HomeMomentumSections.swift")

        XCTAssertTrue(
            sections.contains("refreshLiveRoutine()"),
            "the live run must be re-read wherever the arrival surface is — appear,"
                + " pull-to-refresh and the app-wide DataChangeSignal all run through it"
        )
    }

    /// `onDisappear` did NOT fire reliably for this full-screen cover — the routine journey
    /// caught a finished routine keeping its Today card. So every deliberate exit calls
    /// `leaveScreen()` itself, and the lifecycle callback is only a net.
    func testEveryExitFromTheScreenEndsTheRunItself() throws {
        let screen = try Self.appSource("Places/PlaceRoutineScreen.swift")

        XCTAssertTrue(
            screen.contains("DataChangeSignal.post()"),
            "closing the screen must move Today — otherwise a finished routine leaves a stale"
                + " card behind until something else happens to refresh"
        )
        XCTAssertEqual(
            screen.components(separatedBy: "leaveScreen()").count - 1, 5,
            "leaveScreen must be DECLARED once and called from all three exits — the Close"
                + " button, the background hook, and onDisappear as the net (plus the mention"
                + " in its own doc comment). Relying on onDisappear alone is fragile: it did"
                + " not fire reliably for this cover."
        )
        XCTAssertTrue(
            screen.contains("leaveScreen()\n                    dismiss()"),
            "the Close button must end the run BEFORE it dismisses — after dismiss the view"
                + " may already be gone"
        )
    }

    /// The foreground trigger is load-bearing, not belt-and-braces: a crossing while the app
    /// is backgrounded writes only UserDefaults, and a tap-steps-only routine writes nothing to
    /// Firestore — so no DataChangeSignal fires, and `.task` does not re-run on a warm return.
    /// Delete this hook and the recovery surface goes stale in exactly the case it exists for.
    func testTheCardRefreshesWhenTheAppComesBackToTheForeground() throws {
        let home = try Self.appSource("Home/HomeView.swift")

        XCTAssertTrue(
            home.contains("if phase == .active { refreshLiveRoutine() }"),
            "Today must re-read the live run on foreground — nothing else covers a crossing"
                + " that happened while the app was backgrounded"
        )
    }

    func testContinueOpensTheScreenThroughTheRouter() throws {
        let card = try Self.appSource("Home/HomeRoutineCard.swift")
        let router = try Self.appSource("Places/PlaceRoutineNotificationRouter.swift")

        XCTAssertTrue(
            card.contains("PlaceRoutineNotificationRouter.shared.open("),
            "Continue opens the same door the notification tap uses — the App-Intent"
                + " precedent (PlaceActionNotificationRouter.open), so there is one door,"
                + " one pending/replay rule, and no new parameter threaded through HomeView"
        )
        XCTAssertTrue(
            router.contains("func open("),
            "the router must expose the non-notification way in"
        )
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw NSError(domain: "HomeRoutineCardCallSiteTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not read \(url.path) — this test reads the"
                    + " tree it was compiled from (#filePath)."
            ])
        }
        return text
    }
}
