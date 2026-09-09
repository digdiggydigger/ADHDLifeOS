//
//  FocusCompletionCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-2's reachability guards, in the `FocusBarCollapseCallSiteTests` mould and for the
//  same reason: this repo's most repeated defect is a helper that is written, documented and
//  unit-tested while no view uses it. A perfect `confirmCompletion` that nothing on screen calls
//  passes every assertion in `FocusCompletionStackServiceTests` and leaves collapse stuck forever.
//
//  Two of these read ORDER rather than presence — where the push sits relative to the history
//  write, and where the completion card sits relative to the timer bar — because both are
//  correctness properties that a "does the file mention it" check cannot see.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionCallSiteTests: XCTestCase {

    // MARK: - The card reaches the screen

    func testTheOverlayRendersTheCompletionCard() throws {
        let source = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            source.contains("FocusCompletionCard("),
            "`RootBottomOverlay` never renders the completion card, so a finished sprint pushes a"
                + " record nothing shows and collapse is never reset."
        )
        XCTAssertTrue(
            source.contains("unconfirmedCompletions.first"),
            "The overlay is not reading the front of the stack. E's presentation is"
                + " iOS-notification style — newest in front, one at a time, no confirm-all."
        )
        XCTAssertTrue(
            source.contains("confirmCompletion("),
            "The Confirm button is not wired to the service, so tapping it cannot finalise the"
                + " record or clear collapse."
        )
    }

    /// **The card must sit ABOVE the running timer bar.** E chose "Both show — new sprint runs":
    /// a routine firing must never be dropped because the user had not tidied up. Put the
    /// completion card below the bar and it either covers the running card's Pause or gets
    /// covered by it — a card behind another cannot be confirmed.
    func testTheCompletionCardIsAboveTheRunningTimerBar() throws {
        let source = try Self.appCode("RootBottomOverlay.swift")
        let completion = try XCTUnwrap(source.range(of: "FocusCompletionCard("))
        let timerBar = try XCTUnwrap(source.range(of: "FocusTimerBar(service:"))
        XCTAssertTrue(
            completion.lowerBound < timerBar.lowerBound,
            "The completion card is rendered BELOW the timer bar in the VStack. The running"
                + " sprint keeps its established position; the new card stacks above it."
        )
    }

    /// `RootBottomOverlay` animated on `isActive` and the search scope only. A completion card
    /// arriving as the running card leaves is exactly the moment both move, and without a trigger
    /// keyed to the stack the entrance simply pops.
    func testTheOverlayAnimatesOnTheStackDepth() throws {
        let source = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertTrue(
            source.contains("value: focusService.unconfirmedCompletions.count"),
            "Nothing animates on the stack's depth, so the running card's exit and the completion"
                + " card's entrance are not choreographed — the card appears in one frame."
        )
    }

    // MARK: - The push, and where it sits

    /// The runtime proof is `testThePushLandsBeforeTheLogAwait`, which suspends a fake logger
    /// forever. This is the cheap textual companion: it fails the moment someone moves the push
    /// below the write while reading the file, before the suite is ever run.
    func testThePushIsWrittenBeforeTheHistoryWrite() throws {
        let source = try Self.appCode("Focus/FocusSessionService.swift")
        let stop = try XCTUnwrap(source.range(of: "func stop(completedNaturally"))
        let body = source[stop.lowerBound...]
        let push = try XCTUnwrap(
            body.range(of: "pushUnconfirmedCompletion("),
            "`stop()` never pushes a completion, so no natural completion raises a card."
        )
        let log = try XCTUnwrap(body.range(of: "await log("))
        XCTAssertTrue(
            push.lowerBound < log.lowerBound,
            "The push comes AFTER `await log(...)` in `stop()`. A Firestore write that hangs then"
                + " leaves a finished sprint with nothing on screen until it returns or fails."
        )
    }

    /// The push belongs in `stop()`, never in `finishCurrentSprint` — which is also the teardown
    /// for the replacement path in `start` and for the app-was-dead settle in
    /// `restorePersistedSprint`. `testTheOfflineRestorePathPushesNothingToTheNewStack` is the
    /// runtime proof; this one names the mistake.
    func testTheSharedTeardownDoesNotPush() throws {
        let source = try Self.appCode("Focus/FocusSessionService.swift")
        let teardown = try XCTUnwrap(source.range(of: "func finishCurrentSprint("))
        let after = source[teardown.upperBound...]
        let nextFunc = after.range(of: "\n    func ")?.lowerBound ?? after.endIndex
        XCTAssertFalse(
            after[..<nextFunc].contains("pushUnconfirmedCompletion"),
            "`finishCurrentSprint` pushes a completion. It is shared by the manual stop, the"
                + " replacement path and the offline settle, so every one of those would raise a"
                + " card — and the offline sprint would raise TWO."
        )
    }

    // MARK: - Confirm does the whole job

    /// **This guard reads the CONDITION as well as the call, and that is deliberate.** Since
    /// F-FocusCard-3 the reset fires only when no sprint is running (E, 2026-09-09), and a bare
    /// `contains("setCardCollapsed(false)")` survives being wrapped in *any* condition — including
    /// the inverted one. The runtime proof is the pair
    /// `testConfirmResetsCollapse` / `testConfirmLeavesARunningSprintsCardCollapsed`; this is the
    /// cheap textual companion that fails while reading the file.
    func testConfirmResetsCollapseAndReSavesTheRecord() throws {
        let source = try Self.appCode("Focus/FocusSessionService+Completions.swift")
        let reset = try XCTUnwrap(
            source.split(separator: "\n").first { $0.contains("setCardCollapsed(false)") },
            "Confirm does not clear collapse. Block 1 shipped it deliberately sticky and this is"
                + " the ONLY thing that was ever going to reset it."
        )
        XCTAssertTrue(
            reset.contains("isActive"),
            "The collapse reset is unguarded, so confirming an old completion expands the card of"
                + " a sprint that is still running — the block-2 behaviour E replaced on"
                + " 2026-09-09."
        )
        XCTAssertTrue(
            source.contains("await log("),
            "Confirm does not finalise the record, so `confirmed_at` is never written and the"
                + " card's dismissal is the only thing that happened."
        )
        XCTAssertTrue(
            source.contains(".confirmed(at:"),
            "Confirm is re-saving the provisional record unchanged."
        )
    }

    // MARK: - The card's own content

    /// **`human(seconds:)`, never `duration(seconds:)`.** `duration` drops seconds below the
    /// minute (`25m` for 25m 30s) — it is the analytics formatter, where a whole-minute readout
    /// is the point. Here the number is the user's own banked time on a `+30s` sprint, and
    /// rounding it away is exactly the invisible loss the Confirm card exists to prevent.
    func testTheCardShowsTheWholeBankedTime() throws {
        let source = try Self.appCode("Focus/FocusCompletionCard.swift")
        XCTAssertTrue(
            source.contains("FocusTimeFormatting.human("),
            "The card is not using the seconds-preserving formatter."
        )
        XCTAssertFalse(
            source.contains("FocusTimeFormatting.duration("),
            "`duration(seconds:)` drops the seconds, so a sprint extended by +30s reads \"25m\""
                + " when 25m 30s was banked."
        )
    }

    /// The block-1 lesson, at the one place block 2 could repeat it: `layoutPriority` decides who
    /// is OFFERED space first, not who may shrink, so a title at priority 1 compresses its
    /// priority-0 `Text` siblings to nothing. On device that vanished the life-area emoji and
    /// reduced the PAUSED badge to a 1pt sliver, with every test still green.
    func testTheCardsRigidPiecesCannotBeCompressedByTheTitle() throws {
        let source = try Self.appCode("Focus/FocusCompletionCard.swift")
        guard source.contains(".layoutPriority(") else { return }
        XCTAssertTrue(
            source.contains(".fixedSize()"),
            "The card gives its title a `layoutPriority` with no `.fixedSize()` on the rigid"
                + " pieces beside it. That combination shipped in block 1 and E caught it in a"
                + " screenshot AFTER the merge — nothing here asserts text layout."
        )
    }

    func testTheConfirmControlIsTappable() throws {
        let source = try Self.appSource("Focus/FocusCompletionCard.swift")
        XCTAssertTrue(
            source.contains("focusCompletionConfirmButton"),
            "The Confirm button has no accessibility identifier, so no UI journey or VoiceOver"
                + " user can address the one control that clears the card."
        )
    }

    // MARK: - Reading the tree

    /// The same source with every comment line removed.
    ///
    /// **Every `XCTAssertFalse` above must read this, not `appSource`.** These files document the
    /// anti-patterns they ban — `FocusCompletionCard.swift`'s own comment spells out why
    /// `FocusTimeFormatting.duration(seconds:)` is wrong here — so a raw text search finds the
    /// banned string in the prose warning against it and fails a correct implementation.
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
            throw FocusCompletionSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum FocusCompletionSourceError: Error, CustomStringConvertible {
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
