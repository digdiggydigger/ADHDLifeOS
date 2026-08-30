//
//  ADHD_LifeOSUITestsLaunchTests.swift
//  ADHD LifeOSUITests
//
//  Created by E Anthony on 17/07/2026.
//

import XCTest

final class ADHD_LifeOSUITestsLaunchTests: XCTestCase {

    // `static` rather than the template's `class`: the class is final, so the two are the same
    // thing here, and it clears the suite's last standing lint violation.
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        // `launchSignedOut` rather than a bare launch, for the same reason the login tests use
        // it: Firebase Auth's session survives in the simulator keychain across whole runs, so
        // a bare launch here photographs whichever state the PREVIOUS run happened to leave —
        // the tab bar as often as the launch screen. This test cannot fail (it only attaches an
        // image), which is precisely why the picture has to be deterministic to be worth having.
        let app = UITestSession.launchSignedOut()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
