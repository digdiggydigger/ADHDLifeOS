//
//  CelebrationSoundCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-7`'s REACHABILITY half, and it is the half that matters here.
//
//  **The "Celebration sounds" switch has been in Settings since `F-CTACelebrations-3` storing a
//  choice that nothing read.** A correct, unit-tested `CelebrationSoundPlayer` that no call site
//  builds would leave it exactly as dead as it has been — this repo's most-repeated defect, and
//  `F-CTACelebrations-6` shipped an instance of it past ten guards a week ago because no guard
//  thought to look for the call. So these read the SOURCE for the wiring, not the behaviour.
//
//  Source is read with comment lines stripped and flattened to one line, the `*CallSiteTests`
//  house shape, so no guard can go green on a claim that only appears in a comment.
//

import XCTest

final class CelebrationSoundCallSiteTests: XCTestCase {

    /// The app owns the centre, so the app is the one place that can hand it a real player.
    /// Without this line the whole block is inert and every other test in it still passes.
    func testTheAppHandsTheCelebrationCentreARealPlayer() throws {
        let app = try flattened("ADHD_LifeOSApp.swift")

        XCTAssertTrue(
            app.contains("CelebrationSoundPlayer("),
            "nothing builds a player, so the chime cannot sound however correct the player is —"
                + " the switch goes on storing a choice nobody reads"
        )
        XCTAssertTrue(
            app.contains("chime:"),
            "the centre's chime seam is left at its no-op default"
        )
    }

    /// **E's F5 gate, and it is read at FIRE time rather than captured at launch** — the
    /// arrangement `Haptics.play(gate:)` and the Celebrations switch both use, so flipping the
    /// switch takes effect on the very next celebration with no relaunch.
    func testTheSoundSwitchIsWhatDecidesAndItIsReadAtFireTime() throws {
        let app = try flattened("ADHD_LifeOSApp.swift")

        XCTAssertTrue(
            app.contains("AppFeedback.celebrationSoundsEnabled()"),
            "the chime never consults E's switch, so turning Celebration sounds off does nothing"
        )
        let gate = try XCTUnwrap(app.range(of: "AppFeedback.celebrationSoundsEnabled()"))
        let play = try XCTUnwrap(
            app.range(of: ".play()", range: gate.upperBound..<app.endIndex),
            "the switch is read but nothing is gated on it"
        )
        XCTAssertLessThan(gate.lowerBound, play.lowerBound)
    }

    /// **E's F5 is "one soft chime", singular.** Per-kind sounds are a design change E has not
    /// been asked for, and the seam's `CelebrationKind` argument makes inventing them a one-word
    /// edit — so the closure discards it deliberately and this says so.
    func testOneChimeServesEveryFullScreenCelebration() throws {
        let app = try flattened("ADHD_LifeOSApp.swift")

        XCTAssertTrue(
            app.contains("chime: { _ in"),
            "the chime closure branches on the celebration's kind. E's F5 asked for ONE soft"
                + " chime over the full-screen moments; per-kind sounds are a new design question"
        )
    }

    /// The centre already decides this and has since `F-CTACelebrations-5`: `start()` chimes only
    /// for a full-screen burst, and a request made with the Celebrations switch OFF is downgraded
    /// to `.pop`, whose `isFullScreen` is false. **So the Celebrations switch gates the chime for
    /// free** — the opener flagged this as an open question and it is not one. Pinned because the
    /// two lines that make it true sit in different files.
    func testTheCelebrationsSwitchGatesTheChimeThroughTheBurstItself() throws {
        let centre = try flattened("Celebrations/CelebrationCenter.swift")
        let burst = try flattened("Celebrations/CelebrationBurst.swift")

        XCTAssertTrue(
            centre.contains("if burst.isFullScreen { chime(burst.kind) }"),
            "the chime must hang off the burst being full-screen — chimed on every burst it would"
                + " sound for each of the nine in-place pops, which E never asked for"
        )
        XCTAssertTrue(
            burst.contains("if case .pop = kind { return false }"),
            "a pop must not count as full-screen, or the downgrade path chimes"
        )
        XCTAssertTrue(
            centre.contains("kind: outcome == .fullScreen ? kind : .pop"),
            "a celebration refused by E's Celebrations switch must become a POP, which is what"
                + " makes that switch silence the chime without a second gate"
        )
    }

    /// **`setActive(false)` is never called, and that is deliberate.** Deactivating hands the
    /// session back and can unduck or resume other audio at a moment that has nothing to do with
    /// the user's music; the category is simply re-asserted next time.
    func testTheSessionIsNeverDeactivated() throws {
        XCTAssertFalse(
            try flattened("Celebrations/CelebrationSound.swift").contains("setActive(false)"),
            "deactivating the session on a chime's tail interferes with whatever else is playing"
        )
    }

    /// **REVERSED the moment E picked, exactly as it said it would be.** It asserted the
    /// opposite for one commit: while the catalog held no chime, the Settings footer had to keep
    /// admitting the sound did not exist yet. E chose a chime by ear on 2026-09-13, the asset
    /// landed, and so the claim flips rather than disappearing — the house rule from
    /// `F-CTACelebrations-6`, where deleting a reversed test would have left no trace of the
    /// decision that removed it.
    ///
    /// **The footer carried TWO stale claims, and only one of them was this block's.** It also
    /// said the milestone celebrations were "still to come" when all four have had production
    /// call sites since `F-CTACelebrations-4`. A footer is prose no compiler checks, so both are
    /// now pinned here.
    func testTheFooterDescribesASoundThatActuallyExists() throws {
        let settings = try flattened("Settings/SettingsPreferenceSections.swift")
        let asset = Self.appRoot
            .appendingPathComponent("Assets.xcassets/CelebrationChime.dataset/CelebrationChime.caf")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: asset.path),
            "the footer now promises a chime, so the catalog must actually hold one — a dataset"
                + " renamed or dropped leaves the switch dead and the footer lying"
        )
        XCTAssertFalse(
            settings.contains("until the chime arrives"),
            "the footer still tells the user the sound has not arrived; it has"
        )
        XCTAssertFalse(
            settings.contains("still to come"),
            "the footer still calls the milestone celebrations unbuilt — all four have had"
                + " production call sites since F-CTACelebrations-4"
        )
        XCTAssertTrue(
            settings.contains("mixes under"),
            "the footer must say the chime mixes under other audio and respects the silent"
                + " switch — that IS the behaviour E's .ambient choice buys, and the row is the"
                + " only place a user learns it"
        )
    }

    // MARK: - Reading the tree

    private static let appRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("ADHD LifeOS")

    private func flattened(_ relativePath: String) throws -> String {
        let url = Self.appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SoundSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private enum SoundSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`) — if the file has not been written yet, that is the point."
            }
        }
    }
}
