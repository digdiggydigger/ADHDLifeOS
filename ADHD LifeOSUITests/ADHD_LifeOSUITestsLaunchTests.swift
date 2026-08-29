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
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
