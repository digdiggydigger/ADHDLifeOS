//
//  ConfirmCelebrationCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-1's reachability and placement guards. The premise is this repo's most
//  repeated defect: a celebration that is written, documented and unit-tested while nothing on
//  screen plays it passes every assertion in the model, recipe and stamp tests.
//
//  Most of these read WHERE something sits, because placement is the correctness property: a layer
//  mounted behind an `if` misses the first Confirm, one without `allowsHitTesting(false)` swallows
//  every tap on the screen for four seconds, and a stage drawn while nothing is live asks for a
//  frame at display rate for as long as the app runs.
//

import XCTest
@testable import ADHD_LifeOS

final class ConfirmCelebrationCallSiteTests: XCTestCase {

    private static let layerFile = "Focus/ConfirmCelebrationOverlay.swift"

    // MARK: - Where the layer is mounted

    /// Above the bottom furniture, so the confetti falls over the card and the tab bar; before the
    /// covers, so a sheet or full-screen cover still presents above it (R3). One line with no `if`,
    /// because the layer's `.onChange` must already be listening when the first Confirm lands.
    func testRootViewMountsTheLayerAboveTheFurnitureAndBelowTheCovers() throws {
        let root = try Self.appCode("RootView.swift")
        let furniture = try XCTUnwrap(root.range(of: "RootBottomOverlay("))
        let layer = try XCTUnwrap(
            root.range(of: ".overlay { ConfirmCelebrationOverlay(focusService: focusService) }"),
            "RootView does not mount the celebration unconditionally, so a Confirm plays nothing."
        )
        let covers = try XCTUnwrap(root.range(of: ".fullScreenCover("))
        XCTAssertLessThan(
            furniture.lowerBound, layer.lowerBound,
            "The celebration is mounted BELOW the bottom furniture, so the card and disc cover it."
        )
        XCTAssertLessThan(
            layer.lowerBound, covers.lowerBound,
            "The celebration is mounted after the covers' modifiers."
        )
    }

    /// The listener sits on the layer's outermost view, after the modifiers that close the
    /// `GeometryReader` — never inside the `if` that only exists while a burst is live.
    func testTheLayerListensForConfirmsOnItsAlwaysPresentView() throws {
        let layer = try Self.appCode(Self.layerFile)
        let hidden = try XCTUnwrap(layer.range(of: ".accessibilityHidden(true)"))
        let listener = try XCTUnwrap(
            layer.range(of: ".onChange(of: focusService.latestConfirmation)"),
            "The layer never listens for the Confirm stamp, so nothing starts a burst."
        )
        XCTAssertLessThan(
            hidden.lowerBound, listener.lowerBound,
            "The Confirm listener is inside the conditional content, so it is not there to hear the"
                + " first Confirm."
        )
    }

    func testTheLayerNeverTakesATapAndIsNeverReadOut() throws {
        let layer = try Self.appCode(Self.layerFile)
        XCTAssertTrue(
            layer.contains(".allowsHitTesting(false)"),
            "The full-screen layer takes touches, so every tap is swallowed while confetti falls."
        )
        XCTAssertTrue(layer.contains(".ignoresSafeArea()"), "The celebration stops short of the screen's edges.")
        XCTAssertTrue(
            layer.contains(".accessibilityHidden(true)"),
            "VoiceOver can land on a decoration with nothing to say."
        )
    }

    /// `TimelineView(.animation)` asks for every frame while it exists. It must exist only while a
    /// burst is live, and bursts must be pruned when they end.
    func testNothingRedrawsOnceTheLastBurstHasEnded() throws {
        let layer = try Self.appCode(Self.layerFile)
        let gate = try XCTUnwrap(
            layer.range(of: "if !bursts.isEmpty {"),
            "The stage is built whether or not anything is live."
        )
        let stage = try XCTUnwrap(layer.range(of: "ConfirmCelebrationStage("))
        XCTAssertLessThan(gate.lowerBound, stage.lowerBound, "The stage is built outside the live-burst gate.")
        XCTAssertEqual(
            layer.components(separatedBy: "TimelineView(.animation)").count - 1, 1,
            "More than one frame clock drives the celebration."
        )
        XCTAssertTrue(
            layer.contains("ConfirmCelebrationQueue.pruned("),
            "Finished bursts are never removed, so the frame clock runs for ever after the first Confirm."
        )
    }

