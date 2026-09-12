//
//  CelebrationSwitchCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-2`'s placement guards: the two Settings switches, and the one site the
//  Celebrations switch is wired to today (Confirm). E's decision #3 and F5 —
//  `handoff/SESSION-OPENER-cta-celebrations-design.md`.
//
//  These read the tree because a `Toggle`'s `set` closure and a `.onChange` body cannot be called
//  from a unit test, and what is at stake is not whether the values round-trip (that is
//  `MomentumPreferencesTests`) but whether anything on screen is wired to them. A switch that
//  stores a value nothing reads is this repo's most repeated defect.
//
//  **Every assertion is scoped to its own closure, never to the whole file.** `feedbackSection`
//  already holds four Toggles of the identical shape, so a whole-file
//  `contains("momentumPreferencesStore.write(")` would be green on a tree where the two new rows
//  stored nothing at all (block 1's lesson, `CTAHapticTidyCallSiteTests`).
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationSwitchCallSiteTests: XCTestCase {

    private static let settingsFile = "Settings/SettingsPreferenceSections.swift"
    private static let layerFile = "Focus/ConfirmCelebrationOverlay.swift"

    // MARK: - The two rows (E's #3, F5)

    /// Both rows sit immediately after "Haptics" — the design's placement, and the right one: they
    /// are the same kind of gate over the app's own feedback, while "Notification sounds" below
    /// them governs what iOS plays for a scheduled reminder.
    ///
    /// The identifier is asserted INSIDE each row's own slice, so the ids cannot drift onto each
    /// other's Toggle, and each `set` closure is read on its own, so neither row can be the one
    /// that forgets to persist.
    func testTheFeedbackSectionCarriesBothCelebrationTogglesImmediatelyAfterHaptics() throws {
        let source = try Self.appCode(Self.settingsFile)

        let celebrations = try Self.closure(
            in: Self.settingsFile,
            from: "Toggle(\"Celebrations\", isOn: Binding(",
            to: ".accessibilityIdentifier(\"settingsCelebrationsToggle\")",
            missing: "The Feedback section has no Celebrations row, so E's switch does not exist."
        )
        XCTAssertTrue(
            celebrations.contains("momentumPreferences.celebrationsEnabled = newValue"),
            "The Celebrations row never assigns the preference, so the switch springs back."
        )
        XCTAssertTrue(
            celebrations.contains("momentumPreferencesStore.write(momentumPreferences)"),
            "The Celebrations row never persists, so the choice is lost on the next read."
        )

        let sounds = try Self.closure(
            in: Self.settingsFile,
            from: "Toggle(\"Celebration sounds\", isOn: Binding(",
            to: ".accessibilityIdentifier(\"settingsCelebrationSoundsToggle\")",
            missing: "The Feedback section has no Celebration sounds row."
        )
        XCTAssertTrue(
            sounds.contains("momentumPreferences.celebrationSoundsEnabled = newValue"),
            "The Celebration sounds row never assigns the preference, so the switch springs back."
        )
        XCTAssertTrue(
            sounds.contains("momentumPreferencesStore.write(momentumPreferences)"),
            "The Celebration sounds row never persists, so the choice is lost on the next read."
        )

        let haptics = try XCTUnwrap(source.range(of: "\"settingsHapticsToggle\""))
        let celebrationsID = try XCTUnwrap(source.range(of: "\"settingsCelebrationsToggle\""))
        let soundsID = try XCTUnwrap(source.range(of: "\"settingsCelebrationSoundsToggle\""))
        let notificationSound = try XCTUnwrap(source.range(of: "\"settingsSoundToggle\""))
        XCTAssertLessThan(haptics.lowerBound, celebrationsID.lowerBound, "Celebrations sits before Haptics.")
        XCTAssertLessThan(
            celebrationsID.lowerBound, soundsID.lowerBound,
            "Celebration sounds sits before the switch it depends on."
        )
        XCTAssertLessThan(
            soundsID.lowerBound, notificationSound.lowerBound,
            "The celebration rows sit after Notification sounds rather than straight after Haptics."
        )
    }

    /// One sentence each, and the sound row's sentence has to say it does nothing yet: the player
    /// arrives in `F-CTACelebrations-7`, and a row that claims to add a chime before any chime
    /// exists is the lie this block is shaped to avoid.
    func testTheFeedbackFooterExplainsBothSwitchesAndSaysTheSoundIsNotLiveYet() throws {
        let footer = try Self.feedbackFooter()
        XCTAssertTrue(
            footer.contains("Celebrations"),
            "The Feedback footer never mentions Celebrations, so the row arrives unexplained."
        )
        XCTAssertTrue(
            footer.contains("full-screen"),
            "The footer does not say WHAT the Celebrations switch covers — the full-screen moments,"
                + " not the haptics or the in-place flourishes (E's #3)."
        )
        XCTAssertTrue(
            footer.contains("chime"),
            "The footer never mentions the chime the sound switch adds."
        )
        XCTAssertTrue(
            footer.contains("until"),
            "The footer does not say the sound switch does nothing UNTIL the chime ships, so the row"
                + " promises something that is not built yet."
        )
    }

    // MARK: - Confirm reads the switch at FIRE time

    /// The `hapticsEnabled()` arrangement (`Haptics.play(gate:)`): the switch is consulted in the
    /// listener, as the Confirm lands, so flipping it takes effect on the very next Confirm with no
    /// relaunch and nothing plumbed through `RootView`.
    ///
    /// The gate must sit BEFORE the burst is appended. Read after it, the celebration would already
    /// be on the list and the frame clock already running.
    func testTheConfirmLayerGatesOnTheCelebrationsSwitchBeforeStartingABurst() throws {
        let listener = try Self.closure(
            in: Self.layerFile,
            from: ".onChange(of: focusService.latestConfirmation)",
            to: ".task(id: bursts)",
            missing: "The Confirm listener is not where this test expects it."
        )
        let gate = try XCTUnwrap(
            listener.range(of: "guard celebrationsGate() else { return }"),
            "The Confirm listener never consults the Celebrations switch, so the Settings row is a lie."
        )
        let adding = try XCTUnwrap(
            listener.range(of: "ConfirmCelebrationQueue.adding("),
            "The Confirm listener no longer starts a burst."
        )
        XCTAssertLessThan(
            gate.lowerBound, adding.lowerBound,
            "The switch is read after the burst has already been added, so the celebration plays anyway."
        )
        XCTAssertTrue(
            try Self.appCode(Self.layerFile)
                .contains("var celebrationsGate: () -> Bool = { AppFeedback.celebrationsEnabled() }"),
            "The gate does not default to the Settings switch, so the mounted layer reads something else."
        )
    }

    /// E's #3, verbatim: the switch turns off every FULL-SCREEN celebration — "haptics and in-place
    /// feedback stay". The Confirm haptic lives in `RootBottomOverlay`, deliberately outside this
    /// gate, so a later sweep that "makes the switch cover everything" cannot take the buzz with it.
    func testTheCelebrationsSwitchNeverSilencesTheConfirmHaptic() throws {
        let overlay = try Self.appCode("RootBottomOverlay.swift")
        XCTAssertFalse(
            overlay.contains("celebrationsEnabled") || overlay.contains("celebrationsGate"),
            "The Confirm haptic is gated on the Celebrations switch. E chose a switch over the"
                + " full-screen celebrations only: haptics and in-place feedback stay (#3)."
        )
    }

    // MARK: - Reading the tree

    /// The Feedback section's footer alone. Anchored on the section's own header so a footer added
    /// to another section cannot satisfy it, and bounded at the next declaration so a section
    /// appended after this one cannot either.
    private static func feedbackFooter() throws -> String {
        let source = try appCode(settingsFile)
        guard let header = source.range(of: "Text(\"Feedback\")") else {
            throw CelebrationSwitchSourceError.anchorMissing(
                settingsFile, "Text(\"Feedback\")", "The Feedback section's header has been renamed."
            )
        }
        guard let footer = source.range(of: "} footer: {", range: header.upperBound..<source.endIndex) else {
            throw CelebrationSwitchSourceError.anchorMissing(
                settingsFile, "} footer: {", "The Feedback section has no footer at all."
            )
        }
        let tail = source[footer.upperBound...]
        let end = tail.range(of: "\n    var ")?.lowerBound ?? tail.endIndex
        return String(tail[..<end])
    }

    private static func closure(
        in relativePath: String,
        from opening: String,
        to closing: String,
        missing: String
    ) throws -> String {
        let source = try appCode(relativePath)
        guard let start = source.range(of: opening) else {
            throw CelebrationSwitchSourceError.anchorMissing(relativePath, opening, missing)
        }
        guard let end = source.range(of: closing, range: start.upperBound..<source.endIndex) else {
            throw CelebrationSwitchSourceError.anchorMissing(relativePath, closing, missing)
        }
        return String(source[start.upperBound..<end.lowerBound])
    }

    /// The same source with every comment line removed, because these files document the very
    /// identifiers and anti-patterns the assertions look for.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw CelebrationSwitchSourceError.unreadable(url.path)
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    /// Loud rather than skipped — a guard that quietly disables itself is what these tests prevent.
    private enum CelebrationSwitchSourceError: Error, CustomStringConvertible {
        case unreadable(String)
        case anchorMissing(String, String, String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            case .anchorMissing(let file, let anchor, let why):
                return "\(file) does not contain `\(anchor)`. \(why)"
            }
        }
    }
}
