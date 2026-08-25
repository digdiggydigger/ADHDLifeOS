//
//  CaptureFanTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The capture fan's pure geometry and voice (F-V3-Capture): five discs on v3's bowed arc with
/// its reverse-frequency stagger (Task nearest and first, Note farthest and last), each kind
/// owning its identity hue and its composer copy.
final class CaptureFanTests: XCTestCase {
    func testSlots_coverAllFiveKindsInV3Order() {
        XCTAssertEqual(CaptureFan.slots.map(\.kind), [.note, .voice, .photo, .link, .task])
    }

    func testSlots_bowOutAndBack_andStaggerReversesDistance() {
        let slots = CaptureFan.slots
        // The arc bows: the middle disc sits farthest from the trailing edge.
        XCTAssertEqual(slots.map(\.fromTrailing), [57, 70, 75, 70, 57])
        // Bottom-up spacing is even 78pt centres from 207 (task) to 519 (note).
        XCTAssertEqual(slots.map(\.fromBottom), [519, 441, 363, 285, 207])
        // The nearest disc appears first: task 0ms … note 160ms.
        XCTAssertEqual(slots.map(\.appearanceDelay), [0.16, 0.12, 0.08, 0.04, 0])
    }

    func testDiscTokens_carryTheIdentityHues() {
        XCTAssertEqual(CaptureFan.slot(for: .note).fillAssetName, "AccentColor")
        XCTAssertEqual(CaptureFan.slot(for: .voice).fillAssetName, "AreaGrowthVivid")
        XCTAssertEqual(CaptureFan.slot(for: .photo).fillAssetName, "AreaHealthVivid")
        XCTAssertEqual(CaptureFan.slot(for: .link).fillAssetName, "AreaAdminVivid")
        XCTAssertEqual(CaptureFan.slot(for: .task).fillAssetName, "StateGoVivid")
        XCTAssertEqual(CaptureFan.slot(for: .photo).onAssetName, "OnAreaHealth")
        XCTAssertEqual(CaptureFan.slot(for: .task).onAssetName, "OnStateGo")
    }

    func testComposerCopy_perKindVoice() {
        XCTAssertEqual(CaptureComposerCopy.title(for: .note), "Note")
        XCTAssertEqual(CaptureComposerCopy.title(for: .voice), "Voice note")
        XCTAssertEqual(CaptureComposerCopy.ctaLabel(for: .note), "Save to inbox")
        XCTAssertEqual(CaptureComposerCopy.ctaLabel(for: .task), "Add to Today")
        XCTAssertEqual(
            CaptureComposerCopy.footer(for: .task),
            "Skips the inbox — this one goes straight to your list."
        )
        XCTAssertEqual(
            CaptureComposerCopy.footer(for: .voice),
            "Audio and transcript both go to your inbox."
        )
        XCTAssertEqual(
            CaptureComposerCopy.footer(for: .note),
            "Saves to your inbox — nothing gets scheduled yet."
        )
        XCTAssertEqual(CaptureComposerCopy.altLabel(for: .task), "Send to inbox instead")
        XCTAssertEqual(CaptureComposerCopy.altLabel(for: .note), "Make it a task instead")
    }

    func testEveryFanTokenExistsInTheCatalog() {
        let bundle = Bundle(for: ADHD_LifeOS.FirebaseManager.self)
        for slot in CaptureFan.slots {
            for name in [slot.fillAssetName, slot.onAssetName] {
                XCTAssertNotNil(
                    UIColor(named: name, in: bundle, compatibleWith: nil),
                    "Colorset '\(name)' is missing from the asset catalog"
                )
            }
        }
    }
}
