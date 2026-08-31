//
//  UITestOrientation.swift
//  ADHD LifeOSUITests
//
//  `UITestSession`'s orientation half, split out when F-LandscapeFix pushed that file past the
//  400-line budget. Orientation, like the keychain, outlives the app process AND the whole test
//  run — these two helpers are how every test arrives in a known one.
//

import XCTest

extension UITestSession {

    /// Puts the DEVICE back in portrait before a test launches into it.
    ///
    /// `ADHD_LifeOSUITestsLaunchTests` sets `runsForEachTargetApplicationUIConfiguration`, so
    /// XCTest runs it once per UI configuration — and two of the four are landscape, the LAST of
    /// which leaves the simulator in Landscape Left. Orientation, like the keychain, outlives the
    /// app process: every journey scheduled after it launched into landscape, where the login
    /// form's password field never becomes hittable, and died at `focusAndType`'s hittability
    /// wait. TEN of the seventeen tests in the first whole-target run failed that way on
    /// 2026-08-30 — every single test scheduled after `testLaunch` — with one identical message
    /// that said nothing about orientation.
    ///
    /// It had gone unseen because the whole UI target had never actually been run in one go: the
    /// run recorded as "9/9 journeys" totalled twelve tests, which only adds up as three plus
    /// nine, so it cannot have included `testLaunch` at all.
    ///
    /// This is the same defect as the one `launchSignedOut` exists to fix, one layer down: a test
    /// has to ARRIVE in a known state rather than inherit the previous one's. Auth was the state
    /// that had been noticed; orientation was the one that had not.
    ///
    /// Deliberately NOT applied inside `launchSignedOut` unconditionally — `testLaunch` calls
    /// that, and forcing portrait there would defeat the configuration sweep it exists to run.
    @MainActor
    static func resetToPortrait() {
        guard XCUIDevice.shared.orientation != .portrait else { return }
        XCUIDevice.shared.orientation = .portrait
    }

    /// Rotates the interface to landscape and PROVES it landed, retrying the set (F-LandscapeFix).
    ///
    /// A single orientation set can be swallowed exactly like a single tap — the race class
    /// `tap(_:untilExists:)` exists for, one layer down. Seen live on 2026-08-31: "Device
    /// orientation changed to Landscape Left" with no "Interface orientation changed" ever
    /// following, and the window still 402×874 ten seconds later. The device state is then
    /// already landscape, so a bare re-set would no-op — toggle through portrait to force
    /// redelivery, and judge by the only truth that matters: the window's own frame. (A fresh
    /// simulator boot also clears the sulk; the retry is for when it strikes mid-suite.)
    @MainActor
    @discardableResult
    static func rotateToLandscape(_ app: XCUIApplication) -> Bool {
        let window = app.windows.firstMatch
        var attempts = 3
        while window.frame.width <= window.frame.height, attempts > 0 {
            XCUIDevice.shared.orientation = .portrait
            XCUIDevice.shared.orientation = .landscapeLeft
            let deadline = Date().addingTimeInterval(5)
            while window.frame.width <= window.frame.height, Date() < deadline {
                Thread.sleep(forTimeInterval: 0.25)
            }
            attempts -= 1
        }
        return window.frame.width > window.frame.height
    }
}
