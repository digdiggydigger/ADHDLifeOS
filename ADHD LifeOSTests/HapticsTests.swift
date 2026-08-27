//
//  HapticsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The app-wide haptic vocabulary (F-V3-Haptics, E's 2026-08-27 direction). Six feels, one gate,
/// one place to reason about them — replacing the three near-identical copies of the same
/// `#available`-split modifier that had accumulated (`saveSuccessHaptic`, `promoteSuccessHaptic`,
/// and `RootView`'s inline generator).
///
/// The seam is `HapticPerforming`: the UIKit generators can't be asserted against, so the gate and
/// the feel-selection are tested through a recording fake and the real generators sit behind the
/// one `UIKitHapticPerformer` that nothing else calls.
final class HapticsTests: XCTestCase {

    private final class RecordingPerformer: HapticPerforming {
        private(set) var performed: [HapticFeel] = []
        func perform(_ feel: HapticFeel) { performed.append(feel) }
    }

    // MARK: - The gate

    /// The Settings toggle is consulted at FIRE time (the `AppFeedback` arrangement), so flipping
    /// it mid-session silences the very next tap with no relaunch and no plumbing through views.
    func testPlay_whenHapticsDisabled_performsNothing() {
        let performer = RecordingPerformer()

        Haptics.play(.success, gate: { false }, performer: performer)

        XCTAssertTrue(performer.performed.isEmpty)
    }

    func testPlay_whenHapticsEnabled_performsTheRequestedFeel() {
        let performer = RecordingPerformer()

        Haptics.play(.success, gate: { true }, performer: performer)

        XCTAssertEqual(performer.performed, [.success])
    }

    /// Every feel must survive the gate — a case added to the enum without a generator behind it
    /// would silently do nothing at one call site and be very hard to notice on device.
    func testPlay_everyFeel_reachesThePerformer() {
        let performer = RecordingPerformer()

        for feel in HapticFeel.allCases {
            Haptics.play(feel, gate: { true }, performer: performer)
        }

        XCTAssertEqual(performer.performed, HapticFeel.allCases)
    }

    /// The gate is only asked once per play, and only when it might matter — a disabled gate must
    /// not still be constructing UIKit generators behind it.
    func testPlay_consultsTheGateExactlyOncePerCall() {
        var gateCalls = 0
        let performer = RecordingPerformer()

        Haptics.play(.light, gate: { gateCalls += 1; return true }, performer: performer)

        XCTAssertEqual(gateCalls, 1)
    }

    // MARK: - The vocabulary

    /// The six feels E signed off on. Pinned as a test because the mapping from interaction class
    /// to feel is the whole design: growing this enum casually is how an app ends up buzzing at
    /// everything, which for an ADHD app is an accessibility regression, not a polish win.
    func testVocabulary_isTheSixAgreedFeels() {
        XCTAssertEqual(
            HapticFeel.allCases,
            [.selection, .light, .solid, .success, .warning, .error]
        )
    }

    // MARK: - The two calls E made by hand

    /// E's 2026-08-27 call: the tab bar ticks with a LIGHT IMPACT, not the iOS-conventional
    /// selection tick. Asserted so a later "tidy-up" toward the platform default is a red test
    /// rather than a silent change to something felt fifty times a day.
    func testTabChange_usesLightImpact() {
        XCTAssertEqual(HapticFeel.tabChange, .light)
    }

    /// E's 2026-08-27 call: closing a task is a SUCCESS — the celebratory triple-tap — everywhere
    /// it can be done (row circle, swipe, detail toggle, Today's due-now row, area detail tick).
    func testTaskClose_usesSuccess() {
        XCTAssertEqual(HapticFeel.taskClose, .success)
    }
}
