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
//  **`F-CTACelebrations-3` re-pointed these at the shared layer.** `ConfirmCelebrationOverlay.swift`
//  is deleted: its drawing moved to `Celebrations/CelebrationFrame.swift` and its mounting to
//  `Celebrations/CelebrationLayer.swift`, and the Confirm listener became a BRIDGE on
//  `RootBottomOverlay` that asks the centre rather than starting a burst itself. Every property
//  these tests pinned survives; only the file each one reads has moved, and the split matters —
//  the layer reads Reduce Motion by design, the frame must not (§7.2's waiver).
//

import XCTest
@testable import ADHD_LifeOS

final class ConfirmCelebrationCallSiteTests: XCTestCase {

    /// Mounting, hit-testing and the frame clock.
    private static let layerFile = "Celebrations/CelebrationLayer.swift"
    /// Drawing at one instant. Reduce Motion arrives here as a PARAMETER, never from the
    /// environment, which is what keeps it on the §7.2 waiver's RM-free list.
    private static let frameFile = "Celebrations/CelebrationFrame.swift"
    /// The always-mounted view the Confirm haptic and the Confirm bridge share.
    private static let bridgeFile = "RootBottomOverlay.swift"

    // MARK: - Where the layer is mounted

    /// Above the bottom furniture, so the confetti falls over the card and the tab bar; before the
    /// covers, so a sheet or full-screen cover still presents above it (R3). One line with no `if`,
    /// because the layer must already be mounted when the first Confirm lands.
    func testRootViewMountsTheLayerAboveTheFurnitureAndBelowTheCovers() throws {
        let root = try Self.appCode("RootView.swift")
        let furniture = try XCTUnwrap(root.range(of: "RootBottomOverlay("))
        let layer = try XCTUnwrap(
            root.range(of: ".overlay { CelebrationLayer(surface: .root) }"),
            "RootView does not mount the root celebration layer unconditionally, so a Confirm plays nothing."
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

    /// The bridge sits beside the Confirm haptic on `RootBottomOverlay`, which is mounted
    /// unconditionally and outlives the card stack — the trap `testTheHapticListenerOutlivesTheStack`
    /// records. It ASKS the centre; it never decides, and it never starts a burst itself.
    func testTheConfirmBridgeListensBesideTheHapticOnTheAlwaysMountedOverlay() throws {
        let overlay = try Self.appCode(Self.bridgeFile)
        let listener = try XCTUnwrap(
            overlay.range(of: ".onChange(of: focusService.latestConfirmation)"),
            "Nothing bridges the Confirm stamp into the celebration centre, so a Confirm plays nothing."
        )
        let haptic = try XCTUnwrap(
            overlay.range(of: ".haptic(.success, trigger: focusService.confirmationCount)"),
            "The Confirm haptic has left the always-mounted overlay."
        )
        XCTAssertTrue(
            overlay[listener.lowerBound...].contains(
                "celebrate.request(.confirm(clearedStack: confirmation.clearedStack), at: nil)"
            ),
            "The bridge does not ask the centre for a Confirm celebration, so nothing is enqueued."
        )
        // Both hang off the same modifier run on the same always-present view: nothing between
        // them re-opens a conditional, so the bridge cannot be mounted later than the haptic.
        let between = overlay[min(listener.lowerBound, haptic.lowerBound)..<max(listener.lowerBound, haptic.lowerBound)]
        XCTAssertFalse(
            between.contains("\n            if ") || between.contains("\n        if "),
            "The Confirm bridge and the Confirm haptic are separated by a conditional, so one of them"
                + " can be absent when the first Confirm lands."
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
    /// burst is live on THIS surface, and bursts must be pruned when they end.
    func testNothingRedrawsOnceTheLastBurstHasEnded() throws {
        let layer = try Self.appCode(Self.layerFile)
        let gate = try XCTUnwrap(
            layer.range(of: "if !bursts.isEmpty {"),
            "The stage is built whether or not anything is live."
        )
        let stage = try XCTUnwrap(layer.range(of: "CelebrationStage("))
        XCTAssertLessThan(gate.lowerBound, stage.lowerBound, "The stage is built outside the live-burst gate.")
        XCTAssertEqual(
            layer.components(separatedBy: "TimelineView(.animation)").count - 1, 1,
            "More than one frame clock drives the celebration."
        )
        XCTAssertTrue(
            layer.contains("center.prune("),
            "Finished bursts are never removed, so the frame clock runs for ever after the first Confirm."
        )
    }

    /// E's extra 1.2 s is a stretch of the whole choreography, so the frame must place every piece
    /// on the stretched clock. Reverting to raw elapsed time would play the old 4.2 s inside a 5.4 s
    /// burst, then show nothing for the last 1.2 s.
    func testTheFrameDrawsOnTheStretchedClock() throws {
        XCTAssertTrue(
            try Self.appCode(Self.frameFile)
                .contains("CelebrationQueue.choreographyTime(of: scene.burst, at: date)"),
            "The confetti is placed on raw elapsed time, not on the stretched choreography clock."
        )
    }

    // MARK: - The stack-clearing Confirm (block 2)

    /// E's decision 2: the fireworks ARE what makes the stack-clearing Confirm bigger; the confetti
    /// is identical on both. So the display is built only for a burst whose stamp cleared the
    /// stack, and the dim is driven by the same live bursts (which know which of them cleared it).
    func testTheFireworksAndTheDimPlayOnlyOnAStackClearingConfirm() throws {
        XCTAssertTrue(
            try Self.appCode(Self.layerFile)
                .contains("fireworks: burst.clearedStack ? ConfirmFireworks(canvas: canvas) : nil"),
            "The fireworks are built for every burst, or for none. They belong to the stack-clearing"
                + " Confirm only."
        )
        XCTAssertTrue(
            try Self.appCode(Self.frameFile)
                .contains("ConfirmCelebrationDim.strongestEnvelope(of: scenes.map(\\.burst), at: date)"),
            "The dim is not driven by the live bursts, so it cannot follow a stack-clearing Confirm."
        )
    }

    /// E (#7): "for light-mode display views, a background dim". Dark appearance does not dim
    /// (R6: the glow shows in both; only the dim is light-only).
    func testTheDimIsLightAppearanceOnly() throws {
        let frame = try Self.appCode(Self.frameFile)
        XCTAssertTrue(
            frame.contains("@Environment(\\.colorScheme) private var colorScheme"),
            "The frame never reads the appearance, so the dim plays in dark too."
        )
        let gate = try XCTUnwrap(
            frame.range(of: "if colorScheme == .light"), "The dim is not gated on the light appearance."
        )
        let dim = try XCTUnwrap(frame.range(of: "Color(ConfirmCelebrationDim.colorName)"), "The frame draws no dim.")
        XCTAssertLessThan(gate.lowerBound, dim.lowerBound, "The dim is drawn outside the light-appearance gate.")
    }

    /// Back to front, the record's order: app → dim → glow → fireworks → confetti. The dim under
    /// the glow keeps the green wash visible over the night sky; the fireworks under the confetti
    /// keep the paper in front of the sparks. And the fireworks are placed at `elapsed`, the
    /// stretched choreography time, never at raw wall-clock time (E's "Same stretch").
    func testTheFrameDrawsDimThenGlowThenFireworksThenConfettiOnTheStretchedClock() throws {
        let frame = try Self.appCode(Self.frameFile)
        let dim = try XCTUnwrap(frame.range(of: "Color(ConfirmCelebrationDim.colorName)"), "The frame draws no dim.")
        let glow = try XCTUnwrap(frame.range(of: "RadialGradient("))
        let fireworks = try XCTUnwrap(
            frame.range(of: "ConfirmFireworksDrawing.draw(fireworks, in: context, at: elapsed"),
            "The frame draws no fireworks, or draws them off the stretched clock."
        )
        let confetti = try XCTUnwrap(frame.range(of: "for piece in scene.confetti"))
        XCTAssertLessThan(dim.lowerBound, glow.lowerBound, "The dim is drawn over the glow.")
        XCTAssertLessThan(glow.lowerBound, fireworks.lowerBound, "The fireworks are drawn under the glow.")
        XCTAssertLessThan(fireworks.lowerBound, confetti.lowerBound, "The fireworks are drawn over the confetti.")
    }

    // MARK: - The haptic (R4)

    /// On the overlay beside the completion haptic, keyed on the Confirm ordinal — never on the
    /// card or the stack (`testTheHapticListenerOutlivesTheStack` already bans those).
    ///
    /// **The centre's ordinal never reaches this line.** `ordinal` did three jobs in the Confirm
    /// build (SwiftUI id, confetti seed, haptic trigger); block 3 gave the first two to the centre's
    /// counter and left the third on the service's, so a pop can never buzz a Confirm.
    func testEveryConfirmFiresTheSuccessHapticFromTheOverlay() throws {
        XCTAssertTrue(
            try Self.appCode(Self.bridgeFile)
                .contains(".haptic(.success, trigger: focusService.confirmationCount)"),
            "Confirm buzzes nothing. E chose the success haptic on every Confirm."
        )
    }

    // MARK: - The §7.2 waiver

    /// **E's waiver of CLAUDE.md §7.2, 2026-09-11: "B AND C".** With Reduce Motion ON, Confirm shows
    /// the glow AND real falling confetti, identical to Reduce Motion OFF. Pinned so a later Reduce
    /// Motion sweep cannot quietly turn E's celebration into a fade.
    ///
    /// **Block 3 changed this pin's SHAPE, not its meaning** (the block's own instruction: it
    /// "becomes 'the Confirm files are RM-free AND the resolver returns `.full` for Confirm'").
    /// `ConfirmCelebrationOverlay.swift` no longer exists, so the sixth file on the list is the
    /// frame it became; and with one shared layer for every celebration, "this file reads no Reduce
    /// Motion" is no longer sufficient on its own — the resolver that picks the rendering has to
    /// answer `.full` for a Confirm before it ever looks at the setting. The behavioural half of
    /// that claim is `CelebrationMotionTests`; the half here is that the branch is REACHED first.
    func testTheConfirmCelebrationIgnoresReduceMotionByDesign() throws {
        for file in [
            "Focus/ConfettiPhysics.swift", "Focus/ConfirmCelebrationRecipe.swift", Self.frameFile,
            "Focus/ConfirmFireworksSchedule.swift", "Focus/ConfirmFireworksPhysics.swift",
            "Focus/ConfirmFireworksDrawing.swift"
        ] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains("reduceMotion") || source.contains("accessibilityReduceMotion"),
                "\(file) reads Reduce Motion. E waived §7.2 for this celebration by name: with Reduce"
                    + " Motion ON it plays in full. Changing that is E's call, not a sweep's."
            )
        }

        let resolver = try Self.appCode("Celebrations/CelebrationMotion.swift")
        let confirm = try XCTUnwrap(
            resolver.range(of: "if case .confirm = kind { return .full }"),
            "The resolver has no Confirm branch, so E's waived celebration is chosen like any other."
        )
        // The parameter's own name comes first, unavoidably; what must not come first is the
        // place the setting is USED to choose a rendering.
        let setting = try XCTUnwrap(
            resolver.range(of: "return reduceMotion ?"),
            "The resolver never uses Reduce Motion to choose a rendering at all."
        )
        XCTAssertLessThan(
            confirm.lowerBound, setting.lowerBound,
            "The resolver reads Reduce Motion BEFORE it answers for Confirm, so a reordering could"
                + " route E's waived celebration down the reduced path."
        )
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
