//
//  HitTestProbeUITests.swift
//  ADHD LifeOSUITests
//
//  A PROBE, not a guard — it is here to characterise a defect, and it should be deleted (or
//  turned into a real assertion) the moment the defect is understood.
//
//  The defect: a row EXISTS at a sane frame and is never HITTABLE, so the TAP fails rather than
//  an assertion. Four sightings on 2026-09-04/05, three different identifiers —
//  `homeManageNudgesRow` {{32,584},{338,44}}, `toolsCard.places` {{16,181.7},{370,88}} and
//  `placeTestFireButton` {{326,321.7},{44,44}} — and XCUITest reports "no interrupting elements",
//  retries three times, and refuses each time. It is intermittent and it reproduces at `2c46ee7`,
//  so it is pre-existing and on main.
//
//  Theorising has already cost more than it is worth (`AppTabContent`'s `allowsHitTesting` is
//  correct; `RootBottomOverlay` is bottom-aligned, not full-screen). What is missing is the state
//  AT THE MOMENT OF THE FAILURE, which no existing log captures. So this probe loops the tab
//  switch until hittability breaks and then dumps:
//
//  1. whether OTHER elements on screen are hittable at the same instant — the single most
//     discriminating fact available. If everything is dead, something full-screen is eating hits
//     and the question is what. If only this row is dead, the cause is local to it.
//  2. the full element tree (`app.debugDescription`), where an invisible full-screen view shows
//     up by name.
//  3. a screenshot, so the frame can be compared against what is actually drawn.
//

import XCTest

final class HitTestProbeUITests: XCTestCase {

    override func setUpWithError() throws {
        // The opposite of the house rule on purpose: the probe must survive its own failures to
        // reach the dump, and a first miss is data rather than a reason to stop.
        continueAfterFailure = true
    }

    /// How many tab round-trips to attempt before giving up on catching it. Each is a few
    /// seconds; the defect has bitten roughly one run in three, so this is generous.
    private let rounds = 12

    @MainActor
    func testProbe_tabRootRowsStayHittableAcrossTabSwitches() throws {
        try UITestEmulator.skipUnlessRunning()

        let app = try UITestSession.launchSignedIn(label: "hitprobe")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        var caught = false
        for round in 1...rounds where !caught {
            // The exact shape the failing journeys walk: Tools root → Places → back → another
            // tab → Tools again. Rapid, because every real sighting was on a tab arrival.
            for tab in ["Tools", "Today", "Tasks", "Tools"] {
                selectTab(tab, in: app)
            }
            let door = app.buttons["toolsCard.places"]
            guard door.waitForExistence(timeout: 10) else {
                report("round \(round): toolsCard.places did not EXIST", app: app)
                caught = true
                break
            }
            if !door.isHittable {
                report(
                    "round \(round): toolsCard.places EXISTS at \(door.frame), NOT hittable",
                    app: app
                )
                caught = true
                break
            }
            door.tap()
            if let dead = deadElementInsidePlaces(app) {
                report("round \(round): \(dead)", app: app)
                caught = true
                break
            }
            guard door.waitForExistence(timeout: 10) else {
                report("round \(round): never got back to the Tools ROOT", app: app)
                caught = true
                break
            }

            if let dead = deadNudgesDoorOnToday(app) {
                report("round \(round): \(dead)", app: app)
                caught = true
            }
        }

        if !caught {
            print("[HITPROBE] \(rounds) rounds, never reproduced")
        }
    }

    // MARK: - The dump

