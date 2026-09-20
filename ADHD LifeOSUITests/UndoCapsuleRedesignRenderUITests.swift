//
//  UndoCapsuleRedesignRenderUITests.swift
//  ADHD LifeOSUITests
//
//  **TEMPORARY — E's REDESIGN ROUND, 2026-09-20. Delete with `UndoCapsuleVariant.swift` when the
//  round closes.** Not a test: a camera. It drives the real app to the two surfaces that decide
//  E's three changes and attaches a frame per candidate.
//
//  **ONE TEST METHOD PER VARIANT, and that is a rule with two lost render rounds behind it.** The
//  height round passed its shape through a launch ARGUMENT beginning with `-`, which iOS parses as
//  a UserDefaults key expecting a value and swallows; `xcodebuild`'s own environment does not reach
//  the test runner either. Both failures look exactly like a design that did not change — every
//  frame photographs the default. A method name cannot be swallowed, `launchEnvironment` does reach
//  the app, and each method ALSO asserts the capsule's identifier carries its variant's name, so a
//  frame that photographed the wrong shape fails the run instead of reaching E.
//
//  **The subject is chosen, not taken.** "Capture three things on your mind" is the longest task
//  first-run seeding writes, and the point of this round is what the second line does — a frame of
//  a short title would answer nothing. `firstCloseCircle` in the sibling harness takes whatever is
//  first, which is why this file does not reuse it.
//

import XCTest

final class UndoCapsuleRedesignRenderUITests: XCTestCase {

    /// The seeded task whose title wraps. See the file comment.
    private static let longSubject = "Capture three things on your mind"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - One method per variant

    @MainActor func testRenderVariantCurrentReference() throws { try render(.current) }
    @MainActor func testRenderVariantBaseRadius20() throws { try render(.base) }
    @MainActor func testRenderVariantRadius16() throws { try render(.radius16) }
    @MainActor func testRenderVariantRadiusFull() throws { try render(.radiusFull) }
    @MainActor func testRenderVariantUpToTwoLines() throws { try render(.upToTwo) }
    @MainActor func testRenderVariantRoomyNoUndoPadding() throws { try render(.roomy) }

    // MARK: - The drive

    @MainActor
    private func render(_ variant: UndoCapsuleVariantName) throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "undoredesign\(variant.rawValue.lowercased())")
        let app = try UITestSession.launchSignedIn(
            as: account,
            environment: ["LIFEOS_UNDO_VARIANT": variant.rawValue]
        )
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        UITestSession.openTab("Tasks", in: app)
        XCTAssertTrue(
            app.buttons["appSearchRow"].waitForExistence(timeout: UITestSession.timeout),
            "Tasks never showed the search row, so there is nothing for the capsule to stand in for"
        )
        // **The Momentum filter is the default and it groups by DUENESS**, so the seeded task this
        // round needs — "Capture three things on your mind", the only one long enough to wrap —
        // has `dueDate: nil` and never appears in it. The first run waited 45s for a title that was
        // never going to be on screen. `Open` is a flat list of every open task.
        // **The RETRYING tap, not a bare one.** The chip reported itself "not hittable" on one run
        // — the list had just loaded and the header was still settling — and a bare tap failed the
        // whole variant. `untilExists:` re-taps; the row this round needs is the proof it landed.
        let openFilter = app.buttons["Open"]
        if openFilter.waitForExistence(timeout: 15) {
            UITestSession.tap(openFilter, untilExists: app.staticTexts[Self.longSubject])
        }
        guard let circle = closeCircle(besideTitle: Self.longSubject, in: app) else {
            return XCTFail("No seeded task titled '\(Self.longSubject)' — seeding did not land")
        }
        circle.tap()

        // **The proof that this frame is the shape it claims to be.** Without it a swallowed switch
        // produces five identical frames and a confident report.
        let capsule = app.otherElements["undoCapsule\(variant.identifierSuffix)"]
        XCTAssertTrue(
            capsule.waitForExistence(timeout: UITestSession.timeout),
            "No capsule with identifier 'undoCapsule\(variant.identifierSuffix)' — the variant did"
                + " not reach the app, so this frame would have photographed \(UndoCapsuleVariantName.current.rawValue)"
        )
        attach(app, named: "\(variant.fileOrder)-tasks-\(variant.rawValue)")

        // The dense-content case: on Tasks the capsule replaces the search row over empty space and
        // looks settled; over a full screen it reads differently, and a bigger radius is exactly the
        // kind of change that helps in one place and hurts in the other.
        UITestSession.openTab("Captures", in: app)
        guard capsule.waitForExistence(timeout: 10) else { return }
        attach(app, named: "\(variant.fileOrder)-inbox-\(variant.rawValue)")
    }

    // MARK: - Driving

    /// The tap-circle on the row whose title is `title`, found by vertical proximity.
    ///
    /// The rows carry `taskCheckbox-<uuid>` and the harness cannot know which uuid seeding made, so
    /// the title is located first and the nearest circle to its centre line is the one taken.
    @MainActor
    private func closeCircle(besideTitle title: String, in app: XCUIApplication) -> XCUIElement? {
        // 20s, not the session's 45: once the Open filter is tapped the row is there or it is not,
        // and a miss should cost seconds rather than most of a minute five times over.
        let label = app.staticTexts[title]
        guard label.waitForExistence(timeout: 20) else { return nil }
        let circles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'taskCheckbox-'"))
        guard circles.firstMatch.waitForExistence(timeout: UITestSession.timeout) else { return nil }
        let wanted = label.frame.midY
        let nearest = (0..<circles.count)
            .map { circles.element(boundBy: $0) }
            .filter { $0.exists && $0.isHittable }
            .min { abs($0.frame.midY - wanted) < abs($1.frame.midY - wanted) }
        return nearest
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

/// The variant names, duplicated here because the UI-test target does not link the app target.
/// Kept in lockstep with `UndoCapsuleVariant` by `testTheRenderHarnessKnowsEveryVariant` below.
enum UndoCapsuleVariantName: String, CaseIterable {
    case current, base, radius16, radiusFull, upToTwo, roomy

    var identifierSuffix: String { self == .current ? "" : "-\(rawValue)" }

    /// Numeric prefix so the folder's file order is the order E should read them in.
    var fileOrder: String {
        switch self {
        case .current: return "00"
        case .base: return "01"
        case .radius16: return "02"
        case .radiusFull: return "03"
        case .upToTwo: return "04"
        case .roomy: return "05"
        }
    }
}
