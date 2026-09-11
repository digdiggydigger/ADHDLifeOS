//
//  FocusCompletionCelebrationCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-4's reachability guards, in the `FocusCompletionCallSiteTests` mould and split into
//  their own file for the reason block 3 recorded: one more test tipped that class over SwiftLint's
//  body ceiling. Same premise — a celebration that is written, documented and unit-tested while no
//  card plays it passes every assertion in `FocusCompletionCelebrationTests`.
//
//  Three of these read WHERE something sits rather than whether it exists, because the placement
//  is the correctness property: a haptic listener on a view that is inserted with the trigger
//  already changed never fires for the first card, and a Reduce Motion check made after the
//  celebration view is built shows one frame of the pre-animation state.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionCelebrationCallSiteTests: XCTestCase {

    // MARK: - The haptic

    /// **Keyed on `confirmableCompletionCount` and nothing else.** `completedSprintCount` is bumped
    /// on manual stops too, which raise no card; `unconfirmedCompletions.count` changes on
    /// confirm-removal, so it would buzz on dismissal. The design record names both traps.
    func testTheOverlayFiresTheSuccessHapticOnTheConfirmableCount() throws {
        let source = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            source.contains(".haptic(.success, trigger: focusService.confirmableCompletionCount)"),
            "The overlay plays no success haptic on a natural completion. E's specification is a"
                + " celebration; a silent card is not one."
        )
        XCTAssertFalse(
            source.contains("trigger: focusService.completedSprintCount"),
            "The haptic is keyed on `completedSprintCount`, which a manual Stop bumps too — so"
                + " stopping a sprint early would celebrate."
        )
        XCTAssertFalse(
            source.contains("trigger: focusService.unconfirmedCompletions.count"),
            "The haptic is keyed on the stack's depth, which falls on Confirm — so dismissing a"
                + " card would celebrate."
        )
    }

    /// The listener must live on a view that is ALWAYS present. `FocusCompletionCardStack` is
    /// inserted by an `if !isEmpty` in the same update that bumps the count, and a
    /// `.sensoryFeedback` / `.onChange` on a view that arrives with the value already changed
    /// observes no change — the very first card, the common case, would be silent.
    func testTheHapticListenerOutlivesTheStack() throws {
        for file in ["Focus/FocusCompletionCardStack.swift", "Focus/FocusCompletionCard.swift"] {
            let source = try Self.appCode(file)
            XCTAssertFalse(
                source.contains(".haptic("),
                "\(file) carries the haptic listener. It is inserted with the trigger already at"
                    + " its new value, so the first completion after an empty stack buzzes nothing."
            )
        }
    }

    // MARK: - The burst reaches the front card, and only the front card

    /// Only the FRONT layer draws a real card — the layers behind are blank edges — so a burst
    /// keyed to any other layer is invisible, and one keyed to the stack rather than the record
    /// fires for cards the user never saw. The cue is the record id the service stamped.
    func testTheCueTravelsFromTheServiceToTheFrontCard() throws {
        let overlay = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            overlay.contains("celebratingID: focusService.celebratingCompletionID"),
            "The overlay never hands the service's celebration cue to the stack, so no card can"
                + " know it is the one that just finished."
        )
        let stack = try Self.appCode("Focus/FocusCompletionCardStack.swift")
        XCTAssertTrue(
            stack.contains("celebrates: layer.record.id == celebratingID"),
            "The stack does not compare the cue against the FRONT layer's record, so either every"
                + " layer celebrates or none does."
        )
        let card = try Self.appCode("Focus/FocusCompletionCard.swift")
        XCTAssertTrue(
            card.contains("FocusCompletionCelebration("),
            "The card never builds the celebration, so it is a tested view nothing shows — this"
                + " repo's most repeated defect."
        )
    }

    /// The trap the design record calls out by name: a Reduce Motion path that shows the
    /// pre-animation state. The environment value must be read by the CARD and resolved before
    /// the celebration's `@State` is initialised, so the first frame is already the final state.
    func testReduceMotionIsResolvedBeforeTheCelebrationIsBuilt() throws {
        let card = try Self.appCode("Focus/FocusCompletionCard.swift")
        XCTAssertTrue(
            card.contains("@Environment(\\.accessibilityReduceMotion)"),
            "The card does not read Reduce Motion, so it cannot hand the celebration a resolved"
                + " answer before the celebration's initial state is chosen."
        )
        XCTAssertTrue(
            card.contains("reduceMotion: reduceMotion"),
            "The card builds the celebration without passing Reduce Motion in. Read inside the"
                + " celebration instead, the value is not available at `init`, and the burst's"
                + " armed state shows for one frame before `onAppear` corrects it."
        )
    }

    // MARK: - The stamp

    /// The cue is written by the push and by nothing else. Written on Confirm it would move to a
    /// card the user is merely revealing; written on restore it would replay on every relaunch
    /// for a sprint that finished hours ago.
    func testOnlyThePushWritesTheCelebrationStamp() throws {
        let source = try Self.appCode("Focus/FocusSessionService+Completions.swift")
        let push = try XCTUnwrap(source.range(of: "func pushUnconfirmedCompletion("))
        let afterPush = source[push.upperBound...]
        let pushEnd = afterPush.range(of: "\n    func ")?.lowerBound ?? afterPush.endIndex
        XCTAssertTrue(
            afterPush[..<pushEnd].contains("latestConfirmableCompletion ="),
            "`pushUnconfirmedCompletion` does not stamp the record it raises, so nothing on screen"
                + " can tell a fresh completion from a card revealed by a Confirm."
        )
        XCTAssertEqual(
            source.components(separatedBy: "latestConfirmableCompletion =").count - 1, 1,
            "The stamp is written from more than one place in the completions extension. Confirm"
                + " must leave it alone (a revealed card must not re-celebrate) and so must the"
                + " restore (a relaunch must not replay a celebration)."
        )
        for file in ["Focus/FocusSessionService.swift", "Focus/FocusSessionService+Persistence.swift"] {
            XCTAssertFalse(
                try Self.appCode(file).contains("latestConfirmableCompletion ="),
                "\(file) writes the celebration stamp. Only the push may."
            )
        }
    }

    /// A relaunch must celebrate nothing, so the stamp lives in memory only — never in
    /// `FocusSprintPersisting`, never under a UserDefaults key.
    func testTheStampIsNeverPersisted() throws {
        for file in [
            "Focus/FocusSprintPersistence.swift", "Focus/FocusSessionService+Persistence.swift"
        ] {
            let source = try Self.appCode(file)
            for form in ["ConfirmableCompletion", "celebrat"] {
                XCTAssertFalse(
                    source.contains(form),
                    "\(file) mentions `\(form)`. The celebration cue must not survive a relaunch:"
                        + " a sprint that finished hours ago would burst again on every launch."
                )
            }
        }
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed — every `XCTAssertFalse` above reads
    /// this, because these files document the anti-patterns they ban.
    private static func appCode(_ relativePath: String) throws -> String {
        try appSource(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CelebrationSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum CelebrationSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`)."
            }
        }
    }
}