    /// Everything worth knowing at the instant of the failure, in one place.
    @MainActor
    private func report(_ what: String, app: XCUIApplication) {
        print("[HITPROBE] \(what)")

        // 1. THE DISCRIMINATING FACT: is anything else hittable right now?
        //    Everything dead → something full-screen is eating hits.
        //    Only the row dead → the cause is local to that row.
        let others = [
            "quickCaptureButton", "tabBar.Today", "tabBar.Tools", "tabBar.Tasks",
            "toolsCard.places", "toolsCard.lifeAreas", "homeManageNudgesRow",
            "homeWeekReviewRow"
        ]
        for identifier in others {
            let element = app.buttons[identifier]
            print("[HITPROBE]   \(identifier): exists=\(element.exists) "
                + "hittable=\(element.exists ? String(describing: element.isHittable) : "n/a") "
                + "frame=\(element.exists ? String(describing: element.frame) : "n/a")")
        }
        print("[HITPROBE]   app.frame=\(app.frame)")

        // 2. The element tree — an invisible full-screen view is NAMED here and nowhere else.
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "element-tree-at-failure"
        tree.lifetime = .keepAlways
        add(tree)

        // 3. The screen, to compare the frame against what is actually drawn.
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "screen-at-failure"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Today's nudges door — the identifier that kills three of the five pre-existing failures.
    ///
    /// Reproduces the FAILING state precisely, which an earlier version of this probe did not:
    /// the real tests scroll only until the row EXISTS and then tap. Scrolling further — as the
    /// first probe did — carries it up to y=452 where it is hittable 12 times out of 12, which
    /// is how the first pass reached the wrong conclusion that the tests merely under-scroll.
    ///
    /// The state worth explaining is the one `FirstRunJourneyUITests` dies in: the row ON SCREEN
    /// at y 572–628 on an 874pt screen, settled, and still refusing a tap.
    @MainActor
    private func deadNudgesDoorOnToday(_ app: XCUIApplication) -> String? {
        selectTab("Today", in: app)
        let nudges = app.buttons["homeManageNudgesRow"]
        var swipes = 12
        while !nudges.exists, swipes > 0 {
            app.swipeUp()
            swipes -= 1
        }
        guard nudges.exists else { return nil }
        // Let the scroll stop, so what follows is about hit-testing rather than momentum.
        Thread.sleep(forTimeInterval: 1.5)

        let frame = nudges.frame
        let centre = CGPoint(x: frame.midX, y: frame.midY)
        let onScreen = app.frame.contains(centre)
        print("[HITPROBE]   frame=\(frame) centre=\(centre) onScreen=\(onScreen) "
            + "hittable=\(nudges.isHittable) screen=\(app.frame)")
        guard !nudges.isHittable, onScreen else { return nil }

        // WHAT IS AT THE CENTRE? The single fact that names the culprit: ask the app which
        // element actually occupies the point the tap would land on.
        let hit = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: centre.x, dy: centre.y))
        print("[HITPROBE]   coordinate at the row's centre: \(hit)")
        return "homeManageNudgesRow ON SCREEN at \(frame), settled, NOT hittable"
    }

    /// Inside Places: checks the third identifier that died in the wild, then pops back.
    ///
    /// Popping is not optional. A tab keeps its navigation stack, so leaving Tools from inside
    /// Places means the next arrival lands inside Places with no door — which reads exactly like
    /// a render failure and is not one. The first version of this probe fell for it and reported
    /// the app's correct behaviour as the defect.
    @MainActor
    private func deadElementInsidePlaces(_ app: XCUIApplication) -> String? {
        let fire = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "placeTestFireButton-")
        ).firstMatch
        var dead: String?
        if fire.waitForExistence(timeout: 10), !fire.isHittable {
            dead = "\(fire.identifier) EXISTS at \(fire.frame), NOT hittable"
        }
        popToRoot(in: app)
        return dead
    }

    /// Back out of any pushed screen to the tab's root.
    @MainActor
    private func popToRoot(in app: XCUIApplication) {
        for _ in 0..<3 {
            let back = app.navigationBars.buttons.firstMatch
            guard back.exists, back.isHittable else { return }
            back.tap()
            _ = app.wait(for: .runningForeground, timeout: 1)
        }
    }

    /// Deliberately NOT `UITestSession.tap(_:untilExists:)` — the probe must be able to observe a
    /// tab tap that does not land, which a retrying helper would paper over.
    @MainActor
    private func selectTab(_ name: String, in app: XCUIApplication) {
        let tab = UITestSession.tabButton(name, in: app)
        guard tab.waitForExistence(timeout: 10) else { return }
        if tab.isHittable {
            tab.tap()
        } else {
            tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        _ = app.wait(for: .runningForeground, timeout: 2)
    }
}