    /// E's extra 1.2 s is a stretch of the whole choreography, so the frame must place every piece
    /// on the stretched clock. Reverting to raw elapsed time would play the old 4.2 s inside a 5.4 s
    /// burst, then show nothing for the last 1.2 s.
    func testTheFrameDrawsOnTheStretchedClock() throws {
        let layer = try Self.appCode(Self.layerFile)
        XCTAssertTrue(
            layer.contains("ConfirmCelebrationQueue.choreographyTime(of: scene.burst, at: date)"),
            "The confetti is placed on raw elapsed time, not on the stretched choreography clock."
        )
    }

    // MARK: - The haptic (R4)

    /// On the overlay beside the completion haptic, keyed on the Confirm ordinal — never on the
    /// card or the stack (`testTheHapticListenerOutlivesTheStack` already bans those).
    func testEveryConfirmFiresTheSuccessHapticFromTheOverlay() throws {
        XCTAssertTrue(
            try Self.appCode("RootBottomOverlay.swift")
                .contains(".haptic(.success, trigger: focusService.confirmationCount)"),
            "Confirm buzzes nothing. E chose the success haptic on every Confirm."
        )
    }

    // MARK: - The §7.2 waiver

    /// **E's waiver of CLAUDE.md §7.2, 2026-09-11: "B AND C".** With Reduce Motion ON — E's own
    /// setting — Confirm shows the glow AND real falling confetti, identical to Reduce Motion OFF.
    /// Pinned so a later Reduce Motion sweep cannot quietly turn E's celebration into a fade.
    func testTheConfirmCelebrationIgnoresReduceMotionByDesign() throws {
        for file in ["Focus/ConfettiPhysics.swift", "Focus/ConfirmCelebrationRecipe.swift", Self.layerFile] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains("reduceMotion") || source.contains("accessibilityReduceMotion"),
                "\(file) reads Reduce Motion. E waived §7.2 for this celebration by name: with Reduce"
                    + " Motion ON it plays in full. Changing that is E's call, not a sweep's."
            )
        }
    }

    // MARK: - The stamp (R2)

    /// Confirm is the only writer: written anywhere else, a finished sprint, a restore or a relaunch
    /// would set off a celebration nobody asked for.
    func testOnlyConfirmWritesTheConfirmationStamp() throws {
        let completions = try Self.appCode("Focus/FocusSessionService+Completions.swift")
        let confirm = try XCTUnwrap(completions.range(of: "func confirmCompletion("))
        let afterConfirm = completions[confirm.upperBound...]
        let confirmEnd = afterConfirm.range(of: "\n    func ")?.lowerBound ?? afterConfirm.endIndex
        XCTAssertTrue(
            afterConfirm[..<confirmEnd].contains("latestConfirmation = "),
            "`confirmCompletion` does not stamp the Confirm, so nothing can celebrate it."
        )
        XCTAssertEqual(
            completions.components(separatedBy: "latestConfirmation = ").count - 1, 1,
            "The Confirm stamp is written from more than one place."
        )
        for file in [
            "Focus/FocusSessionService.swift", "Focus/FocusSessionService+Persistence.swift",
            "Focus/FocusSessionService+Notifications.swift"
        ] {
            XCTAssertFalse(
                try Self.appCode(file).contains("latestConfirmation = "), "\(file) writes the Confirm stamp."
            )
        }
    }

    func testTheConfirmationStampIsNeverPersisted() throws {
        for file in ["Focus/FocusSprintPersistence.swift", "Focus/FocusSessionService+Persistence.swift"] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains("FocusConfirmation") || source.contains("latestConfirmation"),
                "\(file) persists the Confirm stamp, so a relaunch replays a celebration."
            )
        }
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed, because these files document the
    /// anti-patterns they ban.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw ConfirmCelebrationSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    /// Loud rather than skipped — a guard that quietly disables itself is what these tests prevent.
    private enum ConfirmCelebrationSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
