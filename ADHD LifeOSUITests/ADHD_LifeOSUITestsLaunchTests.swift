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
        // `resettingOrientation: false` — this is the ONE caller that must not be forced to
        // portrait. `runsForEachTargetApplicationUIConfiguration` above is why: XCTest runs this
        // test once per UI configuration, two of the four being landscape, and pinning the device
        // would collapse the sweep into four identical portrait screenshots. Every other caller
        // takes the default and arrives upright. The cost of that exemption is that this test
        // LEAVES the simulator in landscape, which is exactly what `resetToPortrait` absorbs.
        let app = UITestSession.launchSignedOut(resettingOrientation: false)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
